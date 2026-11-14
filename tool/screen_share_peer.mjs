// Headless Chrome proof that a second RTCPeerConnection receives
// screenshare video bytes.
//
// Chrome is started with the flags from issue #928:
//   --use-fake-ui-for-media-stream
//   --auto-select-desktop-capture-source=Entire screen
//
// The page calls getDisplayMedia (the same browser API Stream's
// setScreenShareEnabled uses on web) and connects two peers in that page.
// The receiver's getStats inbound-rtp video bytesReceived must rise.
//
// https://getstream.io/video/docs/flutter/guides/screensharing/
//
// Usage: node tool/screen_share_peer.mjs
// Exit 0 prints {"ok":true,"bytesReceived":N}. Exit 1 prints the reason.
//
// Chrome 157 binds DevTools to 127.0.0.1. When that port is already taken it
// logs "bind() failed: Address already in use" and listens on [::1] instead.
// Polling only http://127.0.0.1:9333/json then fails with
// "TypeError: fetch failed" and the byte check never runs. Port 0 makes
// Chrome pick a free port. This script connects to the host in
// "DevTools listening on ws://...", and tries [::1] as well as 127.0.0.1.

import { spawn } from 'node:child_process';
import { mkdtemp, readFile, rm } from 'node:fs/promises';
import { createServer } from 'node:http';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const chrome =
  process.env.CHROME_PATH ||
  '/usr/bin/google-chrome';

const pageScript = `
async function run() {
  const stream = await navigator.mediaDevices.getDisplayMedia({
    video: true,
    audio: false,
  });
  const track = stream.getVideoTracks()[0];
  if (!track) return { ok: false, reason: 'no video track' };
  const sender = new RTCPeerConnection();
  const receiver = new RTCPeerConnection();
  sender.onicecandidate = (event) => {
    if (event.candidate) receiver.addIceCandidate(event.candidate);
  };
  receiver.onicecandidate = (event) => {
    if (event.candidate) sender.addIceCandidate(event.candidate);
  };
  sender.addTrack(track, stream);
  const offer = await sender.createOffer();
  await sender.setLocalDescription(offer);
  await receiver.setRemoteDescription(offer);
  const answer = await receiver.createAnswer();
  await receiver.setLocalDescription(answer);
  await sender.setRemoteDescription(answer);
  const deadline = Date.now() + 8000;
  let bytes = 0;
  while (Date.now() < deadline) {
    const stats = await receiver.getStats();
    stats.forEach((report) => {
      if (report.type === 'inbound-rtp' && report.kind === 'video') {
        bytes = report.bytesReceived || 0;
      }
    });
    if (bytes > 0) break;
    await new Promise((resolve) => setTimeout(resolve, 200));
  }
  sender.close();
  receiver.close();
  track.stop();
  return { ok: bytes > 0, bytesReceived: bytes, trackLabel: track.label };
}
run()
`;

async function main() {
  const profile = await mkdtemp(join(tmpdir(), 'screenshare-'));
  const observed = { devtoolsWs: '', stderr: '', exited: null, spawnError: null };
  const child = spawn(
    chrome,
    [
      '--headless=new',
      // 0 asks Chrome for an unused port. A fixed port races anything else
      // on the machine and falls back to an IPv6-only listener.
      '--remote-debugging-port=0',
      `--user-data-dir=${profile}`,
      '--use-fake-ui-for-media-stream',
      '--auto-select-desktop-capture-source=Entire screen',
      '--use-fake-device-for-media-stream',
      '--autoplay-policy=no-user-gesture-required',
      '--no-sandbox',
      '--disable-dev-shm-usage',
      '--no-first-run',
      'about:blank',
    ],
    { detached: true, stdio: ['ignore', 'ignore', 'pipe'] },
  );
  child.stderr.setEncoding('utf8');
  child.stderr.on('data', (text) => {
    observed.stderr = (observed.stderr + text).slice(-2000);
    const match = `${text}\n${observed.stderr}`.match(/DevTools listening on (ws:\/\/\S+)/);
    if (match) observed.devtoolsWs = match[1];
  });
  child.stderr.on('error', () => {});
  child.once('exit', (code, signal) => {
    observed.exited = signal ? `signal ${signal}` : `code ${code}`;
  });
  child.once('error', (error) => {
    observed.spawnError = error;
  });
  let page;
  try {
    page = await serveBlankPage();
    const target = await waitForPage(profile, observed);
    const result = await evaluate(
      target.webSocketDebuggerUrl,
      `http://127.0.0.1:${page.port}/`,
      pageScript,
    );
    if (result.exceptionDetails) {
      console.error(JSON.stringify({
        ok: false,
        reason: result.exceptionDetails.text,
        detail: result.exceptionDetails.exception?.description,
      }));
      process.exitCode = 1;
      return;
    }
    const value = result.result?.value;
    if (!value || value.ok !== true) {
      console.error(JSON.stringify({ ok: false, detail: value }));
      process.exitCode = 1;
      return;
    }
    console.log(JSON.stringify({ ok: true, bytesReceived: value.bytesReceived }));
  } finally {
    page?.server.close();
    stopChrome(child);
    await new Promise((resolve) => setTimeout(resolve, 200));
    await rm(profile, { recursive: true, force: true }).catch(() => {});
  }
}

function stopChrome(child) {
  if (!child.pid) return;
  try {
    process.kill(-child.pid, 'SIGKILL');
  } catch {
    try {
      child.kill('SIGKILL');
    } catch {
      // The browser has already exited.
    }
  }
}

async function waitForPage(profile, observed) {
  const deadline = Date.now() + 15000;
  let last = 'devtools port not announced yet';
  while (Date.now() < deadline) {
    if (observed.spawnError) {
      throw new Error(`chrome did not start: ${describeError(observed.spawnError)}`);
    }
    if (observed.exited) {
      throw new Error(`chrome exited before a page opened: ${observed.exited}; ${stderrTail(observed)}`);
    }
    for (const url of await devToolsJsonUrls(profile, observed)) {
      try {
        const response = await fetch(url, { signal: AbortSignal.timeout(1000) });
        if (!response.ok) {
          last = `${url} status ${response.status}`;
          continue;
        }
        const pages = await response.json();
        const page = pages.find((item) => item.type === 'page' && item.webSocketDebuggerUrl);
        if (page) return page;
        last = JSON.stringify(pages);
      } catch (error) {
        last = `${url} ${describeError(error)}`;
      }
    }
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  throw new Error(`chrome did not open a page: ${last}; ${stderrTail(observed)}`);
}

async function devToolsJsonUrls(profile, observed) {
  const urls = [];
  if (observed.devtoolsWs) urls.push(jsonListUrl(observed.devtoolsWs));
  try {
    const text = await readFile(join(profile, 'DevToolsActivePort'), 'utf8');
    const port = text.split('\n')[0].trim();
    if (/^\d+$/.test(port)) {
      urls.push(`http://127.0.0.1:${port}/json`, `http://[::1]:${port}/json`);
    }
  } catch {
    // Chrome writes this file after the listening line. Either source is enough.
  }
  return [...new Set(urls)];
}

function jsonListUrl(webSocketUrl) {
  const url = new URL(webSocketUrl);
  url.protocol = 'http:';
  url.pathname = '/json';
  url.search = '';
  url.hash = '';
  return url.toString();
}

function describeError(error) {
  const cause = error?.cause;
  const detail = cause?.code || cause?.message || (cause ? String(cause) : '');
  return detail ? `${error} (${detail})` : String(error);
}

function stderrTail(observed) {
  const text = observed.stderr.replace(/\s+/g, ' ').trim();
  return text.slice(-400);
}

function serveBlankPage() {
  return new Promise((resolve) => {
    const server = createServer((request, response) => {
      response.writeHead(200, { 'content-type': 'text/html' });
      response.end('<!doctype html><title>screenshare</title>');
    });
    server.listen(0, '127.0.0.1', () => resolve({ port: server.address().port, server }));
  });
}

function evaluate(url, pageUrl, expression) {
  return new Promise((resolve, reject) => {
    const socket = new WebSocket(url);
    let id = 0;
    const pending = new Map();
    const timer = setTimeout(() => {
      socket.close();
      reject(new Error('chrome evaluate timed out'));
    }, 12000);
    const finish = (callback, value) => {
      clearTimeout(timer);
      callback(value);
    };
    socket.addEventListener('open', async () => {
      await send('Page.enable');
      await send('Runtime.enable');
      await send('Page.navigate', { url: pageUrl });
      await new Promise((done) => setTimeout(done, 300));
      send('Runtime.evaluate', {
        expression,
        awaitPromise: true,
        returnByValue: true,
      }).then((value) => {
        socket.close();
        finish(resolve, value);
      }, (error) => {
        socket.close();
        finish(reject, error);
      });
    });
    socket.addEventListener('message', (event) => {
      const message = JSON.parse(event.data);
      if (message.id && pending.has(message.id)) {
        const { resolve: done, reject: fail } = pending.get(message.id);
        pending.delete(message.id);
        if (message.error) fail(new Error(JSON.stringify(message.error)));
        else done(message.result);
      }
    });
    socket.addEventListener('error', () => finish(reject, new Error('chrome socket failed')));
    function send(method, params) {
      const next = ++id;
      socket.send(JSON.stringify({ id: next, method, params }));
      return new Promise((resolve, reject) => pending.set(next, { resolve, reject }));
    }
  });
}

main().catch((error) => {
  console.error(JSON.stringify({ ok: false, reason: String(error) }));
  process.exitCode = 1;
});

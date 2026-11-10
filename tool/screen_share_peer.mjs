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

import { spawn } from 'node:child_process';
import { mkdtemp, rm } from 'node:fs/promises';
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
  const port = 9333;
  const child = spawn(
    chrome,
    [
      '--headless=new',
      `--remote-debugging-port=${port}`,
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
    { stdio: 'ignore' },
  );
  let page;
  try {
    page = await serveBlankPage();
    const target = await waitForPage(port);
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
    child.kill('SIGKILL');
    await rm(profile, { recursive: true, force: true });
  }
}

async function waitForPage(port) {
  const deadline = Date.now() + 10000;
  let last = '';
  while (Date.now() < deadline) {
    try {
      const response = await fetch(`http://127.0.0.1:${port}/json`);
      const pages = await response.json();
      const page = pages.find((item) => item.type === 'page' && item.webSocketDebuggerUrl);
      if (page) return page;
      last = JSON.stringify(pages);
    } catch (error) {
      last = String(error);
    }
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  throw new Error(`chrome did not open a page: ${last}`);
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
        resolve(value);
      }, (error) => {
        socket.close();
        reject(error);
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
    socket.addEventListener('error', () => reject(new Error('chrome socket failed')));
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

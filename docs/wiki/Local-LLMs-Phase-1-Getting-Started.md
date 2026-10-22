# 🚀 Local LLMs Phase 1: Getting Started with Ollama on 48GB Apple Silicon

> **Repository**: [`https://github.com/neiljaywarner/refuge`](https://github.com/neiljaywarner/refuge)  
> **Hardware Target**: Apple Silicon Mac (48GB Unified RAM, ~36GB Metal VRAM Headroom)  
> **Tracking Issues**: [Issue #271 (Phase 1)](https://github.com/neiljaywarner/refuge/issues/271) & [Issue #272 (Phase 2)](https://github.com/neiljaywarner/refuge/issues/272)  
> **Related Guides**: [Token Quota Preservation](Local-LLMs-and-Token-Quota-Preservation.md), [Agent Harness 2.0](Agent-Harness-and-Token-Orchestration.md)

---

## 1. Executive Summary & Why Local LLMs Matter

Belong on the Spectrum is developed with intensive autonomous agent workflows (Maestro device driving, BDD widget testing, CodeRabbit reviews). While cloud models (Gemini Pro, Claude Sonnet) provide frontier architectural reasoning, they are bound by **5-hour burst windows and weekly quota caps**.

On this **48GB unified RAM Apple Silicon Mac**:
- **36GB VRAM** is directly addressable by the GPU via unified Metal shaders.
- Local models run with **zero token costs, zero API rate limits, and 100% offline privacy**.
- Running local models during repetitive mechanical tasks (lint fixing, widget refactoring, Gherkin translation) preserves cloud quota for high-ambiguity architecture.

---

## 2. Phase 1 Architecture: Tools & Automation

Phase 1 provides two turnkey tools to set up and verify the local environment:

```
                    ┌────────────────────────────────────────┐
                    │      Phase 1: Local LLM Tooling        │
                    └───────────────────┬────────────────────┘
                                        │
             ┌──────────────────────────┴──────────────────────────┐
             ▼                                                     ▼
┌─────────────────────────┐                               ┌─────────────────────────┐
│   tool/setup_ollama.sh  │                               │  tool/verify_ollama.dart│
│ (Turnkey installation,  │                               │ (Health check, VRAM     │
│  brew check, background │                               │  audit, benchmark CLI,  │
│  daemon, model pulling) │                               │  tok/sec measurement)   │
└─────────────────────────┘                               └─────────────────────────┘
```

1. **`tool/setup_ollama.sh`**:
   - Detects `arm64` architecture and queries `sysctl -n hw.memsize` to compute available RAM.
   - Verifies or installs Ollama (`brew install ollama`).
   - Starts the background service (`brew services start ollama` or `ollama serve`).
   - Pulls the two core coding specialist models: `qwen2.5-coder:14b` and `qwen2.5-coder:32b`.
2. **`tool/verify_ollama.dart`**:
   - Zero-dependency Dart CLI utility using standard `dart:io`.
   - Probes `http://127.0.0.1:11434/api/tags` to list installed models, sizes in GB, and quantization levels.
   - Measures prompt evaluation latency and token generation speed (tokens/sec).
   - Validates memory headroom against the 48GB Apple Silicon pool.

---

## 3. Step-by-Step Installation Runbook

### Step 1: Run the Automated Setup Script
From the repository root:
```bash
./tool/setup_ollama.sh
```

*Or perform manual installation via Homebrew:*
```bash
# 1. Install Ollama binary
brew install ollama

# 2. Start the local inference daemon
brew services start ollama
# Alternatively, launch standalone in a separate terminal:
ollama serve
```

---

### Step 2: Download the Target Specialist Models

| Model | Parameter Size | VRAM Usage | Metal Tok/Sec | Recommended Use Case |
| :--- | :---: | :---: | :---: | :--- |
| **`qwen2.5-coder:14b`** | 14.7 Billion | **~9 GB** | **~50 tok/sec** | Ultra-fast single-file refactoring, widget tests, dart lint fixes |
| **`qwen2.5-coder:32b`** | 32.5 Billion | **~20 GB** | **~30 tok/sec** | Complex multi-file architecture, domain models, BDD scenario generation |

```bash
# Pull the fast 14B utility model (~9 GB download)
ollama pull qwen2.5-coder:14b

# Pull the flagship 32B code model (~20 GB download)
ollama pull qwen2.5-coder:32b
```

---

### Step 3: Run the Health Check & Benchmark
Verify connectivity, memory headroom, and tokens-per-second:

```bash
dart run tool/verify_ollama.dart
```

**Expected Healthy Output Sample**:
```text
=================================================================
🦙 Belong on the Spectrum — Local Ollama Diagnostic (Phase 1)
=================================================================

1. Hardware & Unified Memory Profile:
   • Operating System: macos (Version 15.0)
   • Apple Silicon Unified RAM: 48 GB
   • Headroom Grade: Optimal (48GB+) — Can run qwen2.5-coder:32b (~20GB VRAM) + Flutter emulators simultaneously.

2. Probing Ollama HTTP Service:
   • Status: Active & Responding (HTTP 200) at http://127.0.0.1:11434

3. Inspecting Downloaded Models:
   Found 2 local model(s):
   • qwen2.5-coder:14b — 9.00 GB (Params: 14.7B, Quant: Q4_K_M)
   • qwen2.5-coder:32b — 20.00 GB (Params: 32.5B, Quant: Q4_K_M)

4. Testing Inference on qwen2.5-coder:14b:
   Prompt: "Write a 1-line Dart function that reverses a string."
   Waiting for Metal GPU response... Completed in 320ms!
   • Generation Speed: 52.4 tokens/sec (28 tokens)
   • Output snippet: String reverse(String s) => s.split('').reversed.join('');

=================================================================
✓ Local LLM Health Check Completed Successfully!
=================================================================
```

---

## 4. 48GB Unified Memory Headroom Budget

When running local models on Apple Silicon, unified memory is shared between macOS, IDEs, emulators, and Metal GPU shaders:

```
┌────────────────────────────────────────────────────────────────────────┐
│                      48 GB Unified System Memory                       │
├─────────────────────────┬─────────────────────────┬────────────────────┤
│   macOS & Dev Tools     │   Local LLM Inference   │ Free Buffer / Apps │
│   (Android Studio,      │   (qwen2.5-coder:32b)   │ (Chrome, Terminal, │
│    Pixel 9a Emulator)   │                         │  Slack, etc.)      │
│         ~12 GB          │         ~20 GB          │       ~16 GB       │
└─────────────────────────┴─────────────────────────┴────────────────────┘
```

> [!TIP]
> **Safety Rule**: Even with `qwen2.5-coder:32b` loaded into Metal VRAM (~20GB), the system maintains **~28GB of headroom** for physical device debugging (`56091JEBF14039`), Chromium web testing, and the Flutter Gradle build daemon. Memory pressure remains comfortably in the green zone.

---

## 5. Next Phase Preview: Phase 2 ([Issue #272](https://github.com/neiljaywarner/refuge/issues/272))

Phase 1 gets the engine installed, running, and verified.  
**Phase 2 focuses on "How do we know when to use Ollama vs Cloud models wisely?"**:
1. **Automated Task Complexity Classifier**: Route simple mechanical edits to Ollama 14B and reserve Gemini Pro for multi-file architecture.
2. **Benchmark Profiling Suite**: Precision benchmarking on Dart 3 pattern matching and Riverpod state generation.
3. **Agent Integration**: Hooking local endpoints into the Antigravity multi-model router.

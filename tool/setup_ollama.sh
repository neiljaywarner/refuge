#!/usr/bin/env bash
# ==============================================================================
# 🦙 Belong on the Spectrum — Phase 1 Local LLM Setup (48GB Apple Silicon)
# Repository: https://github.com/neiljaywarner/refuge
# Tracking: Issue #271 (Phase 1: Getting Started) & Issue #272 (Phase 2: Intelligent Routing)
# ==============================================================================

set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BOLD}${BLUE}=================================================================${NC}"
echo -e "${BOLD}${BLUE}🦙 Belong on the Spectrum — Local Offline LLM Setup (Phase 1)${NC}"
echo -e "${BOLD}${BLUE}=================================================================${NC}\n"

# 1. Hardware & System Inspection
echo -e "${BOLD}1. Inspecting Hardware & Memory...${NC}"
ARCH=$(uname -m)
if [[ "$ARCH" != "arm64" ]]; then
    echo -e "${YELLOW}⚠️ Architecture is $ARCH (Expected arm64 Apple Silicon). Metal GPU acceleration may not be available.${NC}"
else
    echo -e "${GREEN}✓ Apple Silicon ($ARCH) detected. Metal GPU shader acceleration supported.${NC}"
fi

if [[ "$(uname)" == "Darwin" ]]; then
    RAM_BYTES=$(sysctl -n hw.memsize 2>/dev/null || echo 0)
    RAM_GB=$((RAM_BYTES / 1024 / 1024 / 1024))
    echo -e "${GREEN}✓ Unified RAM: ${RAM_GB} GB detected.${NC}"
    if (( RAM_GB >= 48 )); then
        echo -e "${GREEN}✓ 48GB+ Unified RAM: Comfortably supports both qwen2.5-coder:14b (~9GB) and qwen2.5-coder:32b (~20GB).${NC}"
    elif (( RAM_GB >= 24 )); then
        echo -e "${YELLOW}ℹ️ ${RAM_GB}GB Unified RAM: Recommended to start with qwen2.5-coder:14b (~9GB).${NC}"
    else
        echo -e "${YELLOW}ℹ️ ${RAM_GB}GB Unified RAM: Recommended to run qwen2.5-coder:7b (~5GB).${NC}"
    fi
fi

# 2. Check Homebrew & Ollama installation
echo -e "\n${BOLD}2. Checking Ollama Binary...${NC}"
if command -v ollama >/dev/null 2>&1; then
    OLLAMA_VERSION=$(ollama --version 2>/dev/null || echo "installed")
    echo -e "${GREEN}✓ Ollama is already installed: ${OLLAMA_VERSION}${NC}"
else
    echo -e "${YELLOW}ℹ️ Ollama is not installed.${NC}"
    if command -v brew >/dev/null 2>&1; then
        echo -e "${BLUE}Installing Ollama via Homebrew (brew install ollama)...${NC}"
        brew install ollama || {
            echo -e "${RED}Brew install encountered an issue. You can install Ollama manually by downloading it from https://ollama.com/download${NC}"
        }
    else
        echo -e "${RED}Homebrew not found. Please install Ollama directly from: https://ollama.com/download${NC}"
    fi
fi

# 3. Ensure Ollama Service is running
echo -e "\n${BOLD}3. Checking Ollama Service Status (http://127.0.0.1:11434)...${NC}"
if curl -s http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Ollama service is active and responding on port 11434.${NC}"
else
    echo -e "${YELLOW}Ollama service is not responding. Starting background service...${NC}"
    if command -v brew >/dev/null 2>&1 && brew services list 2>/dev/null | grep -q ollama; then
        brew services start ollama || true
    else
        echo -e "${BLUE}Starting 'ollama serve' in background...${NC}"
        nohup ollama serve > /tmp/ollama.log 2>&1 &
        sleep 2
    fi

    if curl -s http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Ollama service successfully started.${NC}"
    else
        echo -e "${YELLOW}Service startup in progress. If it does not start immediately, run 'ollama serve' in a separate terminal window.${NC}"
    fi
fi

# 4. Pull Starter Coding Models
echo -e "\n${BOLD}4. Checking Installed Models...${NC}"
if command -v ollama >/dev/null 2>&1; then
    CURRENT_MODELS=$(ollama list 2>/dev/null || true)
    echo "$CURRENT_MODELS"

    # Check for 14B model
    if echo "$CURRENT_MODELS" | grep -q "qwen2.5-coder:14b"; then
        echo -e "${GREEN}✓ qwen2.5-coder:14b is already downloaded.${NC}"
    else
        echo -e "${YELLOW}ℹ️ qwen2.5-coder:14b not found.${NC}"
        echo -e "   To pull: ${BOLD}ollama pull qwen2.5-coder:14b${NC} (~9 GB)"
    fi

    # Check for 32B model
    if echo "$CURRENT_MODELS" | grep -q "qwen2.5-coder:32b"; then
        echo -e "${GREEN}✓ qwen2.5-coder:32b is already downloaded.${NC}"
    else
        echo -e "${YELLOW}ℹ️ qwen2.5-coder:32b not found.${NC}"
        echo -e "   To pull: ${BOLD}ollama pull qwen2.5-coder:32b${NC} (~20 GB)"
    fi
fi

# 5. Run Diagnostic Health Check
echo -e "\n${BOLD}5. Running Dart LLM Health Check Utility...${NC}"
if command -v dart >/dev/null 2>&1; then
    dart run tool/verify_ollama.dart || true
else
    echo -e "${YELLOW}Dart SDK not found on PATH. Run 'dart run tool/verify_ollama.dart' from your Flutter/Dart workspace.${NC}"
fi

echo -e "\n${BOLD}${GREEN}=================================================================${NC}"
echo -e "${BOLD}${GREEN}🎉 Phase 1 Setup Script Completed!${NC}"
echo -e "${BOLD}${GREEN}Detailed guide: docs/wiki/Local-LLMs-Phase-1-Getting-Started.md${NC}"
echo -e "${BOLD}${GREEN}=================================================================${NC}\n"

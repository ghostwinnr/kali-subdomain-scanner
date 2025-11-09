#!/usr/bin/env bash
set -euo pipefail

echo "[+] Sistem paketleri güncelleniyor..."
sudo apt update && sudo apt install -y git curl jq python3-pip nmap

# Go ve araçlar
if ! command -v go >/dev/null 2>&1; then
  echo "[+] go yükleniyor..."
  sudo apt install -y golang
fi

GOBIN="$HOME/go/bin"
export PATH="$GOBIN:$PATH"
mkdir -p "$GOBIN"

echo "[+] amass kuruluyor..."
if ! command -v amass >/dev/null 2>&1; then
  GO111MODULE=on go install -v github.com/OWASP/Amass/v3/...@latest || true
fi

echo "[+] subfinder kuruluyor..."
if ! command -v subfinder >/dev/null 2>&1; then
  GO111MODULE=on go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest || true
fi

echo "[+] assetfinder kuruluyor..."
if ! command -v assetfinder >/dev/null 2>&1; then
  go install github.com/tomnomnom/assetfinder@latest || true
fi

echo "[+] httpx kuruluyor..."
if ! command -v httpx >/dev/null 2>&1; then
  GO111MODULE=on go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest || true
fi

echo "[+] nuclei kuruluyor..."
if ! command -v nuclei >/dev/null 2>&1; then
  GO111MODULE=on go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest || true
fi

echo "[+] jq, git vs. hazır. Python pip paketleri yükleniyor..."
pip3 install -r requirements.txt || true

echo "[+] Kurulum tamamlandı. PATH ayarı: export PATH=\"$GOBIN:$PATH\""

echo "NOT: nuclei templates'i güncellemek için: nuclei -update-templates"

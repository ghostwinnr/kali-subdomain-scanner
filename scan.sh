#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

if [ "${1-}" == "" ]; then
  echo "Usage: sudo bash scan.sh <domain> [--fast]"
  exit 1
fi

TARGET="$1"
OUTDIR="results/${TARGET}"
FAST=false
if [[ "${2-}" == "--fast" ]]; then
  FAST=true
fi

mkdir -p "$OUTDIR"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG="$OUTDIR/scan_${TIMESTAMP}.log"

echo "[+] Başlatılıyor: $TARGET" | tee -a "$LOG"

# 1) Subdomain keşfi
SUBS_RAW="$OUTDIR/subdomains_raw.txt"
> "$SUBS_RAW"

if command -v amass >/dev/null 2>&1; then
  echo "[+] amass passive..." | tee -a "$LOG"
  amass enum -passive -d "$TARGET" -o "$OUTDIR/amass.txt" 2>>"$LOG" || true
fi

if command -v subfinder >/dev/null 2>&1; then
  echo "[+] subfinder..." | tee -a "$LOG"
  subfinder -silent -d "$TARGET" -o "$OUTDIR/subfinder.txt" 2>>"$LOG" || true
fi

if command -v assetfinder >/dev/null 2>&1; then
  echo "[+] assetfinder..." | tee -a "$LOG"
  assetfinder --subs-only "$TARGET" > "$OUTDIR/assetfinder.txt" 2>>"$LOG" || true
fi

# Birleştir ve filtrele
if [[ -f "$OUTDIR/amass.txt" ]]; then cat "$OUTDIR/amass.txt" >> "$SUBS_RAW"; fi
if [[ -f "$OUTDIR/subfinder.txt" ]]; then cat "$OUTDIR/subfinder.txt" >> "$SUBS_RAW"; fi
if [[ -f "$OUTDIR/assetfinder.txt" ]]; then cat "$OUTDIR/assetfinder.txt" >> "$SUBS_RAW"; fi

SUBS_CLEAN="$OUTDIR/subdomains.txt"
cat "$SUBS_RAW" | sed 's/^\s*//;s/\s*$//' | grep -v '^$' | sort -u > "$SUBS_CLEAN"

echo "[+] Found $(wc -l < "$SUBS_CLEAN") subdomains" | tee -a "$LOG"

# 2) Live check with httpx
LIVE_OUT="$OUTDIR/live.txt"
if command -v httpx >/dev/null 2>&1; then
  echo "[+] httpx checking live hosts..." | tee -a "$LOG"
  if [[ "$FAST" == true ]]; then
    cat "$SUBS_CLEAN" | httpx -silent -status-code -title -o "$LIVE_OUT" 2>>"$LOG" || true
  else
    cat "$SUBS_CLEAN" | httpx -silent -status-code -title -content-length -o "$LIVE_OUT" 2>>"$LOG" || true
  fi
fi

# 3) Nuclei taraması
NUClei_OUT="$OUTDIR/nuclei-results.json"
if command -v nuclei >/dev/null 2>&1; then
  echo "[+] nuclei scanning..." | tee -a "$LOG"
  cat "$LIVE_OUT" | cut -d ' ' -f1 | nuclei -list - -json -o "$NUClei_OUT" 2>>"$LOG" || true
fi

# 4) Nmap quick scan (opsiyonel / hızlı)
NMAP_OUT="$OUTDIR/nmap.xml"
if command -v nmap >/dev/null 2>&1; then
  echo "[+] nmap quick scan..." | tee -a "$LOG"
  awk '{print $1}' "$LIVE_OUT" | sed -E 's/https?:\/\///' | sed 's/:.*$//' | sort -u > "$OUTDIR/live_hosts.txt"
  if [[ -s "$OUTDIR/live_hosts.txt" ]]; then
    nmap -sS -sV -Pn -iL "$OUTDIR/live_hosts.txt" -oX "$NMAP_OUT" 2>>"$LOG" || true
  fi
fi

# 5) Rapor oluştur
if command -v python3 >/dev/null 2>&1; then
  python3 report_generator.py "$OUTDIR" || true
fi

echo "[+] Tamamlandı. Sonuçlar: $OUTDIR" | tee -a "$LOG"

exit 0

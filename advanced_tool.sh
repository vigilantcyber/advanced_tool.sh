#!/bin/bash

# ======================
# Advanced Vulnerability Scanner
# ======================

# Set up colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
LOG_DIR="./logs"
MASTER_LOG="$LOG_DIR/master_log_$(date +%Y%m%d_%H%M%S).log"

mkdir -p "$LOG_DIR"

function log() {
  echo -e "$1" | tee -a "$MASTER_LOG"
}

# Banner
function banner() {
  log "${BLUE}===========================================${NC}"
  log "${GREEN}    Advanced Vulnerability Scanner Tool    ${NC}"
  log "${BLUE}===========================================${NC}"
}

# Tool checker and installer
function check_tool() {
  local tool=$1
  if ! command -v "$tool" &>/dev/null; then
    log "${YELLOW}[!] $tool is not installed. Installing...${NC}"
    sudo apt update && sudo apt install -y "$tool"
  fi
}

# Scan Website with Nikto and ZAP
function scan_website() {
  local url=$1
  log "${GREEN}[*] Starting website scan for $url${NC}"

  # Nikto Scan
  log "${BLUE}[*] Running Nikto...${NC}"
  check_tool "nikto"
  local nikto_log="$LOG_DIR/nikto_$(date +%Y%m%d_%H%M%S).log"
  nikto -h "$url" | tee -a "$nikto_log" &

  # OWASP ZAP (if available)
  if command -v zap-cli &>/dev/null; then
    log "${BLUE}[*] Running OWASP ZAP baseline scan...${NC}"
    local zap_report="$LOG_DIR/zap_report_$(date +%Y%m%d_%H%M%S).html"
    zap-cli quick-scan -r "$zap_report" "$url" | tee -a "$MASTER_LOG" &
    log "${GREEN}[+] ZAP report saved as: $zap_report${NC}"
  else
    log "${RED}[!] OWASP ZAP not installed. Skipping ZAP scan.${NC}"
  fi

  wait
  log "${GREEN}[+] Website scan complete.${NC}"
}

# Scan Device with Nmap
function scan_device() {
  local ip=$1
  log "${GREEN}[*] Starting device scan for $ip${NC}"

  check_tool "nmap"
  local nmap_log="$LOG_DIR/nmap_$(date +%Y%m%d_%H%M%S).log"
  nmap -sV --script=vuln "$ip" | tee -a "$nmap_log" &
  wait
  log "${GREEN}[+] Device scan complete. Results saved to $nmap_log.${NC}"
}

# Scan Application with SQLmap
function scan_app() {
  local url=$1
  log "${GREEN}[*] Starting application scan for $url${NC}"

  check_tool "sqlmap"
  local sqlmap_log="$LOG_DIR/sqlmap_$(date +%Y%m%d_%H%M%S).log"
  sqlmap -u "$url" --batch --risk=3 --level=5 | tee -a "$sqlmap_log" &
  wait
  log "${GREEN}[+] Application scan complete. Results saved to $sqlmap_log.${NC}"
}

# Scan WordPress Sites with WPScan
function scan_wordpress() {
  local url=$1
  log "${GREEN}[*] Starting WordPress scan for $url${NC}"

  check_tool "wpscan"
  local wpscan_log="$LOG_DIR/wpscan_$(date +%Y%m%d_%H%M%S).log"
  wpscan --url "$url" --enumerate vp | tee -a "$wpscan_log" &
  wait
  log "${GREEN}[+] WordPress scan complete. Results saved to $wpscan_log.${NC}"
}

# Scan Fingerprinting with WhatWeb
function scan_fingerprint() {
  local url=$1
  log "${GREEN}[*] Starting fingerprinting scan for $url${NC}"

  check_tool "whatweb"
  local whatweb_log="$LOG_DIR/whatweb_$(date +%Y%m%d_%H%M%S).log"
  whatweb "$url" | tee -a "$whatweb_log" &
  wait
  log "${GREEN}[+] Fingerprinting scan complete. Results saved to $whatweb_log.${NC}"
}

# Interactive Menu
function interactive_menu() {
  while true; do
    log "${YELLOW}"
    log "Select a scanning option:"
    log "1) Scan Website"
    log "2) Scan Device"
    log "3) Scan Application"
    log "4) Scan WordPress Site"
    log "5) Fingerprint Target"
    log "6) Exit"
    log "${NC}"

    read -rp "Enter your choice [1-6]: " choice

    case $choice in
    1)
      read -rp "Enter website URL: " website
      scan_website "$website"
      ;;
    2)
      read -rp "Enter device IP: " device
      scan_device "$device"
      ;;
    3)
      read -rp "Enter application URL: " app
      scan_app "$app"
      ;;
    4)
      read -rp "Enter WordPress URL: " wp
      scan_wordpress "$wp"
      ;;
    5)
      read -rp "Enter target URL: " target
      scan_fingerprint "$target"
      ;;
    6)
      log "${GREEN}[+] Exiting...${NC}"
      exit 0
      ;;
    *)
      log "${RED}[!] Invalid choice. Please try again.${NC}"
      ;;
    esac
  done
}

# Main Function
banner
interactive_menu

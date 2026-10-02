#!/usr/bin/env bash
# morning_start.sh - exam-morning kickoff helper.
#
# What it does (all safe, no scanning):
#   1. Reminds you to be inside tmux and on the exam VPN.
#   2. Runs the tool health check.
#   3. Creates a per-target workspace with oscp-init.
#   4. Prints the exact enumeration commands to run next.
#
# It does NOT scan anything itself - you run the scan commands by hand,
# so you always control which IP gets touched. Only ever use your
# assigned, authorised exam targets.
#
# Usage:
#   ./morning_start.sh                  # prompts for target name + IP
#   ./morning_start.sh secura 192.168.x.y

set -uo pipefail

info() { printf '\n[*] %s\n' "$*"; }
ok()   { printf '[+] %s\n' "$*"; }
warn() { printf '[!] %s\n' "$*"; }

# ---------------------------------------------------------------------------
# 0. tmux + VPN reminders
# ---------------------------------------------------------------------------
if [[ -z "${TMUX:-}" ]]; then
  warn "You are NOT inside tmux. Recommended: run 'tmux' first, then re-run this."
  warn "tmux keeps your session alive if the VPN or terminal drops."
else
  ok "tmux session detected."
fi

info "Checklist before you start:"
echo "    - Exam VPN connected?        (openvpn your-exam.ovpn)"
echo "    - Read the live OffSec guide + control panel (that is the source of truth)"
echo "    - No AI/chatbot help during the exam or report phase"

# ---------------------------------------------------------------------------
# 1. Health check
# ---------------------------------------------------------------------------
info "Running tool health check..."
if command -v oscp-health >/dev/null 2>&1; then
  oscp-health || warn "Health check reported issues - review the output above."
else
  warn "oscp-health alias not found. Run: source ~/.oscp_plus_aliases"
fi

# ---------------------------------------------------------------------------
# 2. Create a workspace
# ---------------------------------------------------------------------------
NAME="${1:-}"
TARGET="${2:-}"

if [[ -z "$NAME" ]]; then
  read -r -p $'\n[?] Short name for this target (e.g. box1): ' NAME
fi
if [[ -z "$TARGET" ]]; then
  read -r -p "[?] Target IP (your assigned exam box): " TARGET
fi

if ! command -v oscp-init >/dev/null 2>&1; then
  warn "oscp-init alias not found. Run: source ~/.oscp_plus_aliases"
  exit 1
fi

info "Creating workspace for '$NAME' -> $TARGET"
oscp-init -n "$NAME" -t "$TARGET"

# ---------------------------------------------------------------------------
# 3. Print the next steps
# ---------------------------------------------------------------------------
cat <<'NEXT'

============================================================
 NEXT STEPS - run these from inside the workspace folder
============================================================
 1. cd into the workspace that was just printed above, e.g.
      cd ./YYYYMMDD_HHMM_<name>

 2. Enumerate (run in order, read the output between each):
      ./scripts/oscp.sh status
      ./scripts/oscp.sh nmap-full
      ./scripts/oscp.sh suggest
      ./scripts/oscp.sh enum-all

 3. Log everything as you find it:
      ./scripts/oscp.sh note  "what you found"
      ./scripts/oscp.sh cred  "user:pass (where)"
      ./scripts/oscp.sh screenshot "proof with ip visible"

 4. When you get a shell, capture proof:
      ./scripts/oscp.sh proof local
      ./scripts/oscp.sh win-privs        # on Windows targets
      ./scripts/oscp.sh loot-linux       # or loot-windows

 Repeat morning_start.sh for each new target to get a fresh workspace.
============================================================
NEXT

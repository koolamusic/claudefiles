#!/usr/bin/env bash
# .warden/lib/browser.sh - agent-browser session helpers
#
# Wraps the login-and-reuse pattern: one login at the top of a frontend
# plan, then subsequent assertions inherit the browser session.
#
# Requires the agent-browser MCP / CLI: `npx agent-browser`.

warden_browser_login() {
  local url="$1" email="$2" password="$3"
  local timeout="${4:-8000}"
  npx agent-browser open "$url" >/dev/null
  npx agent-browser wait "input" >/dev/null
  npx agent-browser fill "input[type='email'], input[name='email']" "$email" >/dev/null
  npx agent-browser fill "input[type='password'], input[name='password']" "$password" >/dev/null
  npx agent-browser click "button[type='submit']" >/dev/null
  npx agent-browser wait --timeout "$timeout" "body" >/dev/null
}

warden_browser_open() {
  local url="$1" wait_selector="${2:-body}" timeout="${3:-8000}"
  npx agent-browser open "$url" >/dev/null
  npx agent-browser wait --timeout "$timeout" "$wait_selector" >/dev/null
}

warden_browser_query_exists() {
  local selector="$1"
  npx agent-browser query "$selector" 2>/dev/null | grep -q .
}

warden_browser_text_exists() {
  local text="$1"
  npx agent-browser query "text=$text" 2>/dev/null | grep -q .
}

warden_browser_eval_true() {
  local expr="$1"
  npx agent-browser eval "$expr" 2>/dev/null | grep -qi "true"
}

warden_browser_wait() {
  local selector="$1" timeout="${2:-8000}"
  npx agent-browser wait --timeout "$timeout" "$selector" >/dev/null
}

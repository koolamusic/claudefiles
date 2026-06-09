# 03 - Home page (agent-browser)

> Reference plan for the **agent-browser** runtime. Use for any
> assertion that needs to inspect rendered UI: page loads, DOM presence,
> form interactions, navigation outcomes.

## What it proves

The wiki home page renders the hero, search bar, and Featured Wiki
section after authenticated login, and the search input accepts focus.

## Prerequisites

- Wiki frontend running on `$WIKI_URL` (default `http://localhost:8080`)
- `agent-browser` available: `npx agent-browser --version`
- A seeded user (`$INITIAL_USERNAME` / `$INITIAL_PASSWORD`)

## Login-and-reuse

Frontend plans share a single browser session: log in once at the top,
then assert against subsequent navigation. The session persists for the
lifetime of the bash block.

## Steps

### Login

```bash
source "$WARDEN_LIB/assert.sh"
source "$WARDEN_LIB/env.sh"
source "$WARDEN_LIB/browser.sh"

warden_load_env

WIKI_URL="${WIKI_URL:-http://localhost:8080}"

warden_browser_login "$WIKI_URL/login" "$INITIAL_USERNAME" "$INITIAL_PASSWORD"
warden_pass login "signed in as $INITIAL_USERNAME"
```

### Hero section

```bash
warden_browser_open "$WIKI_URL/wiki" ".wiki-page--home" 8000

if warden_browser_query_exists ".wiki-home-title"; then
  warden_pass hero-title "hero section renders title"
else
  warden_fail hero-title "hero section title missing"
fi
```

### Search input is focusable

```bash
if warden_browser_query_exists ".wiki-chat-input"; then
  warden_pass search-input "search input rendered"
else
  warden_fail search-input "search input missing"
fi

npx agent-browser click ".wiki-chat-input" >/dev/null
sleep 0.3

if warden_browser_eval_true "document.activeElement?.classList.contains('wiki-chat-input')"; then
  warden_pass search-focus "search input receives focus on click"
else
  warden_fail search-focus "search input did not receive focus"
fi
```

### Featured Wiki section

```bash
if warden_browser_text_exists "Featured Wiki"; then
  warden_pass featured-section "Featured Wiki section present"
else
  warden_fail featured-section "Featured Wiki section missing"
fi
```

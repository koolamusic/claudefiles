---
name: localframe
description: "Record silent product demos on this machine: a paced Playwright browser walkthrough of a web app or docs site, or a scripted asciinema terminal session against an API, rendered to mp4 with numbered stills, a listing paragraph, and the shot list committed beside it. Gated so nothing is published until the demo key is revoked and the artefacts grep clean. Use when the user says 'record a demo of X', 'make a walkthrough video', 'screen-record the app', 'record a terminal demo of the API', 'shoot a take', or asks to retake or publish one."
---

# Localframe

Two kinds of take, one method:

- **Browser**: Playwright drives headless Chromium at 1440×900 through a paced walkthrough and records it.
- **Terminal**: a shell shot list types each command, runs it for real, and asciinema records the session.

The owner narrates over the result or uploads it as is. Takes are silent.

Templates and scripts live beside this file, deployed at `~/.claude/skills/localframe/`. Call scripts by that full path and run them from the take directory:

| File | Use |
|------|-----|
| `templates/walkthrough.mjs` | browser shot list with `pause`, `shot`, `typeSlow`, `scrollSlow`, `waitFile` |
| `templates/demo.sh` | terminal shot list with `type_line`, `run`, `comment` |
| `~/.claude/skills/localframe/scripts/doctor.sh [browser\|terminal]` | pre-flight tool check; installs nothing |
| `~/.claude/skills/localframe/scripts/postflight.sh <take> ['<revoke check>']` | the publish gate; exits 1 on any failure |

Copy a template into the take and edit it for the product. Don't build a shared library around it. Every product needs a different script.

## Take layout

```
<take>/
  walkthrough.mjs | demo.sh     shot list, committed so the take can be reproduced
  walkthrough.mp4 | demo.mp4    the video
  raw/walkthrough.webm          browser original
  demo.cast, demo.gif           terminal originals
  01-sign-in.png 02-overview.png ...   one numbered still per screen; also the shot list
  listing.md                    one paragraph describing the recording
  .take/                        scratch, gitignored, mode 700: secrets.env, relay files
```

`.take/secrets.env` is the one place secrets live during a take. Set it to mode 0600. It holds `BASE_URL`, `DEMO_KEY` and anything else the shot list needs. The browser side writes a key it creates there. The terminal side sources it. Nothing secret goes in a command-line argument or in a committed script. Delete `.take/` once postflight passes.

## Pre-flight

1. Run `~/.claude/skills/localframe/scripts/doctor.sh browser` or `terminal` from the take directory. Install what it reports missing. Its hints are exact. Note that the `agg` crate on crates.io is unrelated; install `agg` from asciinema's repo.
2. Create a **demo key** for this take. Never load a production key or a shared key into a recorded session. Give anything the walkthrough creates an obviously disposable name (`demo-take-2026-10-10`).
3. Dry-run every command. For a terminal take, run `bash demo.sh` until every `curl | jq` line works against a real response. A jq filter written from memory is often wrong, and a mid-take failure costs a full re-shoot.
4. Count the requests the shot list makes and keep them under the API's per-minute quota, so a retake doesn't hit a 429 mid-scene.
5. Create the scratch directory with `mkdir -m 700 .take` (the browser template also creates it), and add `.take/` to the repository's `.gitignore` if the take lives in a repo.

## Browser take

Pacing is the point. Hold each screen 2 to 3 seconds with `pause()`, type with `typeSlow()`, scroll with `scrollSlow()`, and take a `shot(page, 'name')` per screen. The stills number themselves.

```bash
npm i -D playwright && npx playwright install chromium
```

```bash
BASE_URL=https://app.example.com node walkthrough.mjs
```

The script closes the context first, which is when Playwright finishes the webm. It then renames the webm to `raw/walkthrough.webm` and converts it to H.264 `walkthrough.mp4`. If the walkthrough throws, the webm is still written, under Playwright's random filename in `raw/`, and no mp4 is made. Fix it and retake.

If this host's hosts file points the product's hostname at loopback, set `RESOLVE="app.example.com <real-ip>"`. That maps the name inside Chromium only. Don't edit the hosts file.

### Passwordless sign-in

The recorder can't read an inbox, so a person relays the code:

1. The script types the email, submits it, takes a still of the passcode step, and calls `waitFile('code.txt', 'the emailed sign-in code')`. It prints the exact path it's waiting on.
2. Tell the user that path. They read the code from an inbox they control and write it within the code's validity window, for example `! echo 123456 > <take>/.take/code.txt`.
3. The script reads the file, deletes it, types the code and continues.

Use a real inbox. Sign-up forms and mail providers often reject throwaway domains, and the take then stalls with no code ever sent. Relay other sign-up inputs (an organisation name, a first key) the same way, one file each.

## Terminal take

Edit the scenes in `demo.sh`. Use `comment` lines to narrate what comes next, and `run` for each real command, trimmed with `jq` to what the viewer needs. Write secrets as `\$DEMO_KEY` so the typed line shows the variable name and `eval` supplies the value.

```bash
asciinema rec --headless --window-size 100x30 -q -c 'bash demo.sh' demo.cast
```

```bash
agg --cols 100 --rows 30 demo.cast demo.gif
```

```bash
ffmpeg -y -loglevel error -i demo.gif -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -pix_fmt yuv420p -movflags +faststart demo.mp4
```

Keep `--window-size` and `--cols/--rows` the same so the render matches the recording. The scale filter is required: agg's gif dimensions are often odd, and yuv420p rejects odd sizes.

A rate limit can make a good scene. Loop a request printing the remaining-quota header, stop at the first 429, then show `Retry-After` and the error body. First confirm the limit applies only to the demo account, so the burst doesn't affect anyone else.

## Post-flight — the publish gate

In order. Nothing leaves the host until step 3 prints `PASS`.

1. **Revoke the demo key.** A recording that shows a key is only safe because that key no longer works.
2. **Revoke only what the take created.** Delete the rows with the disposable names. Never touch a key or record that existed before the run.
3. **Run the gate**, with a command that prints the HTTP status of a request made with the demo key:

   ```bash
   ~/.claude/skills/localframe/scripts/postflight.sh <take> 'curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $DEMO_KEY" https://api.example.com/v1/me'
   ```

   It sources `.take/secrets.env` and requires 401 or 403. It greps every text artefact (casts, scripts, logs, listing, JSON) for key material, and only the revoked demo key is allowed through. It also checks that `.take/` is gitignored. Add product-specific key formats to `.take/patterns`, one regex per line.
4. **Look at every still and the video.** Grep can't see pixels. Any key on screen other than the revoked demo key fails the take.
5. **Delete `.take/`.**

## Recordings find defects

Walking the live product frame by frame shows exactly what a visitor sees. Past takes caught placeholder link text, a badge claiming something that wasn't true at that moment, and stale sample data. Treat every take as a review pass:

- List what it surfaced in the reply, with the still that shows each one.
- File the fixes and get them shipped before the video is published, then retake.

A demo of a defect that's still live isn't evidence the product works.

## Listing paragraph

`listing.md` holds one short paragraph in product language: what the product does and what the recording shows. Don't name internal components, services or repos. Write it for someone deciding whether to watch.

## What the reply states

- The paths of the mp4, the originals, the stills, `listing.md` and the shot list
- The postflight result, verbatim
- The defects the take surfaced, or that it surfaced none
- What was revoked, and confirmation that nothing pre-existing was touched

---
name: wildcard-proxy
description: "Set up Caddy on a server so any local port is reachable at https://<port>.<domain>/, and two-letter or named labels like https://ui.<domain>/ map to ports too, with certificates issued on demand and gated so only routed hostnames get one. Use when the user says 'set up the wildcard proxy', 'port routing on this server', 'configure caddy so ports get subdomains', 'add a short name for port N', 'what port is ab', or is preparing a new server to expose local services by port."
---

# Wildcard Proxy

One Caddy config, installed once per server, that routes `https://<label>.<domain>/` to `127.0.0.1:<port>`. After install, exposing a service is just binding it to a loopback port. A short name is one line in a names file.

## How a label becomes a port

Checked in this order; first match wins.

| Label | Rule | Example |
|-------|------|---------|
| short name | listed in `wildcard-proxy.names` | `ui` → 4001 |
| port number | matches the allowed port regex | `4012` → 4012 |
| any two letters | `1` + two-digit alphabet position of each letter (a=00 … z=25) | `ab` → 10001, `hz` → 10725, `zz` → 12525 |

The computed range is 10000–12525. Port for letters `xy` = `10000 + 100·pos(x) + pos(y)`. A short name overrides that name's computed port: `ui` would otherwise be 12008.

Anything else (`abc`, `a1`, `3000` outside the ranges, deeper subdomains) gets no certificate and no route.

## Inputs

| Placeholder | Meaning | Default |
|-------------|---------|---------|
| `{{DOMAIN}}` | the wildcard parent, e.g. `host.example.net` | ask the user |
| `{{DOMAIN_RE}}` | same, dots escaped | derived |
| `{{PORT_RE}}` | allowed numeric labels, as regex alternatives | `40[0-9][0-9]\|80[0-9][0-9]` (4000–4099, 8000–8099) |
| `{{ASK_PORT}}` | loopback port for the certificate gate | `5555` |

Use `[0-9][0-9]`, not `[0-9]{2}`, in `PORT_RE`. Caddyfile braces look like placeholders.

## Prerequisites — check before installing

1. **Caddy v2** installed and running as a systemd service: `caddy version`, `systemctl is-active caddy`.
2. **Wildcard DNS**: `*.{{DOMAIN}}` resolves to this server. Check with a label nobody has used: `dig +short zq.{{DOMAIN}}` should print the server's public IP (`curl -4 -s ifconfig.me`; also check `dig +short AAAA` if the server has IPv6).
3. **Ports 80 and 443** reachable from the internet and not held by another server: `sudo ss -tlnp '( sport = :80 or sport = :443 )'`.
4. **No other `on_demand_tls` block** in `/etc/caddy/Caddyfile`. Caddy allows one `ask` endpoint. If one exists, stop and ask the user. Merging two gates is a design decision. The exception is an older inline version of this same config: replace it with the import, and keep the static sites.
5. **`ASK_PORT` free**: `ss -tln | grep ':{{ASK_PORT}} '` prints nothing, or only Caddy itself when migrating an older version of this config.
6. **Nothing private already listening on a routable port.** After install, anything bound to loopback on a routed port is public. Before install, list what is already there:

   ```bash
   ss -tlnp | awk 'NR>1{n=split($4,a,":"); p=a[n]; if ((p>=4000&&p<=4099)||(p>=8000&&p<=8099)||(p>=10000&&p<=12525&&p%100<=25&&int(p/100)%100<=25)) print $4, $6}'
   ```

   Show the user every hit and confirm each one is meant to be public. Default ports in the computed range include memcached's 11211 (`ml`) and Webmin's 10000 (`aa`).

## Install

Templates are in `references/` beside this file.

**1. Back up the live config.**

```bash
sudo cp /etc/caddy/Caddyfile /etc/caddy/Caddyfile.bak-$(date +%F)
```

**2. Render the site file.** From this skill's `references/` directory:

```bash
DOMAIN=host.example.net
DOMAIN_RE=$(printf '%s' "$DOMAIN" | sed 's/\./\\\\./g')
sed -e "s/{{DOMAIN}}/$DOMAIN/g" -e "s/{{DOMAIN_RE}}/$DOMAIN_RE/g" \
    -e 's/{{PORT_RE}}/40[0-9][0-9]|80[0-9][0-9]/g' -e 's/{{ASK_PORT}}/5555/g' \
    wildcard-proxy.caddy > /tmp/wildcard-proxy.caddy
```

Confirm no placeholder survived: `grep -c '{{' /tmp/wildcard-proxy.caddy` prints `0`. Confirm the regex line reads `host\.example\.net`, with single backslashes.

**3. Place both files.** Don't overwrite an existing names file. It holds the user's names.

```bash
sudo install -m 644 /tmp/wildcard-proxy.caddy /etc/caddy/wildcard-proxy.caddy
sudo cp -n wildcard-proxy.names /etc/caddy/wildcard-proxy.names
```

**4. Wire it into the main Caddyfile.** The global options block must be the first thing in the file. Add the `on_demand_tls` lines to it, creating the block if absent, and put the import anywhere after:

```
{
	on_demand_tls {
		ask http://127.0.0.1:5555/ask
	}
}

import wildcard-proxy.caddy
```

On a fresh install, remove the packaged welcome-page `:80 { … }` block. It catches every plain-HTTP request.

**5. Validate, then reload.** Never reload an unvalidated config.

```bash
sudo caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
```

```bash
sudo systemctl reload caddy
```

## Verify

**Gate** — every routed label returns 200, everything else 403:

```bash
for l in 4012 ab zz 3000 abc; do printf '%s %s\n' $l "$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:5555/ask?domain=$l.$DOMAIN")"; done
```

Expected: `4012 200`, `ab 200`, `zz 200`, `3000 403`, `abc 403`.

**Gate is loopback-only** — `ss -tln | grep ':5555 '` shows `127.0.0.1:5555`, not `*:5555`.

**End to end** — serve something on a loopback port and fetch it publicly:

```bash
python3 -m http.server 4012 --bind 127.0.0.1
```

```bash
curl -s -o /dev/null -w '%{http_code}\n' https://4012.$DOMAIN/
```

`200` means it works. The first request to a new hostname triggers certificate issuance and can fail once with `000`. Wait a few seconds and retry once before diagnosing.

## Add a short name

Append `<label> <port>` to `/etc/caddy/wildcard-proxy.names`. Labels use lowercase letters, digits, and hyphens. Then validate and reload as in install step 5. Check that the label returns 200 from the gate.

To answer "what port is `xy`": check the names file first, then compute `10000 + 100·pos(x) + pos(y)`.

## Rules for services behind it

- **Bind to `127.0.0.1`, never `0.0.0.0`.** Caddy must be the only way in. A `0.0.0.0` bind exposes the service on the raw IP without TLS.
- **Scan before picking a port:** `ss -tln`. Don't trust a remembered list.
- **Watch for static sites that share a port.** A Caddyfile entry like `cloud.example.net { reverse_proxy 127.0.0.1:4040 }` means 4040 is taken even though it matches the range. Grep the Caddyfile for `reverse_proxy 127.0.0.1:` before choosing.
- **A static site block for `x.{{DOMAIN}}` wins** over the wildcard. That's intended, but it means the names file doesn't control that label.
- **Everything is public and unauthenticated.** The hostnames are guessable. Say so once before exposing anything sensitive.

## Known limits

- **Certificate rate limits.** About 900 hostnames can request a certificate: 200 numeric, 676 two-letter, plus names. Anyone who knows the scheme can trigger issuance for all of them and exhaust the CA's per-domain weekly limit, which blocks new certificates until it resets. Hostnames that already have certificates keep working. The full fix is a single wildcard certificate via the DNS challenge, which needs a Caddy build with the DNS provider's module. Offer it, don't do it unasked.
- **Caddy `map` quirks the template works around.** Do not "simplify" these away:
  - Map outputs don't expand placeholders. `1{wp_da}{wp_db}` as a map output stays literal, so the computed port is built inside `reverse_proxy`.
  - Map converts bare numeric outputs to integers. Unquoted `01` becomes `1`, so `ab` dials port 101. The alphabet digits stay quoted.
  - The label is extracted by a regex on the full host, not `{labels.N}`. Label indices shift with domain depth.

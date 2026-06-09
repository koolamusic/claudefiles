# 02 - Auth flow (hurl)

> Reference plan for the **hurl** runtime. Use when the assertion surface
> is HTTP and the request/response shape is the main thing being
> verified. Hurl gives declarative assertions on headers, JSON paths,
> response time, and chained requests.

## What it proves

The full auth signup-and-signin flow: sign-up rejected (single-tenant),
sign-in returns a session cookie, profile endpoint accepts the cookie.

## Prerequisites

- Server running on `$SERVER_URL`
- `hurl` installed: https://hurl.dev
- A seeded user (`$INITIAL_USERNAME` / `$INITIAL_PASSWORD`)
- Fixture file at `.warden/fixtures/auth.hurl`

## Fixture

The HTTP contract lives in `.warden/fixtures/auth.hurl`. Skeleton:

```hurl
# Sign-up should be blocked
POST {{base}}/sign-up
{ "email": "intruder@example.com", "password": "whatever" }
HTTP 403

# Sign-in should succeed with seeded user
POST {{base}}/sign-in/email
{ "email": "{{email}}", "password": "{{password}}" }
HTTP 200
[Captures]
session_cookie: header "Set-Cookie"
[Asserts]
jsonpath "$.user.email" == "{{email}}"

# Profile endpoint should accept the cookie
GET {{base}}/users/profile
Cookie: {{session_cookie}}
HTTP 200
[Asserts]
jsonpath "$.email" == "{{email}}"
```

## Steps

```bash
source "$WARDEN_LIB/assert.sh"
source "$WARDEN_LIB/env.sh"
source "$WARDEN_LIB/hurl.sh"

warden_load_env

SERVER_URL="${SERVER_URL:-http://localhost:3000}"

warden_hurl_test "$WARDEN_DIR/fixtures/auth.hurl" auth-flow \
  --variable "base=$SERVER_URL" \
  --variable "email=$INITIAL_USERNAME" \
  --variable "password=$INITIAL_PASSWORD"
```

A single `warden_hurl_test` call covers the entire fixture; pass/fail is
reported as one assertion. Split into multiple `.hurl` files if you want
finer-grained results.

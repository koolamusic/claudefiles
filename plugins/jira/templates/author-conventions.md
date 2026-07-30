# Author conventions

Issues, PRs, and comments outlive the sprint that produced them. Write them for a reader who has no access to `.jira/`, the sprint handoff, or any internal context — how strictly depends on where the artifact lands. This governs `/jira:issue` (issue bodies), `/jira:execute` (PR bodies), and `/jira:comment` (issue/PR comments).

It restates the global "author for an external reader" stance — so the rule holds even when this plugin is installed without that global file — then adds the jira-specific layer.

For comment-specific voice and GitHub permalink rules, see [`comment/GUIDE.md`](comment/GUIDE.md).

## Visibility mode

Check where the artifact lands before writing a word of it:

```bash
gh repo view --json visibility -q .visibility   # PUBLIC | PRIVATE | INTERNAL
```

`PUBLIC` selects **strict** mode. `PRIVATE` and `INTERNAL` select **relaxed** mode, where a reader is assumed to have repo access and some team context. If detection fails or the target repo is unclear, use strict — an over-explained issue costs a few extra words, an under-explained one costs a disclosure you cannot withdraw.

| | Strict (public) | Relaxed (private / internal) |
|---|---|---|
| Internal names and acronyms | Spell out in plain English or omit | Fine unqualified on first use |
| Decision IDs (`D-04`) | Restate as a constraint or acceptance criterion | Fine as a shorthand pointer |
| Sprint slugs, wave labels | Omit | Fine |
| `.jira/` paths | Omit — summarize the content instead | Fine to cite directly |
| Hostnames, vendor box names | Describe the role ("the serving database") | Fine when the reader may need to act on it |
| File and line references | Permalink pinned to a commit SHA | Bare `path:line` acceptable |

Relaxed is a lower bar, not a licence for shorthand nobody outside the sprint can parse. A private repo still gains a new engineer six months from now.

## Quoting another repo

Before transcribing anything from a different repo — a path, a line number, a commit SHA, an issue title, a hostname — check that repo's visibility too:

```bash
gh repo view OWNER/REPO --json visibility -q .visibility
```

A private source quoted into a public artifact is a disclosure no matter which mode the target is in, and cross-repo autolinks (`owner/repo#N`) render as dead references for anyone without access. Public artifacts cite public sources only. When a public artifact needs the substance of a private reference, paraphrase the finding and drop the coordinates.

This holds for every durable artifact in a public repo, documentation and templates included — not just issue and PR bodies. A worked example copied out of a private repo carries that repo's paths and infrastructure names with it.

## Audience & framing

- Strict mode assumes a reader with no access to `.jira/` or the handoff. Relaxed mode assumes repo access, but not sprint memory.
- Focus on the WHAT and why it matters, not the how. State the outcome — the change in capability or contract.
- Keep internal mechanics (file moves, design splits, refactor steps) in `.jira/`, not the artifact.

## Plain English in strict mode

- Translate internal acronyms and names ("the background token cache", "permission checks", "the authentication package boundary") or leave them out.
- A locked decision travels as its substance — the constraint or acceptance criterion it imposes — so the reader learns what is fixed without needing the identifier.

## Structure

- Milestone = Epic; each sprint = a Feature (FEAT-…). Keep it succinct.

## Never acceptable, either mode

The visibility table above governs what relaxes. These do not, because they have nothing to do with who can read the repo:

- Credentials, tokens, connection strings, private keys
- Customer names and personal data
- The AI-attribution trailer
- `Closes` on a feature PR (see Linking — that is auto-close mechanics, not audience)

## Linking

- Feature PRs only link issues: `Refs #NN`, no `Closes`.
- The canary→main promotion PR carries the `Closes` keywords — auto-close fires only on main.

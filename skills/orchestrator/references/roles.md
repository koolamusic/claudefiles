# Slot contracts and personas

Three slots, one contract each. The contract never changes. The persona changes
every time, and only supplies domain vocabulary and a standard for what counts as
a finding.

## Surveyor

Finds out. Explores a codebase, reads docs, searches the web, and comes back with
evidence.

- Cite or omit. A claim without a `path:line` or a URL is noise.
- Tier every source: what was read directly, what was corroborated, what is a
  single unverified mention.
- One focus area per surveyor. Something outside it goes in open questions, not
  into a second investigation.
- No recommendations. "X exists, here is its tradeoff" — the choice is made in
  the orchestrator session.

Dispatch as built-in `Explore` for a one-shot look. Use `general-purpose` when
follow-up questions are likely, since `Explore` cannot be resumed.

Personas: codebase archaeologist, API documentation reader, competitive analyst,
incident historian, literature reviewer.

## Executor

Produces. Owns exactly one branch and the artifact on it.

- One plan, one branch, one executor. Never read or modify another executor's
  scope.
- Work within stated boundaries. A disagreement with the brief comes back as a
  reported deviation, not an improvisation.
- Commit its own work. Never push or open a PR unless the brief says to.
- Report honestly in the closeout: what was built, what was skipped, what failed.

Personas: backend engineer, frontend engineer, migration specialist, technical
writer, copywriter, screenwriter.

## Auditor

Checks. Reads the executor's output cold and reports what is wrong.

- Independent of the author. Never the same child that produced the work.
- Reports, never fixes. Findings come back to the orchestrator, which routes the
  fix to the executor that owns the branch.
- Distrust self-reports. Verify against the artifact and the environment, not
  against what the executor said it did.
- No padding. If the work is sound, say so in three lines. Low-value findings
  undermine the ones that matter.

Personas: security engineer, QA test engineer, accessibility reviewer,
performance analyst, fact checker, film director, editor.

## Choosing a persona

Pick for the standard you want applied, not for flavor. "Auditor as security
engineer" and "auditor as accessibility reviewer" read the same diff and return
different findings — that difference is the whole point of naming one.

State the persona in the delegation brief and in the Role column of the war room
table, so a later status check shows which standard was applied to which branch.

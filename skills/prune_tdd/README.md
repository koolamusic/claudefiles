# Why this skill exists

Tests written after the code verify what was built, not what was required —
and tests coupled to implementation details break on every refactor while
missing real regressions. This skill encodes the two rules that prevent both:
test observable behavior through public interfaces only, and work in vertical
slices (one test → one implementation → repeat), never "write all tests, then
all code".

The horizontal-slice anti-pattern section is the load-bearing part: bulk
test-writing tests *imagined* behavior and commits to structure before
anything is learned. The type-testing section (`Expect`/`Equal` compile-time
assertions) covers regressions in generics that runtime tests can't see.

## Provenance

Copied from `.reference/skills/tdd` with one adaptation: `bun typecheck`
generalized to "the project's typecheck command".

## Relation to other skills

`debug` routes here when a bug fix touches complex business logic (write the
failing repro first). The jira plugin's `jira-nyquist` agent enforces
test-coverage-after-the-fact per sprint criterion — different layer, no
overlap.

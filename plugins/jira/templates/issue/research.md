<!--
RESEARCH ISSUE TEMPLATE
Read ../GUIDE.md before filling. Pick a domain (backend / library / frontend / integration)
and apply the section matrix. Delete this comment and all [guidance] brackets before pushing.
-->

**Date**: {{YYYY-MM-DD}}
**Subsystem**: {{e.g. data-pipeline, resolver-layer, onboarding-ui}}
**Domain**: {{backend | library | frontend | integration | infra}}
**Severity**: {{Low | Medium | High | Critical}}
**Impact**: {{Availability | Integrity | Performance | Security | Correctness | UX}}
**Hypothesis by**: {{model-id, confidence}} [e.g. `claude-opus-4-7, medium`]

## Expected Behavior

{{What should happen in a correct world. One paragraph. Describe the invariant in terms a reader can check against the system.}}

## Mechanism

{{Why the bug happens, at the level of named functions, data shapes, or user-visible states.
For library/backend: name the functions and the control flow.
For frontend: describe the render/state sequence.
For integration: describe the cross-system timing or contract mismatch.}}

## Reproduction

<!-- Pick ONE form per domain, delete the others. -->

<!-- backend / integration form: -->
{{Minimal state + request that exhibits the bug. Include exact inputs.}}

<!-- library form: -->
```{{ts|js|py|go}}
// Runnable snippet — paste into a fresh project and observe {{expected output}}
```

<!-- frontend form (use freighter-mobile template): -->
### What version are you using?
{{e.g. v1.14.25 on iOS}}

### What did you do?
{{numbered steps}}

### What did you expect to see?
{{one line}}

### What did you see instead?
{{one line + screenshot/video below}}

![screenshot]({{attach image}})

## Target Code

<!-- Skip for pure visual bugs. For everything else, 3-6 citations, annotated. -->

- `{{path/to/file.ext:L-L}}` — {{what lives here and why it matters}}
- `{{path/to/file.ext:L-L}}` — {{what lives here and why it matters}}

## Evidence

{{What supports the hypothesis. Link citations to the claim. For visual bugs, the screenshot is the evidence — say what the reader should see in it.}}

## Anti-Evidence

{{What could weaken the hypothesis. Required. If you genuinely can't think of one, look harder — trivially-true claims and speculative claims both benefit from this discipline.}}

## Environment

<!-- Required for library and frontend. Optional for backend/integration unless version-specific. -->

- {{package@version}}
- {{runtime / OS / device}}
- {{adjacent tools — e.g. model, gateway, network}}

## Workaround

<!-- Optional but encouraged. If you've found a way around it, share it. -->

{{The escape hatch you're using. Constrains the fix space — any fix must not break this.}}

## Related

<!-- Optional. Use for integration issues spanning repos, or when this hypothesis echoes a finding elsewhere. -->

- {{org/repo#N}} — {{one line why}}

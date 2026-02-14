---
name: breadboarding
description: Transform a workflow description into affordance tables showing UI and Code affordances with their wiring. Use to map existing systems or design new ones from shaped parts.
---

# Breadboarding

Breadboarding transforms a workflow description into a complete map of affordances and their relationships. The output is always a set of tables showing numbered UI and Code affordances with their Wires Out and Returns To relationships. The tables are the truth. Mermaid diagrams are optional visualizations for humans.

---

## Use Cases

### 1. Mapping an Existing System

You have a workflow you're trying to understand. Provide code repo(s) and a workflow description (always from the perspective of an operator trying to make an effect happen). Output: affordance tables + optional Mermaid.

### 2. Designing from Shaped Parts

You have a new system sketched as an assembly of parts (mechanisms) per shaping. Provide the parts list, the R (requirement/outcome), and optionally the existing system. Output: affordance tables + optional Mermaid.

### 3. Mixtures

An existing system that must remain as-is, plus new pieces or changes. Breadboard both together — existing affordances and new ones — showing how they connect.

---

## Core Concepts

**Places** — A bounded context of interaction. The blocking test: can you interact with what's behind? No → different Place. Yes → same Place with local state changes. Places get IDs (P1, P2...) and can contain subplaces (P2.1, P2.2).

**Affordances** — Things you can act upon. UI affordances (U): inputs, buttons, displays. Code affordances (N): methods, subscriptions, stores, framework mechanisms.

**Wiring** — How affordances connect. Wires Out = control flow (what triggers what). Returns To = data flow (where output goes). Navigation wires go to Places, not to affordances inside them.

---

## The Output: Affordance Tables

Every breadboard produces these tables:

### Places Table

| # | Place | Description |
|---|-------|-------------|
| P1 | Search Page | Main search interface |
| P2 | Detail Page | Individual result view |

### UI Affordances Table

| # | Place | Component | Affordance | Control | Wires Out | Returns To |
|---|-------|-----------|------------|---------|-----------|------------|
| U1 | P1 | search-detail | search input | type | → N1 | — |
| U2 | P1 | search-detail | loading spinner | render | — | — |

### Code Affordances Table

| # | Place | Component | Affordance | Control | Wires Out | Returns To |
|---|-------|-----------|------------|---------|-----------|------------|
| N1 | P1 | search-detail | `activeQuery.next()` | call | → N2 | — |
| N2 | P1 | search-detail | `activeQuery` subscription | observe | → N3 | — |

### Data Stores Table

| # | Place | Store | Description |
|---|-------|-------|-------------|
| S1 | P1 | `results` | Array of search results |

### Column Definitions

| Column | Description |
|--------|-------------|
| **#** | Unique ID (P1, P2... for Places; U1, U2... for UI; N1, N2... for Code; S1, S2... for Stores) |
| **Place** | Which Place this affordance belongs to (containment) |
| **Component** | Which component/service owns this |
| **Affordance** | The specific thing you can act upon |
| **Control** | The triggering event: click, type, call, observe, write, render |
| **Wires Out** | What this triggers: `→ N4`, `→ P2` (control flow, including navigation) |
| **Returns To** | Where output flows: `→ N3` or `→ U2, U3` (data flow) |

---

## References

Load these progressively as needed:

| File | Contains | Load When |
|------|----------|-----------|
| [concepts.md](./references/concepts.md) | Places, subplaces, place references, modes, containment vs wiring, navigation wiring | You need to determine Place boundaries or model containment |
| [procedures.md](./references/procedures.md) | Step-by-step for mapping existing systems (11 steps) and designing from parts (8 steps) | Starting a breadboarding task |
| [principles.md](./references/principles.md) | Never use memory, mechanisms aren't affordances, two flows, data source rules, store placement | Reviewing or debugging a breadboard |
| [catalog.md](./references/catalog.md) | Complete element/relationship reference, qualification criteria, verification checks | Quick lookup of what qualifies as what |
| [visualization.md](./references/visualization.md) | Mermaid conventions, colors, lines, subgraphs, chunking, workflow annotations | Creating or reviewing Mermaid diagrams |
| [slicing.md](./references/slicing.md) | Vertical slicing methodology, constraints, procedure, visualization | Breaking a breadboard into implementation slices |
| [reflection.md](./references/reflection.md) | Design smell detection, naming test, splitting affordances, fixing wiring | Reviewing a breadboard for correctness |
| [examples.md](./references/examples.md) | Example A: mapping existing system, Example B: designing from parts + slicing | Need a worked example for reference |

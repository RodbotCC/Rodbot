---
id: 0019
slug: cowork-code-mission-control-architecture
date: 2026-04-19
operator: rodbot (human)
assistants: Claude Code (Opus 4.7)
status: captured (design, not yet built)
---

# 0019 — Claude Cowork + Claude Code + Mission Control: full-stack architecture vision

## What happened

Operator, riding in a car, dropped the full target architecture for
RodBot as he currently sees it. Not a build request — a capture-this
request so the architecture is in the ledger before we start designing
pieces of it. Quoting the spirit of the operator-yelled rule from
session 0018: every idea of this shape must land in a ledger the
session it happens. This TCL is that landing.

Operator explicitly said "I don't necessarily think we have to build
the whole thing right now." Scope of this session is **log only**.

## What changed

Files touched:

- `ledgers/TCL/0019-cowork-code-mission-control-architecture.md` (this
  file — new)
- `CLAUDE.md` — updated §9 open work queue to point at this TCL as the
  active architecture direction and retired the bare "design the
  intake/triage system from clean slate" line (superseded by this
  broader vision, which contains intake/triage as one component).
- `ledgers/current_state.md` — updated "Next architectural direction"
  to reference this TCL.
- `ledgers/contents_ledger.md` — added entry for this TCL.

No code, no new directories, no new ledger files yet.

## What changed — the architecture (as stated by operator)

### Two runtimes, different jobs

**Claude Cowork** — the sweeping layer. Uses connector access
(Close CRM, Slack, ClickUp, Google Workspace) to continuously pull
team + client + accounting state into our system.

- **Close CRM sweeps** — leads, opportunities, everything about
  clients + connections + Close's own automations.
- **Slack sweeps** — employee comms. Two purposes: (1) profile each
  teammate so the system can emulate their voice / style, (2)
  temporal continuity on the team's *present state* (who's doing
  what, where the mood/tempo of the team is right now).
- **ClickUp + Google Workspace sweeps** — accounting for the
  business (tasks, docs, calendar, spreadsheets). Operational
  ground truth.

**Claude Code** — the reasoning layer. Uses **Routines** (15/day
budget). Does the **ratings + residual checks** on what Cowork swept.
This is where scoring against the ledgers happens, not in Cowork.

> Vocab note: "Cowork" vs "Code" is the operator's split. Interpretation
> used in this TCL — Cowork = connector-driven sweeping (web-app
> Claude with Work-tier connectors), Code = Routines-scheduled agent
> with filesystem + git authority. If that mapping is wrong, correct
> it in the next TCL; the architectural split stands either way.

### The sweep cadence — seed then residual

1. **One long semi-manual seed sweep.** Operator overwatches (does
   not actually drive) a first pass that pulls a complete snapshot of
   Close + Slack + ClickUp + GWorkspace, scored and rated against the
   ledgers. One time. Heavyweight.

2. **Hourly residual sweeps, workdays, fully automated thereafter.**
   Every subsequent sweep compares against the last-known state,
   finds what's *new* since the seed (or since the previous sweep),
   and appends it as the *newest state*. The "what's important"
   signal surfaces from how residuals accumulate against the scoring
   ledgers.

This is explicitly the batch-hourly model decided in session 0018,
generalized to also cover connector data, not just filesystem intake.

### The scoring ledgers (starter set)

All residuals land against **five** ledgers at first:

1. **North Stars** — the big goals for the actual Comeketo Agent
   app. Already drafted (NS-01..NS-18).
2. **Sales Daily + Sales Weekly** — *NEW ledger family.* Operator
   will interview the sales team over several days to elicit their
   daily and weekly goals, then set those into the system. Incoming
   sweeps get scored against those goals as the sales tempo changes.
3. **Temporal Continuity** — the TCL + sessions arc; already in
   place.
4. **Ratio Lattice** — the relative-importance scoring grid;
   already placeholdered at `ledgers/ratio_lattice.md` (v0).
5. **Open Problems** — *NEW ledger.* "Kinda obvious" per operator —
   the running list of things that are broken / blocked / unresolved.
   Scoring ledger because open problems are what incoming data
   should be tested *against* as much as goals are.

**Not built this session.** The `sales/` and `open_problems.md`
ledgers exist only as intent until a later TCL.

### Mission Control — the presentation layer

The eventual target:

- Local filesystem on the Mac is the source of truth.
- Pushed to GitHub.
- Deployed onto a **Render** instance.
- Render instance has an Anthropic (Opus / Claude) API key plugged
  in so Mission Control can *reason over* what Code + Cowork have
  produced.
- This is how the "handshake" between Code and Cowork happens —
  they write into the file tree dynamically, Mission Control
  interprets it statically (operator's phrase: *"dynamically
  static"*).

### Open architectural questions (operator's own)

**Q1.** *"I feel like there's something easier here where we don't
actually have to use that extra Anthropic key on Mission Control.
Is this possible to be done by things like Opus and all that
because it's only one user actually using them with Claude Code
OAuth?"*

Claude's read (to be confirmed):

- Claude Code OAuth authenticates the CLI (and its Routines) as
  the operator. It does not extend to a separately-hosted Render
  web app — OAuth tokens are CLI-scoped and interactive, not a
  service credential a server-side app can call Claude with.
- Which means **Mission Control can only avoid a second
  Anthropic key if Mission Control doesn't need to generate new
  reasoning server-side.** It would be pure presentation over
  artifacts that Claude Code + Cowork already wrote into the
  repo. That's a real, viable shape — and arguably the cleanest:
  one reasoning runtime (Code + Routines), one display layer
  (Mission Control reading the committed file tree).
- If Mission Control *does* need live reasoning (ask-it-a-question
  UX, real-time synthesis that wasn't precomputed), then yes, it
  needs its own Anthropic key. That key is metered-billing, which
  re-opens the cost concern from session 0014. Mitigation: heavy
  precompute via Routines so Mission Control calls are rare and
  short.

**Q2.** *"If we do put Anthropic keys on Mission Control, how much
of a pain is it to allow them access to the whole file tree?"*

Claude's read:

- **Read access:** trivial. Render pulls the GitHub repo at deploy;
  the repo *is* the file tree. Mission Control's server-side code
  reads its own filesystem and hands content to the Anthropic API.
  Standard RAG shape. Not painful.
- **Write access (API-produced artifacts committed back to the
  repo):** moderate. Render instance needs a GitHub deploy-key /
  PAT with write scope, plus a commit-and-push loop. Possible, but
  introduces a second writer into git alongside Claude Code — which
  needs thought (who wins on conflict? is Mission Control writing
  to a different branch / subtree?).
- **Read-only Mission Control with writes coming only from Claude
  Code is the low-pain default.** Start there.

These answers are logged here as *Claude's current read*, not as
decided doctrine. Operator to confirm or correct in a follow-up.

## What we learned

1. **The system has three tiers, not two.** Up to now we've been
   thinking "filesystem + ledgers" as one tier and "connectors" as
   bolt-ons. Operator's framing splits it cleanly: **Cowork (sweep),
   Code (score), Mission Control (present)** — three tiers with
   different runtimes and different authorities. That framing is
   probably the most useful organizing split we have so far.

2. **Seed-then-residual is a pattern, not a one-off.** It applies to
   Close, to Slack, to ClickUp, to GWorkspace, and — conceptually —
   to any external system we decide to sweep later. Worth elevating
   to a named pattern in whatever architecture doc comes next.

3. **The ledger set is growing with purpose, not sprawl.** Sales
   Daily/Weekly + Open Problems weren't invented here; they're what
   the scoring needs in order to be meaningful against the residuals.
   Goals + obstacles are the two poles incoming data gets scored
   between.

4. **Mission Control's Anthropic-key question is really a "where
   does reasoning live" question.** If reasoning lives in Code +
   Routines (precompute), Mission Control can be keyless-presentation.
   If reasoning lives in Mission Control (live-query), it needs its
   own key and its own cost story. Operator's instinct that "maybe
   we don't need a second key" lines up with the Routines-heavy
   architecture we committed to in session 0018.

## Next

Not building anything this session. Queued in priority order:

- **(design)** Design the seed sweep for Close CRM specifically —
  what fields, what schema, how we express "scored against NS-01
  speed-to-lead" in a markdown artifact.
- **(design)** Sales Daily/Weekly ledger structure. Blocks on
  operator interviewing the sales team — put a placeholder file
  with the interview protocol when that window opens.
- **(design)** Open Problems ledger — decide format (single
  append-only markdown vs directory of per-problem files). Lean
  toward single markdown to start.
- **(design)** First Routine prompt: what does one hourly residual
  sweep actually look like, step-by-step, inside the 15/day budget?
- **(confirm with operator)** Q1 + Q2 above — does Mission Control
  need its own Anthropic key, or can we keep reasoning in Code +
  Routines and have Mission Control be presentation-only?
- **(confirm with operator)** "Cowork" vs "Code" vocabulary — is
  Cowork = Claude Work (web app + connectors) or something more
  specific?
- **(carry-forward, unchanged)** NS-01..NS-18 ratification, Pieces
  MCP sanity query, Ratio Lattice v0.1, `extraction-section-*` dedup
  check, raw-ai-mission-control skim (especially relevant now —
  prior Mission Control sketch).

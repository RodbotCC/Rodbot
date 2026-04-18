# North Star Ledger

The goals RodBot exists to achieve. Each goal has:

- `id` — `NS-NN`
- `statement` — one sentence, concrete enough to tell done from not-done.
- `importance` — `[0, 1]`, how load-bearing this goal is to the overall mission.
- `progress` — `[0, 1]`, how far along we are.
- `why` — the reason this goal is on the list.
- `as_of` — date of last update.

## v0 status

**All entries below are DRAFT as of 2026-04-17 — pending operator ratification.**
Drafted from the Comeketo Sales Playbook V2.0, the Tasting narrative, and the business Extraction document (archived under `intake/2026-04-17-bootstrap/`).

Importance × (1 − progress) gives a crude "remaining work" signal. The Ratio Lattice will refine this by scoring every TCL session, file, and directory against each North Star under the `goal-alignment` comparator.

---

## Goals

### NS-01 — 5-minute speed-to-lead, 24/7, without burning out SDRs

- statement: Every inbound lead (Facebook, website, 3rd-party, Wedding Expo) gets a human-quality first touch within 5 minutes, every hour of every day, with the SDR team augmented — not replaced — by RodBot.
- importance: 0.95
- progress: 0.05
- why: The playbook names this as the "uncompromising standard." Speed-to-lead is the single highest-leverage conversion lever in the inbound funnel and the one most likely to silently erode when the team is stretched.
- as_of: 2026-04-17

### NS-02 — Tasting pipeline is the conversion engine, measured and defended

- statement: Booked-tastings-per-week, show-up rate, on-the-spot booking-fee collection rate, and post-tasting close rate are instrumented, visible weekly, and trending up.
- importance: 0.9
- progress: 0.05
- why: Twice-weekly tastings are the structured pipeline stage with the strongest conversion. The Tasting narrative shows Rodrigo already knows how to make the experience differentiating; the gap is measurement and funnel-loss visibility, not the tasting itself.
- as_of: 2026-04-17

### NS-03 — Venue + planner relationships become a process, not a memory

- statement: Every partner venue and event planner has an assigned rep, a defined check-in cadence, logged interactions, and attributable revenue — queryable in one view, with no reliance on Rodrigo holding the relationships in his head.
- importance: 0.85
- progress: 0.05
- why: Venues are stated as the #1 referral source. The Extraction flagged this as a strategic growth mechanism that is currently operationalized but still fragile. Referral revenue compounds; losing a venue relationship silently is catastrophic.
- as_of: 2026-04-17

### NS-04 — Close CRM becomes the single sales authority

- statement: Lead source, ownership, stage, tasting-linked activity, quotes, booking-fee status, and commission data live in Close first; Sheets become read-only reflections or are retired.
- importance: 0.8
- progress: 0.15
- why: Close is already the sales backbone; the drift comes from parallel Sheets. Source-attribution answers ("which channel produced closed revenue last week?") should be one query, not three cross-referenced tabs.
- as_of: 2026-04-17

### NS-05 — One weekly operating surface for cash, labor, jobs, and prep

- statement: On Monday morning, one view shows: expected inflow by day, expected outflow by day, labor spend by person, every job with complexity tags (grill-on-site, water service, travel, party size), and the shared shopping/prep list — derived automatically, not hand-assembled.
- importance: 0.85
- progress: 0.05
- why: The Extraction makes clear the business is "manually overextended." Rodrigo already does this weekly — the job is to remove the manual assembly cost while preserving his visual shorthand (color, side-by-side, fast comprehension).
- as_of: 2026-04-17

### NS-06 — Close the Google ↔ Outlook/GoDaddy fragmentation

- statement: Communications, calendars, and shared docs run on one authoritative stack (or have a clear, documented bridge). No team member has to guess which inbox, which calendar, or which domain to use for what.
- importance: 0.6
- progress: 0.1
- why: Fragmentation surfaced in the Extraction as real friction. It is not the highest-leverage fix, but it is load-bearing under every other goal — automation across two mail/identity stacks is materially harder than across one.
- as_of: 2026-04-17

### NS-07 — Social media and content become a repeatable engine

- statement: A cross-platform pipeline (YouTube, TikTok, Instagram, LinkedIn, Twitter) publishes on cadence, leverages Rodrigo's on-camera fluency, and ties content performance back to lead-source attribution in Close.
- importance: 0.75
- progress: 0.05
- why: The Extraction explicitly flagged Rodrigo's excitement about social. The Tasting narrative proves he already produces broadcast-quality content naturally. The gap is cadence, repurposing, and attribution — not talent.
- as_of: 2026-04-17

### NS-08 — RodBot as the meta-harness across every tool on this machine

- statement: Claude Code / Work / Desktop, GPT, Codex, Cursor, Warp, Wispr Flow, Logi Options+, Raycast, and Pieces (with MCP) are syndicated so any goal above can be advanced from any entry point, with Pieces continuously cataloguing activity into the TCL.
- importance: 0.9
- progress: 0.05
- why: This is the enabling goal — without it, the other seven regress to manual labor. The entire reason this machine was wiped and re-scaffolded is to make this specific goal real this time.
- as_of: 2026-04-17

### NS-09 — Comeketo becomes a templatable reference model for similar SMBs

- statement: The operating system built here (ledgers + syndicated AI + Close + Sheets consolidation + venue ops + content engine) can be lifted and re-pointed at another catering / event-services SMB with <30 days of configuration.
- importance: 0.5
- progress: 0.0
- why: Implied by the Extraction's closing observation (#32, #33). Not a near-term driver of decisions, but a useful tiebreaker: when two implementation paths are equivalent for Comeketo, prefer the one that generalizes.
- as_of: 2026-04-17

---

## NS-10..NS-18 — implementation note

The nine North Stars below (drafted 2026-04-18) rhyme with experimental architecture the operator is building separately on another machine (Delta / Sylvia stack: bounded world state, predictive-processing modules, metacognition, packet lanes, `world.json`, Sales Oracle). **That is not RodBot doctrine.** These NSes are adopted here as RodBot-facing *principles and intentions*, not as claims that RodBot already contains the corresponding implementation. Delta-side internals should not be imported into RodBot by default — any port happens deliberately, one doctrine artifact at a time, via intake + TCL. Until then, these goals stand on RodBot's existing substrate (ledgers, file-tree, Pieces, intake, sessions, CLAUDE.md).

Importances below are Claude-drafted from the operator's prose; they share the `pending ratification` status of NS-01..NS-09.

---

### NS-10 — Shared Operational Awareness

- statement: RodBot continuously turns fragmented company activity into a current, visible, trustworthy operational picture — a company-facing stream of meaningful deltas (new tastings booked, stale leads crossing thresholds, ownership changes, meaningful replies, pipeline-health shifts, newly identified risks) so no one has to manually reconstruct reality from Close + Slack + ClickUp + calendars + notes + memory.
- importance: 0.85
- progress: 0.0
- why: The Extraction's framing — "manually overextended, not broken" — says the opportunity isn't to invent a new operating reality, but to make the existing one continuously visible without manual reassembly. Complements NS-04 (Close-as-authority), NS-05 (weekly view), NS-08 (syndication): turns them into a live company-facing surface instead of internal plumbing. "Facebook timeline for the company," but grounded in business state.
- as_of: 2026-04-18

### NS-11 — Queryable Company Mainframe

- statement: Any authorized employee can ask RodBot about the current status of a lead, opportunity, workflow, client situation, or internal operational question and receive a grounded, current, decision-useful answer that increasingly explains why the state is what it is and what the likely next move should be.
- importance: 0.85
- progress: 0.0
- why: NS-10 is push (RodBot surfaces what it already considers meaningful); NS-11 is pull (the long tail of "what's going on with X?" the team currently answers by cross-referencing Close, Sheets, Slack, and memory). Different interaction mode, same underlying state. Paired with NS-10, these two together are the human-facing interface to everything else.
- as_of: 2026-04-18

### NS-12 — Style-Aware Drafting with Human Approval

- statement: RodBot learns how Rodrigo, Andre, and other approved teammates actually communicate, generates drafts in a sender-appropriate voice grounded in real prior messages and company doctrine (the Sales Playbook's tone rules — open-ended questions, tactical empathy, direct framing, no fake enthusiasm, no generic SDR language), and always routes the final send decision through explicit human approval.
- importance: 0.8
- progress: 0.0
- why: Horizontal capability that serves NS-01 (5-min first-touch at scale), NS-02 (tasting follow-up), NS-03 (venue/planner communication), NS-07 (content). Not impersonation — a drafting partner. Slack evidence already shows real in-team debate about customized vs. template voice, which means the need is already live. Approval gate is non-negotiable; RodBot should never send unattended on a teammate's behalf.
- as_of: 2026-04-18

### NS-13 — Delta Anomaly Detection

- statement: RodBot learns the normal rhythm of change in the business (lead flow, ownership transitions, stage movement, reply cadence, stale-deal growth, tasting movement, message volume) and surfaces meaningful deviations from that pattern as operational alerts, so abnormal motion is noticed before it becomes obvious damage or missed opportunity.
- importance: 0.65
- progress: 0.0
- why: Higher-order extension of NS-10. NS-10 answers "what changed?"; NS-13 answers "is the *pattern* of change itself normal?" Requires baseline history before it can function, so progress trails the other awareness-layer goals by design. Quality bar isn't "flag every weird thing" — it's distinguishing meaningful abnormal motion from ordinary variation, and getting better at that over time through correction (NS-14).
- as_of: 2026-04-18

### NS-14 — Correction-Driven Trust

- statement: Every important RodBot output — a surfaced delta, a queried answer, a drafted message, an anomaly alert, an automated action — can be challenged, categorized (incorrect fact, outdated status, wrong framing, wrong priority, weak draft, confusing presentation, missing context, bad tone, broken automation, should-have-asked-first), and fed back into the system as a structured correction signal that produces a receipt and improves future behavior.
- importance: 0.85
- progress: 0.0
- why: Complex automation is only trustworthy if it's contestable. Without a formal correction loop, users are trapped between blindly trusting RodBot and abandoning it — the third option (structured pushback that visibly matters) is what makes the system corrigible. Trust is built by visible fixability, not by pretending the system is perfect. This goal cross-cuts everything: NS-10, 11, 12, 13 all produce outputs that should be contestable through this loop.
- as_of: 2026-04-18

### NS-15 — Directory-Level Domain Intelligence

- statement: Each major RodBot operating surface (intake, ledgers, pieces, screenshots, Close mirrors, future packet lanes) becomes a locally governed domain with its own doctrine file — explaining what may enter, what mutations are allowed, what ledgers must update, what its authority boundary is, and when it should escalate rather than act — so work is routed through specialized local logic before one central agent touches it.
- importance: 0.6
- progress: 0.15
- why: Already prefigured on disk: `scripts/triage_protocol.md` governs intake, this CLAUDE.md governs the root, `ledgers/TCL/README.md` governs the TCL, and `ledgers/pieces_memory_ledger.md` governs pieces. NS-15 generalizes that pattern instead of letting each domain stay implicit. Protects against the failure mode where one big agent acts too early without honoring rules a specialized domain would have enforced.
- as_of: 2026-04-18

### NS-16 — Intelligent Trigger Bus / Multi-Runner Execution

- statement: Important filesystem and system events (files landing, screenshots arriving, sweeps completing, queues transitioning, significant state changes) are turned into structured jobs, classified, and routed into the correct execution lane — Claude Code, Codex, Warp, Cursor, Raycast, Pieces, future runners — under orchestrator control, serial when sequencing matters, parallel when it doesn't, without collisions or hidden mutations.
- importance: 0.75
- progress: 0.05
- why: NS-08 says every tool is a syndicated entry point; NS-16 is how that works without stepping on itself. The intake `SessionStart` hook (`scripts/audit_intake.sh`) is the first narrow proof-of-concept — a watched-directory event producing structured pending-work injection. NS-16 generalizes that into a real routing layer across every runner on the machine.
- as_of: 2026-04-18

### NS-17 — Observable Automation

- statement: Every important RodBot trigger, route, domain call, lock, retry, failure, correction, and final outcome is visible in a human-readable operations surface (a live event stream, active-jobs view, queue state, failures/retries view, current-believed-state summary) so the system can be monitored, trusted, and debugged without guesswork.
- importance: 0.8
- progress: 0.05
- why: Complex automation becomes dangerous the moment it goes invisible — one old script or misrouted job creates haunted side effects that are nearly impossible to trace. NS-14 (correction), NS-16 (routing), NS-18 (durability), NS-13 (anomaly), NS-10 (shared awareness) all depend on the system being inspectable. Cross-cutting prerequisite, not a standalone feature.
- as_of: 2026-04-18

### NS-18 — Durable, Replayable Execution

- statement: Important RodBot workflows (sweeps, intake triage, approval flows, multi-step orchestrations, long-running draft-review-send sequences) preserve state, survive interruption, resume cleanly from known state, and remain inspectable and replayable over time — so automation doesn't become haunted when a script, runner, session, or machine stops halfway through.
- importance: 0.7
- progress: 0.05
- why: Natural extension of the existing pattern — `ledgers/intake_state.json`, the append-only `intake_events.jsonl`, and the hook-driven sweep already treat intake as stateful rather than as one-off scripts. NS-18 applies that same discipline to all load-bearing workflows: approvals, drafts, sends, anomaly alerts. Reinforces the one-piece-at-a-time discipline because durable workflows are easier to certify when they're explicit and stateful rather than fragile.
- as_of: 2026-04-18

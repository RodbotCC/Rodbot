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

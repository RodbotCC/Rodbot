# Temporal Continuity Ledger (TCL)

Append-only. One file per session, named `NNNN-slug.md`, numbered in order of creation.

Each entry records:
- **When** — ISO date, wall-clock start/end if known.
- **Who** — human operator + which assistants/tools were in the loop.
- **What happened** — narrative of the session.
- **What changed** — files created/modified, systems touched.
- **What we learned** — insights, surprises, corrections.
- **Next** — the immediate next piece of functionality to build.

The TCL is the load-bearing memory. If the other ledgers are lost, they can be rebuilt from the TCL.

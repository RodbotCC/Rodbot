# RodBot

Semi-autonomous / autonomous intelligence syndication for a catering company.
This machine *is* RodBot — its home directory is the substrate.

## Principles

1. **One piece of functionality at a time.** Build → test → certify → log → update ledgers → move on.
2. **Everything is searchable and cataloged.** Nothing important happens without a ledger entry.
3. **The ledgers are the memory of the system.** Human-readable, machine-queryable.
4. **Bootstrap toward a meta-harness** for every tool on this computer (Claude Code/Work/Desktop, GPT, Codex, Cursor, Warp, Wispr Flow, Logi Options+, Raycast, Pieces, etc.).

## Ledgers

All live under `ledgers/`:

- **TCL — Temporal Continuity Ledger** (`ledgers/TCL/`): append-only log of sessions and events, in time order. The project's memory through time.
- **Directory Ledger** (`ledgers/directory_ledger.md`): what lives in every directory and subdirectory.
- **Contents Ledger** (`ledgers/contents_ledger.md`): one-line summary of every file's purpose.
- **Ratio Lattice Ledger** (`ledgers/ratio_lattice.md`): a scoring system rating how relevant each ledger entry is to every other, under a chosen comparator. Built from scratch.
- **North Star Ledger** (`ledgers/north_star.md`): the goals we are moving toward, each scored for importance and progress.

## Current status

Day 0. See `ledgers/TCL/0001-birth.md` for the first session.

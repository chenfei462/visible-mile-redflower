# Next-Stage Developer Handoff Document Design

## Goal

Create a complete, developer-facing project introduction document for the current state of the game so the next-stage game developer can quickly understand what exists, how it runs, how the main systems connect, and where to continue development safely.

## Audience

Primary audience:

- the next-stage gameplay or technical developer taking over this repository

Secondary audience:

- producers, collaborators, or reviewers who need an accurate snapshot of the current playable demo

## Deliverable

The implementation should produce a Markdown document under `docs/`:

- `docs/project-handoff-guide.md`

The document should be detailed enough to work as a handoff reference, not just a public-facing pitch or short README summary.

## Source of Truth

The handoff document should prioritize information in this order:

1. `project.godot` for runtime entry and autoload structure
2. `README.md` for officially stated scope, run commands, and release workflow
3. `gameDesign.md` for intended design framing and progression goals
4. current code under `scripts/`, `scenes/`, `data/`, and `tests/` for implemented architecture and behavior

If README targets and current data files differ, the document should say so clearly instead of pretending they match perfectly.

## Document Type

This is a combined handoff document:

- part design overview,
- part technical architecture guide,
- part current-state implementation summary,
- part next-phase recommendation memo.

It should optimize for developer onboarding, not marketing language.

## Required Sections

The final document should include these sections:

1. Project overview
2. Current playable scope and completion snapshot
3. Core gameplay loop and intended player experience
4. System-by-system breakdown
5. Engineering structure and important files
6. Runtime flow from launch to end-of-day/end-of-run
7. Data-driven content organization
8. Testing, build, and release workflow
9. Current limitations, mocks, risks, and technical debt
10. Recommended next-stage development priorities
11. Suggested reading order for a new developer

## Content Expectations

The document should:

- explain what the game is in practical terms,
- distinguish implemented behavior from planned behavior,
- name key autoload modules and their responsibilities,
- describe how UI, runtime state, rules, events, and persistence fit together,
- document the current AI fallback architecture and Steam mock boundary,
- describe available automated tests and what confidence they provide,
- call out places where the repo is still in flux, including actively edited data content,
- give concrete next steps for a developer inheriting the codebase.

## Style

The final document should be:

- written in Chinese,
- structured and skimmable,
- accurate to the current repository state,
- explicit when something is provisional, mocked, or not yet production-ready.

It should avoid:

- marketing exaggeration,
- pretending missing integrations already exist,
- vague advice like "optimize later" without naming the actual subsystem.

## Known Repository Reality To Reflect

The design should explicitly reflect the current state we verified:

- the project runs through `res://scenes/Main.tscn`,
- `project.godot` defines a substantial autoload layer,
- the project is playable as a Godot demo instead of a split frontend/backend application,
- AI event generation can fall back locally when remote config is missing,
- Steam integration is currently a mock bridge,
- save/load and smoke/core tests already exist,
- launcher scripts were recently adapted to local fixed Godot paths on this machine,
- data files are still being actively edited and may temporarily diverge from README framing.

## Verification

Before delivering the final handoff document, implementation should verify:

- the Markdown file exists under `docs/`,
- its section structure matches this design,
- referenced paths and system names match the repository,
- no section claims an unverified production integration.

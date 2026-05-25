# Opening Flow Unification Design

## Goal

Unify the player's opening experience around one canonical six-step contract:

`buy_pack -> assign_resident -> collect_funds -> buy_next_pack -> build_facility -> handle_resident_need`

The fix must make the live tutorial, the left-side tasks panel, and the smoke tests all speak the same flow. It must also preserve progress for existing saves instead of forcing old players to replay the opening.

## Problem Summary

The current build has three separate opening contracts:

- `TutorialManager.gd` and `MainView.gd` still drive first-time guidance from the old four-step milestone flags (`first_pick_done`, `first_craft_done`, `first_place_done`, `first_problem_done`).
- The tasks panel already exposes a newer six-step tabletop opening.
- The smoke tests still mostly prove the older `bulletin -> hand -> craft -> board` route.

That mismatch causes two visible problems:

1. The coachmark can ask the player to act on the tabletop opening cards, but the completion condition still waits for a bulletin pick.
2. The "build facility" step can finish as soon as a facility exists in tabletop autocraft state, even if the player has not actually placed it onto the board.

## Options Considered

### 1. Replace the tutorial system with a brand-new onboarding state machine

Pros:

- Clean separation from old first-time flags.
- Easy to name the new six steps directly.

Cons:

- Highest migration risk.
- Touches save compatibility, welcome flow, and live UI at the same time.
- Too large for the current bugfix.

### 2. Add one canonical opening contract and keep the legacy flags as compatibility data

Pros:

- Fixes the player-facing mismatch without throwing away existing save semantics.
- Lets the tasks panel, coachmark, and live guidance read from one shared resolver.
- Keeps changes local to `MainView.gd`, `TutorialManager.gd`, save normalization, and tests.

Cons:

- Leaves some old milestone keys in place as compatibility baggage.
- Requires careful mapping so later progress implies earlier progress on old saves.

### 3. Patch each surface independently

Pros:

- Smallest immediate code diff.

Cons:

- Preserves drift.
- Makes future regressions likely because tutorial, task panel, and tests would still encode separate rules.

## Recommended Approach

Use option 2.

We will keep the existing tutorial progress dictionary for compatibility, but stop treating the old four-step flags as the source of truth for the opening loop. Instead, `MainView.gd` will expose one canonical opening objective resolver, and every player-facing onboarding surface will use it.

## Canonical Opening Contract

The shared contract is:

1. `buy_pack`
2. `assign_resident`
3. `collect_funds`
4. `buy_next_pack`
5. `build_facility`
6. `handle_resident_need`

### Completion Rules

- `buy_pack`
  - Complete when `card_pack_open_count >= 1`.
- `assign_resident`
  - Complete when the player has already produced the first opening result from tabletop resident work.
  - Compatibility rule: if later opening steps are already complete, this step also counts as complete.
- `collect_funds`
  - Complete when `collected_tabletop_funds > 0`.
  - Compatibility rule: if `buy_next_pack`, `build_facility`, or `handle_resident_need` is already complete, this step also counts as complete.
- `buy_next_pack`
  - Complete when `card_pack_open_count >= 2`.
- `build_facility`
  - Complete only when a facility is actually registered on the board with a real root/cell index.
  - A tabletop autocrafted facility with `cell_index = -1` must not satisfy this step.
- `handle_resident_need`
  - Complete when at least one resident need entity has status `resolved`, or the direct need-resolution action succeeds.

## Guidance Unification

### Shared Resolver

`MainView.gd` will own a small resolver that returns the six opening objectives, their completed state, their unlocked state, and the single current objective.

The following systems will all consume that resolver:

- `get_tasks_panel_objectives()`
- `get_active_tutorial_coachmark()`
- `get_tutorial_guidance_state()`
- the progress lines shown in the live guidance card

### Coachmark Mapping

The current objective maps to a tutorial target like this:

- `buy_pack` -> `card_pack`
- `assign_resident` -> `tabletop_opening_cards`
- `collect_funds` -> `tabletop_funds`
- `buy_next_pack` -> `card_pack`
- `build_facility`
  - `hand_facility` if a placeable facility already exists in hand
  - otherwise `hand_quick_craft`, `craft`, or `hand` depending on what action can build the facility next
- `handle_resident_need`
  - `demand` when a pending need exists
  - `next_day` when the player needs to advance time before a need can appear

### Live Guidance Card

The live card should no longer render the old four-step summary. It should render the six-step opening summary from the same canonical objectives used by the task panel.

The live card remains hidden when:

- the welcome card has not been seen yet, or
- all six opening objectives are complete

## Compatibility Strategy

### Saves

Existing saves should not be forced to replay the opening.

We will preserve the current `tutorial_progress` dictionary and its welcome-state normalization. For opening completion, we will rely on current saved run state first:

- `card_pack_open_count`
- `collected_tabletop_funds`
- `built_facilities`
- `resident_need_entities`
- saved UI context such as `selected_recipe_ids` and tabletop state

Where older saves have already progressed beyond an earlier step, later-step completion will imply earlier-step completion.

### Legacy Four-Step Flags

The old flags stay in the save format for compatibility, but they are no longer the primary contract for opening guidance. Where practical, action triggers on tabletop interactions should still keep them moving so older regression coverage does not become misleading.

## Test Changes

### Core Tests

Add or update tests that prove:

- the tasks panel, coachmark, and live guidance card all expose the same six-step contract
- the collect-funds step points at tabletop funds instead of bulletin pick
- `build_facility` stays incomplete when a facility exists only as tabletop autocraft state
- old saves with later opening progress still appear advanced in the new contract

### Smoke Tests

Update the smoke tests so the opening route actually exercises:

- pack opening
- tabletop resident assignment
- tabletop fund collection
- second pack opening
- facility placement onto the board
- resident-need handling

## Out Of Scope

- Replacing the save format wholesale
- Rewriting the welcome-card system
- Large-scale `MainView.gd` refactors unrelated to the opening flow
- Rebalancing opening recipes or packs unless a test proves the current flow cannot complete

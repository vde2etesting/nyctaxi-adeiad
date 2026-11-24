# Plan: Fix the double-counted airport fee in the revenue walk

**Goal:** Make the fare residual net of every component the walk models, so the nine components of `finance.mart_revenue_component_bridge` sum to billable revenue instead of counting the airport fee twice.

**Requirement:** [`docs/cases/2026-11-24-airport-fee-double-counted-in-revenue-walk.md`](../cases/2026-11-24-airport-fee-double-counted-in-revenue-walk.md) (`kinds: [fix]`, `code-change` approved)

**Constraints:**

- The residual is "what is left of a trip's total after every modelled fare component" (`CONTEXT.md`, "Fare residual"); the walk models the airport fee as component 8, so the residual is net of it.
- Apply the billable rule where revenue is reported ([ADR 0003](../adr/0003-billable-trip-definition-and-where-it-applies.md)); the bridge already filters on `is_billable`.
- No column is added, removed or retyped: the enforced dbt contract and the ODCS contracts keep their shape, so neither contract version moves.
- Changing the macro restates published values; `fct_trip` is incremental by `trip_key`, so existing rows change only under `--full-refresh`, approved as a breaking delta in the Case record.
- Compare money at the cent (`round(x, 2)`), never bit for bit.
- Run dbt through the runtime wrapper from `transformation/`, target `dev`; `dbt deps` first because `dbt_packages/` is absent.

## Scope and impact

| Artifact | Kind | Action | Requirements | Design record | Gate |
| --- | --- | --- | --- | --- | --- |
| `transformation/tests/assert_revenue_bridge_components_sum_to_total.sql` | test | create | Case record | `code is contract` | `dbt test --select assert_revenue_bridge_components_sum_to_total --target dev` (fails first: 21 groups) |
| `test-map.json` | project-config | modify | Case record | `code is contract` | `python3 -m pytest tests/test_maps.py -q` |
| `transformation/macros/finance.sql` | macro | modify | Case record | `code is contract` | `dbt build --select int_trip_fare_components+ --full-refresh --target dev` |
| `transformation/models/docs.md` | docs | modify | Case record | `code is contract` | `dbt parse --target dev` |
| `docs/design/models/finance/mart_revenue_component_bridge.md` | design record | create | Case record | this record | `python3 -m pytest tests/test_adr_links.py -q` |

**Change impact:** `intermediate.int_trip_fare_components` (`fare_residual`, `has_unexplained_residual`) → `core.fct_trip.fare_residual` → `finance.mart_revenue_component_bridge.c_residual` and `ops.mart_trip_quality_scorecard.unbalanced_total_count`; the canonical metric `fare_residual_total` follows `fct_trip.fare_residual`. No column or type changes; the only shape risk is the full refresh of the published `fct_trip`, already approved.

## Tasks

### Task 1: The failing assertion

**Requirements:** the Case record's `code-change` acceptance · **Design:** `code is contract` · **Skill:** `generating-dbt-model` · **Depends on:** none

- [ ] Author `transformation/tests/assert_revenue_bridge_components_sum_to_total.sql`: group `mart_revenue_component_bridge` by `trip_month, service_type_key, borough_name`, compare `sum(component_amount)` with `max(total_amount)`, and return the groups where the absolute gap exceeds 0.01.
- [ ] Add that file to `test-map.json` under `modules.finance.data`.
- [ ] Run `dbt deps --target dev`, then `dbt test --select assert_revenue_bridge_components_sum_to_total --target dev`; expect `FAIL 21` — the 21 groups that carry an airport fee. This is the required failing-first signal.
- [ ] Run `python3 -m pytest tests/test_maps.py -q`; expect exit 0.
- [ ] Commit and push `transformation/tests/assert_revenue_bridge_components_sum_to_total.sql` and `test-map.json`.

### Task 2: The residual definition

**Requirements:** the Case record's `code-change` acceptance · **Design:** `code is contract` · **Skill:** `generating-dbt-model` · **Depends on:** Task 1

- [ ] Subtract `coalesce({{ alias }}.airport_fee, 0)` in `fare_residual` in `transformation/macros/finance.sql`, so `total_amount` equals fare + tip + tolls + the four surcharges + airport fee + residual.
- [ ] Add the airport fee to the component list in the `{% docs fare_residual %}` block in `transformation/models/docs.md`.
- [ ] Run `dbt build --select int_trip_fare_components+ --full-refresh --target dev`; expect every node to pass, including `assert_revenue_bridge_components_sum_to_total` and both contract-enforced marts.
- [ ] Run the acceptance condition from the Case record against the sandbox (`lakehouse_query`, target `ephemeral`): Q1 components sum to 263,480,834.99 at the cent, no group off by more than 0.01, and `c_residual` reads −3,269,079.50.
- [ ] Commit and push the macro and the docs block.

### Task 3: The design record and the contract proof

**Requirements:** the Case record's `code-change` acceptance · **Design:** the record created here · **Skill:** `generating-dbt-model` · **Depends on:** Task 2

- [ ] Author `docs/design/models/finance/mart_revenue_component_bridge.md`: grain, `D-01` (the residual is net of every modelled component, the airport fee included, so the walk does not count it twice), consumers, history.
- [ ] Run `dbt parse --target dev`; expect exit 0.
- [ ] Run `python3 .agents/skills/data-contract/scripts/odcs.py check` and `python3 .agents/skills/data-contract/scripts/odcs.py diff origin/main`; expect exit 0 with no version move — the proof that the enforced contract is unaffected.
- [ ] Run `python3 -m pytest tests/test_adr_links.py -q`; expect exit 0.
- [ ] Commit and push the design record.

## Execution evidence

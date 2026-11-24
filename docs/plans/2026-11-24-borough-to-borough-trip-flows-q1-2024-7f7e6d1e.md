# Plan: Borough-to-borough trip flows Q1 2024

**Goal:** Publish `agg.agg_borough_flow_monthly`, one row per pickup month and origin and destination borough, with billable trips, revenue and the origin borough's cross-borough trip share, as a contracted boundary relation of the trips star.

**Requirement:** `docs/requirement/2026-11-24-borough-to-borough-trip-flows-q1-2024-7f7e6d1e.md`

**Constraints:**
- Billable trips only, inside the reporting window (`in_report_window`), applied in gold (ADR 0003).
- No trip-count floor; every populated borough pair is published (ADR 0018).
- `Unknown` and `N/A` kept as boroughs and flagged on both sides (ADR 0012).
- Pairs with no billable trip in a month have no row.
- Month is `cast(date_trunc('month', pickup_datetime) as date)` as `month_start_date`.
- Schema `agg` (design `## Schema`, user answer).
- Contract starts `status: proposed` (version 1.0.0) and becomes `active` in Task 2; `odcs.py generate` owns `data_type`, tests and `contract.enforced`.
- Sandbox target `dev`; no production manifest, so no `--defer`.

## Scope and impact

| Artifact | Kind | Action | Requirements | Design record | Gate |
| --- | --- | --- | --- | --- | --- |
| `agg_borough_flow_monthly` (model, `_agg.yml` entry, `_unit_tests.yml`, 5 singular tests) | model | create | `R-01`–`R-07` | `docs/design/models/agg/agg_borough_flow_monthly.md` | `dbt build --select agg_borough_flow_monthly+ --exclude test_type:unit` then `dbt test --select agg_borough_flow_monthly,test_type:unit` |
| `contracts/agg/agg_borough_flow_monthly.odcs.yaml` | contract | create | `R-08` | `docs/design/models/agg/agg_borough_flow_monthly.md` | `odcs.py check` |
| `logical-model/nyc_taxi_analytics.ossie.yaml`: dataset `borough_flows`, logical source `borough_flows`, metric `cross_borough_trip_share` | logical-model | create | `R-08` | `docs/design/models/agg/agg_borough_flow_monthly.md` | `ossie.py validate`, `coverage`, `suppliers`, `notes`, `generate-tests --check` |
| `ontology/nyc_taxi_analytics.mapping.yaml` | ontology | verify | `R-08` | `docs/design/models/agg/agg_borough_flow_monthly.md` | `ossie.py validate ontology/`, `refs`, `glossary` |

**Change impact:** no existing model, contract or published relation is modified. Shared files gain entries only: `transformation/models/marts/agg/_agg.yml`, `test-map.json`, `transformation/tests/` (five new singular tests plus the regenerated semantic tests). The new relation has no downstream consumer in the repository.

## Tasks

### Task 1: Contract (proposed), model and tests

**Requirements:** `R-01`–`R-07` · **Design:** `docs/design/models/agg/agg_borough_flow_monthly.md` · **Skill:** `data-contract` (contract), `generating-dbt-model` (model) · **Depends on:** none

- [ ] Author `contracts/agg/agg_borough_flow_monthly.odcs.yaml` through `data-contract`: `status: proposed`, version 1.0.0, grain statement `one row per pickup month, origin borough and destination borough`, properties `month_start_date` (date), `origin_borough` (string, required), `dest_borough` (string, required), `origin_is_unresolved_borough` (boolean), `dest_is_unresolved_borough` (boolean), `is_intra_borough` (boolean), `trip_count` (integer, required), `total_revenue` (number), `origin_trip_count` (integer, required), `origin_cross_borough_trip_count` (integer, required), `cross_borough_trip_share` (number, required), `primaryKey` on the three grain columns.
- [ ] Author `transformation/models/marts/agg/agg_borough_flow_monthly.sql`: `fct_trip` joined to `dim_zone` as origin (`pickup_zone_key`) and as destination (`dropoff_zone_key`), `where in_report_window(f.pickup_datetime) and f.is_billable`, grouped by month and the two borough names; the two flags from `dim_zone.is_unresolved_zone`, `is_intra_borough` from the two borough names, and the origin-month window sums for `origin_trip_count`, `origin_cross_borough_trip_count` and `cross_borough_trip_share` (`safe_divide`); every column cast to its declared type. No `contract: {enforced: true}` in this task: `generate` writes it in Task 2.
- [ ] Add the model entry to `transformation/models/marts/agg/_agg.yml` with a description stating grain, population (billable, in window, both zones resolved), the absence of a floor (ADR 0018) and the share's denominator, and a description on every column.
- [ ] Add `transformation/models/marts/agg/_unit_tests.yml` with unit test `agg_borough_flow_monthly` over `fct_trip` and `dim_zone` fixtures (with `overrides: {vars: {report_start: '2024-01-01', report_end: '2024-04-01'}}`): a cross-borough pair, an intra-borough pair, an `Unknown` origin, a `N/A` destination and a pickup on the first and last day of a month, asserting each row's counts, flags and share.
- [ ] Add `transformation/tests/assert_borough_flow_one_row_per_grain.sql`.
- [ ] Add `transformation/tests/assert_borough_flow_publishes_every_pair.sql`: a full outer join between the table's (month, origin, destination) cells and the star's, reporting a missing pair, an extra pair or a row with `trip_count < 1`.
- [ ] Add `transformation/tests/assert_borough_flow_share_holds.sql`: recompute the share from the table's own `origin_cross_borough_trip_count` and `origin_trip_count`, reporting a mismatch beyond 1e-9 and any origin-month whose rows disagree on the share.
- [ ] Add `transformation/tests/assert_borough_flow_flags_unresolved_boroughs.sql`: report a row whose `origin_is_unresolved_borough` or `dest_is_unresolved_borough` disagrees with the borough name being `Unknown` or `N/A`.
- [ ] Add `transformation/tests/assert_borough_flow_covers_every_trip.sql`: report a difference between the table's summed `trip_count` and the star's billable in-window trips with both zones resolved.
- [ ] Add the five new singular tests to the `agg` `data` list in `test-map.json`.
- [ ] Run `cd transformation && dbt deps`; expect exit 0.
- [ ] Run `cd transformation && dbt build --select agg_borough_flow_monthly+ --exclude test_type:unit --target dev --warn-error-options '{"error":["NoNodesForSelectionCriteria"]}'`; expect PASS.
- [ ] Run `cd transformation && dbt test --select agg_borough_flow_monthly,test_type:unit --target dev --warn-error-options '{"error":["NoNodesForSelectionCriteria"]}'`; expect PASS.
- [ ] Run `python3 .agents/skills/data-contract/scripts/odcs.py check`; expect exit 0.
- [ ] Run the `R-02` acceptance check: `sum(trip_count)` = 9,604,511 and `round(sum(total_revenue), 2)` = 263,480,834.99, recomputed from `fct_trip` joined twice to `dim_zone` in the sandbox.
- [ ] Run the `R-05` acceptance check: recompute each origin-month's share from `fct_trip` independently and match every row at 1e-9.
- [ ] Commit and push the contract, SQL, YAML, unit test, five singular tests and `test-map.json`.

### Task 2: Ossie dataset, source and metric; contract activation; ontology gates

**Requirements:** `R-08` · **Design:** `docs/design/models/agg/agg_borough_flow_monthly.md` · **Skill:** `semantic-model`, `data-contract` (activation), `ontology`, `validating-semantic-model`, `validating-ontology` · **Depends on:** Task 1

- [ ] Add to `logical-model/nyc_taxi_analytics.ossie.yaml` through `semantic-model`: dataset `borough_flows` (`source: agg.agg_borough_flow_monthly`, primary key the three grain columns), aggregate logical source `borough_flows` with `content_levels` from the `GROUP BY` and `content_filter` from the `WHERE` and the two inner joins, its `column_map` binding `trip_count` to `billable_trip_count` and `total_revenue` to `billable_revenue`, and metric `cross_borough_trip_share` reading the published share column beside its numerator and denominator counts.
- [ ] Set `contracts/agg/agg_borough_flow_monthly.odcs.yaml` to `status: active`, run `python3 .agents/skills/data-contract/scripts/odcs.py generate`, then `check` and `diff origin/main`; expect exit 0 from each.
- [ ] Run `python3 .agents/skills/semantic-model/scripts/ossie.py generate-tests logical-model/ transformation/tests`; expect it rewrites the three `assert_semantic_*.sql` files.
- [ ] Run `cd transformation && dbt build --select agg_borough_flow_monthly+ --exclude test_type:unit --target dev --warn-error-options '{"error":["NoNodesForSelectionCriteria"]}'`; expect PASS with the enforced contract now in place.
- [ ] Run `cd transformation && dbt test --select agg_borough_flow_monthly,test_type:unit --target dev` and `dbt test --select assert_semantic_content_holds assert_semantic_level_keys_hold assert_semantic_levels_hold --target dev`; expect PASS.
- [ ] Run `python3 .agents/skills/semantic-model/scripts/ossie.py validate logical-model/`, then `coverage logical-model/ transformation/models/marts/core transformation/models/marts/agg transformation/models/marts/finance transformation/models/marts/ops --exclude agg.agg_od_flow_matrix --exclude finance.mart_revenue_component_bridge --exclude core.dim_fare_regime`, then `suppliers logical-model/`, then `notes logical-model/ transformation/tests docs/adr`, then `generate-tests logical-model/ transformation/tests --check`; expect exit 0 from each.
- [ ] Load `validating-semantic-model` and record its report; expect no open finding.
- [ ] Run `python3 .agents/skills/semantic-model/scripts/ossie.py validate ontology/`, `refs ontology/ logical-model/` and `glossary ontology/ CONTEXT.md`; expect exit 0 from each.
- [ ] Load `validating-ontology` and record its report; expect a pass with the mapping unchanged, since the aggregate carries no concept identity.
- [ ] Run `cd transformation && dbt docs generate --target dev`, then `python3 .agents/skills/data-contract/scripts/odcs.py check --relations --catalog transformation/target/catalog.json` and `python3 .agents/skills/data-contract/scripts/odcs.py profile --relation agg.agg_borough_flow_monthly`; expect exit 0 from each.
- [ ] Commit and push the Ossie document, regenerated tests, activated contract, generated dbt keys and `_agg.yml`.

## Execution evidence

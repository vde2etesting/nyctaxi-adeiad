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
| `logical-model/nyc_taxi_analytics.ossie.yaml`: logical source `trips.LTS10_borough_month_flow`, no new dataset and no new metric (`D-13`) | logical-model | create | `R-08` | `docs/design/models/agg/agg_borough_flow_monthly.md` | `ossie.py validate`, `coverage logical-model/ transformation/models/marts/core transformation/models/marts/agg transformation/models/marts/finance transformation/models/marts/ops --exclude agg.agg_od_flow_matrix --exclude finance.mart_revenue_component_bridge --exclude core.dim_fare_regime`, `suppliers`, `notes`, `generate-tests --check` |
| `ontology/nyc_taxi_analytics.mapping.yaml` | ontology | verify | `R-08` | `docs/design/models/agg/agg_borough_flow_monthly.md` | `ossie.py validate ontology/`, `refs`, `glossary` |

**Change impact:** no existing model, contract or published relation is modified. Shared files gain entries only: `transformation/models/marts/agg/_agg.yml`, `test-map.json`, `transformation/tests/` (five new singular tests plus the regenerated semantic tests). The new relation has no downstream consumer in the repository.

## Tasks

### Task 1: Contract (proposed), model and tests

**Requirements:** `R-01`–`R-07` · **Design:** `docs/design/models/agg/agg_borough_flow_monthly.md` · **Skill:** `data-contract` (contract), `generating-dbt-model` (model) · **Depends on:** none

- [x] Author `contracts/agg/agg_borough_flow_monthly.odcs.yaml` through `data-contract`: `status: proposed`, version 1.0.0, grain statement `one row per pickup month, origin borough and destination borough`, properties `month_start_date` (date), `origin_borough` (string, required), `dest_borough` (string, required), `origin_is_unresolved_borough` (boolean), `dest_is_unresolved_borough` (boolean), `is_intra_borough` (boolean), `trip_count` (integer, required), `total_revenue` (number), `origin_trip_count` (integer, required), `origin_cross_borough_trip_count` (integer, required), `cross_borough_trip_share` (number, required), `primaryKey` on the three grain columns.
- [x] Author `transformation/models/marts/agg/agg_borough_flow_monthly.sql`: `fct_trip` joined to `dim_zone` as origin (`pickup_zone_key`) and as destination (`dropoff_zone_key`), `where in_report_window(f.pickup_datetime) and f.is_billable`, grouped by month and the two borough names; the two flags from `dim_zone.is_unresolved_zone`, `is_intra_borough` from the two borough names, and the origin-month window sums for `origin_trip_count`, `origin_cross_borough_trip_count` and `cross_borough_trip_share` (`safe_divide`); every column cast to its declared type. No `contract: {enforced: true}` in this task: `generate` writes it in Task 2.
- [x] Add the model entry to `transformation/models/marts/agg/_agg.yml` with a description stating grain, population (billable, in window, both zones resolved), the absence of a floor (ADR 0018) and the share's denominator, and a description on every column.
- [x] Add `transformation/models/marts/agg/_unit_tests.yml` with unit test `agg_borough_flow_monthly` over `fct_trip` and `dim_zone` fixtures (with `overrides: {vars: {report_start: '2024-01-01', report_end: '2024-04-01'}}`): a cross-borough pair, an intra-borough pair, an `Unknown` origin, a `N/A` destination and a pickup on the first and last day of a month, asserting each row's counts, flags and share.
- [x] Add `transformation/tests/assert_borough_flow_one_row_per_grain.sql`.
- [x] Add `transformation/tests/assert_borough_flow_publishes_every_pair.sql`: a full outer join between the table's (month, origin, destination) cells and the star's, reporting a missing pair, an extra pair or a row with `trip_count < 1`.
- [x] Add `transformation/tests/assert_borough_flow_share_holds.sql`: recompute the share from the table's own `origin_cross_borough_trip_count` and `origin_trip_count`, reporting a mismatch beyond 1e-9 and any origin-month whose rows disagree on the share.
- [x] Add `transformation/tests/assert_borough_flow_flags_unresolved_boroughs.sql`: report a row whose `origin_is_unresolved_borough` or `dest_is_unresolved_borough` disagrees with the borough name being `Unknown` or `N/A`.
- [x] Add `transformation/tests/assert_borough_flow_covers_every_trip.sql`: report a difference between the table's summed `trip_count` and the star's billable in-window trips with both zones resolved.
- [x] Add the five new singular tests to the `agg` `data` list in `test-map.json`.
- [x] Run `cd transformation && dbt deps`; expect exit 0.
- [x] Run `cd transformation && dbt build --select agg_borough_flow_monthly+ --exclude test_type:unit --target dev --warn-error-options '{"error":["NoNodesForSelectionCriteria"]}'`; expect PASS.
- [x] Run `cd transformation && dbt test --select agg_borough_flow_monthly,test_type:unit --target dev --warn-error-options '{"error":["NoNodesForSelectionCriteria"]}'`; expect PASS.
- [x] Run `python3 .agents/skills/data-contract/scripts/odcs.py check`; expect exit 0.
- [x] Run the `R-02` acceptance check: `sum(trip_count)` = 9,604,511 and `round(sum(total_revenue), 2)` = 263,480,834.99, recomputed from `fct_trip` joined twice to `dim_zone` in the sandbox.
- [x] Run the `R-05` acceptance check: recompute each origin-month's share from `fct_trip` independently and match every row at 1e-9.
- [x] Commit and push the contract, SQL, YAML, unit test, five singular tests and `test-map.json`.

### Task 2: Ossie logical source; contract activation; ontology gates

**Requirements:** `R-08` · **Design:** `docs/design/models/agg/agg_borough_flow_monthly.md` · **Skill:** `semantic-model`, `data-contract` (activation), `ontology`, `validating-semantic-model`, `validating-ontology` · **Depends on:** Task 1

- [ ] Add to `logical-model/nyc_taxi_analytics.ossie.yaml` through `semantic-model`: aggregate logical source `trips.LTS10_borough_month_flow` on the existing `trips` dataset — `source: agg.agg_borough_flow_monthly`, `primary_key` the three grain columns, `content_levels` built from the model's `GROUP BY` (date at its month level, pickup zone at its borough level keyed `origin_borough`, dropoff zone at its borough level keyed `dest_borough`), `content_filter` from its `WHERE`, and a `column_map` binding `trip_count` to `billable_trip_count` and `total_revenue` to `billable_revenue`, with the refusal of the share and its two counts recorded in that source's `note` per `D-13`. No new dataset and no new metric.
- [ ] Set `contracts/agg/agg_borough_flow_monthly.odcs.yaml` to `status: active`, run `python3 .agents/skills/data-contract/scripts/odcs.py generate`, then `check` and `diff origin/main`; expect exit 0 from each.
- [ ] Run `python3 .agents/skills/semantic-model/scripts/ossie.py generate-tests logical-model/ transformation/tests`; expect it rewrites the `assert_semantic_*.sql` files and reports `0 stale`.
- [ ] Run `cd transformation && dbt build --select agg_borough_flow_monthly+ --exclude test_type:unit --target dev --warn-error-options '{"error":["NoNodesForSelectionCriteria"]}'`; expect PASS with the enforced contract now in place.
- [ ] Run `cd transformation && dbt test --select agg_borough_flow_monthly,test_type:unit --target dev` and `dbt test --select assert_semantic_content_holds assert_semantic_level_keys_hold assert_semantic_levels_hold --target dev`; expect PASS on the unit test and on every `trips.LTS10_borough_month_flow` row, with only the pre-existing `LTS5_weather_borough_daily` level-key warning.
- [ ] Run `python3 .agents/skills/semantic-model/scripts/ossie.py validate logical-model/`, then `coverage logical-model/ transformation/models/marts/core transformation/models/marts/agg transformation/models/marts/finance transformation/models/marts/ops --exclude agg.agg_od_flow_matrix --exclude finance.mart_revenue_component_bridge --exclude core.dim_fare_regime`, then `suppliers logical-model/`, then `notes logical-model/ transformation/tests docs/adr`, then `generate-tests logical-model/ transformation/tests --check`; expect exit 0 from each.
- [ ] Load `validating-semantic-model` and record its report; expect no open finding.
- [ ] Run `python3 .agents/skills/semantic-model/scripts/ossie.py validate ontology/`, `refs ontology/ logical-model/` and `glossary ontology/ CONTEXT.md`; expect exit 0 from each.
- [ ] Load `validating-ontology` and record its report; expect a pass with the mapping unchanged, since the aggregate carries no concept identity.
- [ ] Run `cd transformation && dbt docs generate --target dev`, then `python3 .agents/skills/data-contract/scripts/odcs.py check --relations --catalog transformation/target/catalog.json` and `python3 .agents/skills/data-contract/scripts/odcs.py profile --relation agg.agg_borough_flow_monthly`; expect exit 0 from each.
- [ ] Commit and push the Ossie document, regenerated tests, activated contract, generated dbt keys and `_agg.yml`.

## Execution evidence

### Task 1 — contract (proposed), model and tests

**Profiling.** `core.fct_trip` and `core.dim_zone` were both profiled in the Verification's `## Discovery` on the `domain` target (borough totals, the eight borough values, month completeness, null zone keys and totals, borough-pair cells, share per origin-month), verdict `Ready`; no new probe was needed and nothing here is unprofiled.

**Artifacts.** `contracts/agg/agg_borough_flow_monthly.odcs.yaml` (sha256 `ab5032b2a2cf`, `status: proposed`, version 1.0.0), `transformation/models/marts/agg/agg_borough_flow_monthly.sql` (`5cf48ae4362d`), its `_agg.yml` entry, `transformation/models/marts/agg/_unit_tests.yml` (`9e2114309069`), `transformation/tests/assert_borough_flow_one_row_per_grain.sql` (`71c03a2eaff7`), `assert_borough_flow_publishes_every_pair.sql` (`e723f6244e07`), `assert_borough_flow_share_holds.sql` (`a6c76bd74d3f`), `assert_borough_flow_flags_unresolved_boroughs.sql` (`22a98f1f202f`), `assert_borough_flow_covers_every_trip.sql` (`79339ad551f4`), and the five entries added to `test-map.json`.

**Gate commands.**

| Command | Exit | Result |
| --- | --- | --- |
| `python3 .agents/skills/data-contract/scripts/odcs.py check` | 0 | Three pre-existing `boundary/excluded` info findings; the proposed contract is shape-checked with the orphan and no-document checks skipped, as the skill states. |
| `cd transformation && dbt deps` | 0 | `dbt_project_evaluator` 1.4.1 installed. |
| `cd transformation && dbt compile --select agg_borough_flow_monthly --target dev --warn-error-options '{"error":["NoNodesForSelectionCriteria"]}'` | 0 | Resolves `agg.agg_borough_flow_monthly`, table, 11 columns. |
| `cd transformation && dbt build --select agg_borough_flow_monthly+ --exclude test_type:unit --target dev --warn-error-options '{"error":["NoNodesForSelectionCriteria"]}'` | 0 | `PASS=6 WARN=0 ERROR=0 SKIP=0`, a table model and its five singular tests; 1.52s. |
| `python /data/default-plugins/vibedata-data-engineering/0.148.28/scripts/assert_dbt_destination.py` | 0 | `DESTINATION_OK: 1 built relation(s) landed in the sandbox ephm_singapore-l1-workshop_new-intent-7f7e6d1e`. |
| `python /data/default-plugins/vibedata-data-engineering/0.148.28/scripts/ephemeral_workspace_marker.py init` | 0 | `{"status": "created"}` — the marker is written. |
| `cd transformation && dbt test --select agg_borough_flow_monthly,test_type:unit --target dev --warn-error-options '{"error":["NoNodesForSelectionCriteria"]}'` | 0 | `PASS=1` — `borough_flow_counts_share_and_flags`. |
| `sqlfluff lint transformation/models/marts/agg/agg_borough_flow_monthly.sql transformation/tests/assert_borough_flow_*.sql` | 0 | Clean after one layout fix in the full outer join. |
| `python3 -m pytest tests/test_maps.py tests/test_adr_links.py -q` | 0 | 32 passed. |
| `python3 -m pytest tests/test_odcs_contracts.py -q` | 0 | 7 passed. |
| `cd transformation && dbt docs generate --static --target dev` | 0 | `target/static_index.html` copied onto `/data/ephm_dbt_docs/static_index.html`. |

**Defer:** none — this Domain publishes no production manifest and the dbt card forbids `--defer`.

**Acceptance checks (target `ephemeral`, `agg.agg_borough_flow_monthly`).**

- `R-01`, `R-03`, `R-06`, `R-07` — `select count(*) as cells, sum(trip_count) as trips, round(sum(total_revenue), 2) as revenue, count(distinct month_start_date) as months, min(trip_count) as min_trips, count(*) filter (where trip_count < 25) as cells_under_25, count(*) filter (where trip_count < 1) as zero_rows from agg.agg_borough_flow_monthly` returned `cells 180, trips 9604511, revenue 263480834.99, months 3, min_trips 1, cells_under_25 49, zero_rows 0` — the grain has one row per cell, no cell is missing or zero, 49 cells sit under the zone floor and are published anyway, and the three months are the only group.
- `R-02` — the same query: `9,604,511` billable trips and `263,480,834.99` revenue, equal to the star's billable in-window population at the cent.
- `R-04` — `select origin_borough, origin_is_unresolved_borough, sum(trip_count) as trips … group by 1, 2` returned eight boroughs with only `Unknown` (31,551 trips, `true`) and `N/A` (5,006 trips, `true`) flagged; the origin totals sum to 9,604,511.
- `R-05` — each origin-month's share recomputed from `core.fct_trip` joined twice to `core.dim_zone` and compared with the published rows: `published_rows 180, origin_months 24, share_mismatches 0, count_mismatches 0, cross_mismatches 0` at 1e-9.
- `R-07` — the unit test's fixture trips on `2024-01-31 23:59` and `2024-02-01 00:00` land in January and February, and the trips at `2024-04-01 00:00:00` and `2023-12-31 23:59` are excluded.

**Coverage gap:** none known. The contract is `proposed`, so `generate` wrote no dbt enforcement keys yet by design; Task 2 activates it.


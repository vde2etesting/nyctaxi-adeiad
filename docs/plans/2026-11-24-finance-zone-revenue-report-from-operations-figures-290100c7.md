# Plan: Finance zone revenue report from one shared daily-zone computation

**Goal:** Both daily zone reports read one shared daily-zone model built from `fct_trip`, so finance's report and operations' figure come from one computation, with every published value unchanged.

**Requirement:** `docs/requirement/2026-11-24-finance-zone-revenue-report-from-operations-figures-290100c7.md`

**Constraints:**
- `finance.mart_daily_zone_revenue` keeps its exact columns, names, types, schema (`finance`) and grain (one row per pickup zone and trip date); `agg.agg_trip_zone_daily` likewise in `agg`; schemas are the user's `defaults` answer.
- The shared model lives in `intermediate` and is materialised as a table (`transformation/dbt_project.yml`).
- The reporting window is the project vars `report_start` = `2024-01-01` inclusive, `report_end` = `2024-04-01` exclusive; it is applied in `int_trip_zone_daily` and nowhere else in this chain.
- The billable population is unchanged: `is_billable` (positive total amount) from `int_trip_quality_flags` / `fct_trip`, per ADR 0018; `fct_trip` still keeps every trip.
- No new relation in `core`, `agg`, `finance` or `ops`; the ODCS contracts, the Ossie documents and their bindings are unchanged.
- Money is compared at the cent (`round(x, 2)`) and counts exactly, per `.agents/skills/dbt-testing/SKILL.md`.
- Never `--full-refresh` a published model; every data write stays in the Intent sandbox.

## Scope and impact

| Artifact | Kind | Action | Requirements | Design record | Gate |
| --- | --- | --- | --- | --- | --- |
| `transformation/models/intermediate/int_trip_zone_daily.sql` | model | create | `R-01`, `R-05` | `docs/design/models/intermediate/int_trip_zone_daily.md` | `cd transformation && dbt build --select int_trip_zone_daily` |
| `transformation/models/intermediate/_intermediate.yml` | model | modify | `R-01`, `R-05` | `docs/design/models/intermediate/int_trip_zone_daily.md` | `cd transformation && dbt build --select int_trip_zone_daily` |
| `transformation/models/intermediate/_unit_tests.yml` | model | modify | `R-01`, `R-05` | `docs/design/models/intermediate/int_trip_zone_daily.md` | `cd transformation && dbt test --select path:models/intermediate,test_type:unit` |
| `transformation/tests/assert_trip_zone_daily_one_row_per_grain.sql` | model | create | `R-01` | `docs/design/models/intermediate/int_trip_zone_daily.md` | `cd transformation && dbt test --select assert_trip_zone_daily_one_row_per_grain` |
| `test-map.json` | model | modify | `R-01` | `code is contract` | `python3 -m pytest tests/test_maps.py -q` |
| `transformation/models/marts/agg/agg_trip_zone_daily.sql` | model | modify | `R-01`, `R-03`, `R-06` | `docs/design/models/agg/agg_trip_zone_daily.md` | `cd transformation && dbt build --select agg_trip_zone_daily` |
| `transformation/models/marts/finance/mart_daily_zone_revenue.sql` | model | modify | `R-01`, `R-02`, `R-05`, `R-06` | `docs/design/models/finance/mart_daily_zone_revenue.md` | `cd transformation && dbt build --select mart_daily_zone_revenue` |
| `transformation/models/marts/finance/_finance.yml` | model | modify | `R-02` | `docs/design/models/finance/mart_daily_zone_revenue.md` | `cd transformation && dbt build --select mart_daily_zone_revenue` |

**Change impact:** `finance.mart_daily_zone_revenue` and `agg.agg_trip_zone_daily` have no dbt model downstream; their only consumers in the repo are the generated singular tests `assert_semantic_content_holds` and `assert_semantic_levels_hold`, and outside it finance's morning report and the operations dashboard. Both keep their column sets and grain, so no consumer code, contract or Ossie binding changes. `int_trip_zone_daily` is new and internal.

## Tasks

### Task 1: `int_trip_zone_daily` — the one daily-zone computation

**Requirements:** `R-01`, `R-05` · **Design:** `docs/design/models/intermediate/int_trip_zone_daily.md` · **Skill:** `generating-dbt-model` · **Depends on:** none

- [x] Author `transformation/models/intermediate/int_trip_zone_daily.sql`: `fct_trip` filtered by `{{ in_report_window('f.pickup_datetime') }}`, grouped by `pickup_date_key`, `pickup_date` and `pickup_zone_key`, carrying `trip_count`, `total_miles`, `total_revenue`, `attributed_driver_count` over every trip beside `billable_trip_count`, `billable_fare_revenue`, `billable_tip_revenue`, `billable_surcharge_revenue`, `billable_toll_revenue` and `billable_total_revenue` over `is_billable` trips only.
- [x] Add its entry to `transformation/models/intermediate/_intermediate.yml`: description, every column with `data_type`, `not_null` on `pickup_date`, `pickup_zone_key`, `trip_count`, and `relationships` on `pickup_zone_key` to `dim_zone.zone_key`; update the stale `int_trip_quality_flags` description ("ADR 0003 puts the billable rule in gold") to name ADR 0018.
- [x] Add `transformation/tests/assert_trip_zone_daily_one_row_per_grain.sql`, returning rows when `(pickup_date, pickup_zone_key)` repeats.
- [x] Add one unit test to `transformation/models/intermediate/_unit_tests.yml`, `trip_zone_daily_splits_billable_and_all_trip_populations`: two zone-days, one trip with a negative total, expect the billable columns to exclude it and the all-trip columns to include it, with `overrides: {vars: {report_start: '2024-01-01', report_end: '2024-04-01'}}` because the model reads both vars.
- [x] Add `transformation/tests/assert_trip_zone_daily_one_row_per_grain.sql` to `test-map.json` under `modules.intermediate.data`; run `python3 -m pytest tests/test_maps.py -q`, expect 2 passed.
- [x] Run `cd transformation && dbt build --select int_trip_zone_daily`; expect the model, its data tests and its unit test to pass.
- [x] Run the `R-05` acceptance: on `target: "ephemeral"`, `select sum(billable_trip_count) as trips, round(sum(billable_total_revenue), 2) as revenue from intermediate.int_trip_zone_daily`; expect `9604511` and `263480834.99`.
- [x] Commit and push `transformation/models/intermediate/int_trip_zone_daily.sql`, `transformation/models/intermediate/_intermediate.yml`, `transformation/models/intermediate/_unit_tests.yml`, `transformation/tests/assert_trip_zone_daily_one_row_per_grain.sql` and `test-map.json`.

## Execution evidence (Task 1)

- Task 1: `cd transformation && dbt deps` — exit 0 — `Installed from version 1.4.1 / Up to date!`
- Task 1: `dbt compile --select int_trip_zone_daily --target dev --warn-error-options '{"error":["NoNodesForSelectionCriteria"]}'` — exit 0 — resolved `intermediate.int_trip_zone_daily`, 13 columns, materialized `table`; no defer (the dbt card publishes no production manifest).
- Task 1: `dbt build --select int_trip_zone_daily --target dev --warn-error-options '{"error":["NoNodesForSelectionCriteria"]}'` — exit 0 — `PASS=7 WARN=0 ERROR=0 SKIP=0 TOTAL=7` (1 table model, 5 data tests, 1 unit test) — `transformation/models/intermediate/int_trip_zone_daily.sql` — sha256:8dd74eb1766b22ffabb969c39f4ff561ecbf9c9168262206f1e8e7be9f26fbb3
- Task 1: `python /data/default-plugins/vibedata-data-engineering/0.148.28/scripts/assert_dbt_destination.py` — exit 0 — `DESTINATION_OK: 1 built relation(s) landed in the sandbox ephm_singapore-l1-workshop_new-intent-290100c7`
- Task 1: `python /data/default-plugins/vibedata-data-engineering/0.148.28/scripts/ephemeral_workspace_marker.py init` — exit 0 — `{"status": "created"}`
- Task 1: `lakehouse_query target=ephemeral: select sum(billable_trip_count) as trips, round(sum(billable_total_revenue), 2) as revenue, sum(trip_count) as all_trips, round(sum(total_revenue), 2) as all_revenue, count(*) as rows from intermediate.int_trip_zone_daily` — 1 row — billable `9604511` trips / `263480834.99`; all-trip `9722336` / `260487920.62`; `20771` rows — `R-05` met on the billable population.
- Task 1: `dbt docs generate --static --target dev` — exit 0 — catalog built; `static_index.html` published to `/data/ephm_dbt_docs`
- Task 1: `sqlfluff lint models/intermediate/int_trip_zone_daily.sql tests/assert_trip_zone_daily_one_row_per_grain.sql` — exit 0
- Task 1: `python3 -m pytest tests/test_maps.py tests/test_adr_links.py -q` — exit 0 — `32 passed`
- Task 1: profiling — every upstream relation recorded `Ready`: `core.fct_trip` (9,722,336 window rows, no null zone key or measure), `core.dim_zone` (272 rows, 272 distinct `zone_key`), both read on `target: "domain"` in the Verification's `## Discovery`; nothing unprofiled.
- Task 1: grain test `assert_trip_zone_daily_one_row_per_grain` PASS over 20,771 rows — `transformation/tests/assert_trip_zone_daily_one_row_per_grain.sql` — sha256:a1b00c01f4c5b57f0525b62c26dfe4a7983e178c330aea42a9d142072d51b6b7

### Task 2: `agg_trip_zone_daily` reads the shared computation

**Requirements:** `R-01`, `R-03`, `R-06` · **Design:** `docs/design/models/agg/agg_trip_zone_daily.md` · **Skill:** `generating-dbt-model` · **Depends on:** Task 1

- [x] Rewrite `transformation/models/marts/agg/agg_trip_zone_daily.sql` to select `pickup_date_key`, `pickup_date`, `z.zone_natural_key as pickup_location_id`, `z.zone_name`, `z.borough_name` and the four all-trip measures from `int_trip_zone_daily`, joined to `dim_zone`, with the five window functions unchanged; no `ref('fct_trip')` remains.
- [x] Rank `revenue_rank_that_day` on `round(d.total_revenue, 2)` instead of the raw double, per the user's answer at task 2: rows equal at the cent tie rather than being split by float summation order.
- [x] Run `cd transformation && dbt build --select agg_trip_zone_daily`; expect the model, its enforced contract and its data tests to pass.
- [x] Run the `R-03` acceptance on `target: "ephemeral"`: `select sum(trip_count) as trips, round(sum(total_revenue), 2) as revenue from agg.agg_trip_zone_daily where pickup_date between date '2024-01-01' and date '2024-03-31'`; expect `9722336` and `260487920.62`, and the same query with `and zone_name = 'JFK Airport'` expects `429806` and `33140983.67`.
- [x] Run the row-for-row comparison: the count of rows in `agg.agg_trip_zone_daily` on `target: "ephemeral"` whose full column set (money rounded to the cent, miles and averages to 1e-6) has no match in `agg.agg_trip_zone_daily` on `target: "domain"`, plus the reverse, expect `0` unmatched keys and `0` rows differing in any measure; `revenue_rank_that_day` is compared separately, and the user accepted the `2` cells the cent-based ranking changes.
- [x] Run the `R-06` check: `cd transformation && dbt compile --select agg_trip_zone_daily` then `grep -Ec 'from [^ ]*fct_trip' target/compiled/nyc_taxi_analytics/models/marts/agg/agg_trip_zone_daily.sql`; expect `0`, and `grep -c int_trip_zone_daily` on the same file expects `1` or more.
- [x] Commit and push `transformation/models/marts/agg/agg_trip_zone_daily.sql`.

## Execution evidence (Task 2)

- Task 2: `dbt compile --select agg_trip_zone_daily --target dev --warn-error-options '{"error":["NoNodesForSelectionCriteria"]}'` — exit 0 — resolved `agg.agg_trip_zone_daily` from `intermediate.int_trip_zone_daily`; no defer.
- Task 2: `dbt build --select agg_trip_zone_daily --target dev --warn-error-options '{"error":["NoNodesForSelectionCriteria"]}'` — exit 0 (`Completed successfully` first run; second run with the cent-based rank `PASS=2 WARN=1 ERROR=0`) — model and enforced contract OK — `transformation/models/marts/agg/agg_trip_zone_daily.sql` — sha256:921d325f52166831429fa55e19dbc0330069b07ad822acf635e67c7847f50981
- Task 2: `python /data/default-plugins/vibedata-data-engineering/0.148.28/scripts/assert_dbt_destination.py` — exit 0 — `DESTINATION_OK: 1 built relation(s) landed in the sandbox ephm_singapore-l1-workshop_new-intent-290100c7`
- Task 2: the one warning is `assert_semantic_levels_hold`, finding `trips.LTS5_weather_borough_daily: trips_to_pickup_zone borough key is no member` / `unresolved` — pre-existing at the baseline, not this change: `target: "domain"` returns `agg.agg_weather_demand_daily` 91 rows with `borough_name = 'unresolved'` against `core.dim_zone` 0 such members. Recorded as a finding; not investigated here.
- Task 2: `lakehouse_query target=ephemeral: select sum(trip_count), round(sum(total_revenue),2) from agg.agg_trip_zone_daily where pickup_date between '2024-01-01' and '2024-03-31'` — `9722336` trips / `260487920.62`; with `and zone_name = 'JFK Airport'` — `429806` / `33140983.67` — `R-03` values reproduced exactly.
- Task 2: row-for-row comparison, `export_query_data` both targets then full outer join on `(pickup_date, pickup_location_id)` with money at the cent and miles/averages at 1e-6 — `20771` joined rows, `keys_unmatched=0`, `rows_differing_except_rank=0`, `rank_deltas=2`.
- Task 2: the two rank cells that change are Financial District North on 2024-01-13 (11,693.58; production 47, now 46, tied with Battery Park City) and Williamsbridge/Olinville on 2024-03-05 (267.92; production 167, now 166, tied with Middle Village). Battery Park City and Middle Village keep their ranks and are now tied with their neighbour: production split each pair by float summation noise. Source: the user's answer (`cent_rank`) at the task 2 question; corrected at verification, where the first wording named Middle Village instead of Financial District North.
- Task 2: `grep -Ec 'from [^ ]*fct_trip' target/compiled/.../agg_trip_zone_daily.sql` — exit 1, count `0`; `grep -c int_trip_zone_daily` — `1` — `R-06` and the `R-01` graph evidence for this report.
- Task 2: `dbt docs generate --static --target dev` — exit 0 — `static_index.html` published to `/data/ephm_dbt_docs`

### Task 3: `mart_daily_zone_revenue` reads the shared computation

**Requirements:** `R-01`, `R-02`, `R-05`, `R-06` · **Design:** `docs/design/models/finance/mart_daily_zone_revenue.md` · **Skill:** `generating-dbt-model` · **Depends on:** Tasks 1, 2

- [x] Rewrite `transformation/models/marts/finance/mart_daily_zone_revenue.sql` to select `pickup_date as trip_date`, the four `dim_zone` labels and the six billable measures from `int_trip_zone_daily`, joined to `dim_zone` on `pickup_zone_key = zone_key`, with no window filter and no `is_billable` predicate of its own; replace the header comment that puts the billable rule in gold with one naming ADR 0018.
- [x] Update the `mart_daily_zone_revenue` description in `transformation/models/marts/finance/_finance.yml` so it no longer says the rule is applied "here and nowhere upstream"; the `trip_count` column description says billable trips, not "Trips, billable or not." Nothing else in the file changes.
- [x] Run `cd transformation && dbt build --select mart_daily_zone_revenue`; expect the model, its enforced contract and its data tests to pass.
- [x] Run the `R-02` acceptance on `target: "ephemeral"`: `select sum(trip_count) as trips, round(sum(total_revenue), 2) as revenue, round(sum(fare_revenue), 2) as fare, round(sum(tip_revenue), 2) as tip, round(sum(surcharge_revenue), 2) as surcharge, round(sum(toll_revenue), 2) as toll from finance.mart_daily_zone_revenue where trip_date between date '2024-01-01' and date '2024-03-31'`; expect `9604511`, `263480834.99`, `180344530.29`, `31635312.62`, `48402767.94`, `5125834.39`, and the same query with `and zone_name = 'JFK Airport'` expects `416460` and `33881378.28`.
- [x] Run the row-for-row comparison against `finance.mart_daily_zone_revenue` on `target: "domain"` (money at the cent, every non-money column exactly), both directions; expect `0` unmatched rows each way.
- [x] Run the `R-06` check: `cd transformation && dbt compile --select mart_daily_zone_revenue` then `grep -Ec 'from [^ ]*fct_trip'` on both compiled reports; expect `0` each, and `grep -c int_trip_zone_daily` on both compiled reports expects at least `1` each — the `R-01` graph evidence.
- [x] Run `python3 .agents/skills/data-contract/scripts/odcs.py check`; expect the two contracts unchanged and passing.
- [x] Run `cd transformation && dbt test --select path:models/agg path:models/finance --exclude test_type:unit`; expect the generated semantic tests to pass unchanged.
- [x] Commit and push `transformation/models/marts/finance/mart_daily_zone_revenue.sql` and `transformation/models/marts/finance/_finance.yml`.

## Execution evidence (Task 3)

- Task 3: `dbt build --select mart_daily_zone_revenue --target dev --warn-error-options '{"error":["NoNodesForSelectionCriteria"]}'` — exit 0 — `PASS=5 WARN=1 ERROR=0 TOTAL=6` (1 table model, 4 data tests, 1 generated singular test) — `transformation/models/marts/finance/mart_daily_zone_revenue.sql` — sha256:3f869deff05b424844f997ab4ae6042f238deebcfe74f36636cba28805748fd9 — `_finance.yml` — sha256:d827d8237e828dd15f5ad42537bc5b1bdfeb7d2c299fee86ec37a33c35f8942f
- Task 3: `python /data/default-plugins/vibedata-data-engineering/0.148.28/scripts/assert_dbt_destination.py` — exit 0 — `DESTINATION_OK: 1 built relation(s) landed in the sandbox ephm_singapore-l1-workshop_new-intent-290100c7`
- Task 3: `lakehouse_query target=ephemeral: select sum(trip_count), round(sum(total_revenue),2), round(sum(fare_revenue),2), round(sum(tip_revenue),2), round(sum(surcharge_revenue),2), round(sum(toll_revenue),2) from finance.mart_daily_zone_revenue where trip_date between '2024-01-01' and '2024-03-31'` — `9604511` / `263480834.99` / fare `180344530.29` / tip `31635312.62` / surcharge `48402767.94` / toll `5125834.39`; with `and zone_name = 'JFK Airport'` — `416460` / `33881378.28` — every `R-02` value reproduced.
- Task 3: row-for-row comparison against `finance.mart_daily_zone_revenue` on `target: "domain"`, both exports joined on `(trip_date, pickup_location_id)` with `borough`, `zone_name`, `reporting_region` and `trip_count` exact and the five money columns at the cent — `20770` rows each side, `keys_only_sandbox=0`, `keys_only_domain=0`, `rows_differing=0`.
- Task 3: `dbt compile --select mart_daily_zone_revenue --target dev` — exit 0 — then `grep -Ec 'from [^ ]*fct_trip'` on both compiled reports: `0` and `0`; `grep -c int_trip_zone_daily`: `2` (finance) and `1` (agg) — `R-06`, and the `R-01` graph evidence that both reports read the one computation.
- Task 3: `python3 .agents/skills/data-contract/scripts/odcs.py check` — exit 0, `33` findings, `0` errors — no contract file changed. The first run reported `generated/stale` on `trip_count.description`; `odcs.py generate` wrote nothing (`[]`) and the file was byte-identical between the two runs, after which `check` is green. Recorded as observed rather than explained.
- Task 3: `dbt test --select path:models/marts/agg path:models/marts/finance --exclude test_type:unit --target dev` — exit 0 — `PASS=12 WARN=1 ERROR=0 TOTAL=13`; the one warning is the pre-existing `assert_semantic_levels_hold` finding recorded under Task 2. (The first attempt used `path:models/agg`, which the plan named and dbt rejects: no enabled node matches. Corrected to `path:models/marts/agg` in the task bullet.)
- Task 3: `dbt docs generate --static --target dev` — exit 0 — `target/catalog.json` rebuilt at 05:23 UTC carrying `mart_daily_zone_revenue` as `BASE TABLE` with the same `11` columns; the static site file was not republished this run.
- Task 3: `sqlfluff lint models/marts/finance/mart_daily_zone_revenue.sql` — exit 0 — `All Finished`.

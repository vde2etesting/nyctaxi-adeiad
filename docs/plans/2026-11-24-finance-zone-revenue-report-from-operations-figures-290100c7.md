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

- [ ] Author `transformation/models/intermediate/int_trip_zone_daily.sql`: `fct_trip` filtered by `{{ in_report_window('f.pickup_datetime') }}`, grouped by `pickup_date_key`, `pickup_date` and `pickup_zone_key`, carrying `trip_count`, `total_miles`, `total_revenue`, `attributed_driver_count` over every trip beside `billable_trip_count`, `billable_fare_revenue`, `billable_tip_revenue`, `billable_surcharge_revenue`, `billable_toll_revenue` and `billable_total_revenue` over `is_billable` trips only.
- [ ] Add its entry to `transformation/models/intermediate/_intermediate.yml`: description, every column with `data_type`, `not_null` on `pickup_date`, `pickup_zone_key`, `trip_count`, and `relationships` on `pickup_zone_key` to `dim_zone.zone_key`; update the stale `int_trip_quality_flags` description ("ADR 0003 puts the billable rule in gold") to name ADR 0018.
- [ ] Add `transformation/tests/assert_trip_zone_daily_one_row_per_grain.sql`, returning rows when `(pickup_date, pickup_zone_key)` repeats.
- [ ] Add one unit test to `transformation/models/intermediate/_unit_tests.yml`, `trip_zone_daily_splits_billable_and_all_trip_populations`: two zone-days, one trip with a negative total, expect the billable columns to exclude it and the all-trip columns to include it, with `overrides: {vars: {report_start: '2024-01-01', report_end: '2024-04-01'}}` because the model reads both vars.
- [ ] Add `transformation/tests/assert_trip_zone_daily_one_row_per_grain.sql` to `test-map.json` under `modules.intermediate.data`; run `python3 -m pytest tests/test_maps.py -q`, expect 2 passed.
- [ ] Run `cd transformation && dbt build --select int_trip_zone_daily`; expect the model, its data tests and its unit test to pass.
- [ ] Run the `R-05` acceptance: on `target: "ephemeral"`, `select sum(billable_trip_count) as trips, round(sum(billable_total_revenue), 2) as revenue from intermediate.int_trip_zone_daily`; expect `9604511` and `263480834.99`.
- [ ] Commit and push `transformation/models/intermediate/int_trip_zone_daily.sql`, `transformation/models/intermediate/_intermediate.yml`, `transformation/models/intermediate/_unit_tests.yml`, `transformation/tests/assert_trip_zone_daily_one_row_per_grain.sql` and `test-map.json`.

### Task 2: `agg_trip_zone_daily` reads the shared computation

**Requirements:** `R-01`, `R-03`, `R-06` · **Design:** `docs/design/models/agg/agg_trip_zone_daily.md` · **Skill:** `generating-dbt-model` · **Depends on:** Task 1

- [ ] Rewrite `transformation/models/marts/agg/agg_trip_zone_daily.sql` to select `pickup_date_key`, `pickup_date`, `z.zone_natural_key as pickup_location_id`, `z.zone_name`, `z.borough_name` and the four all-trip measures from `int_trip_zone_daily`, joined to `dim_zone`, with the five window functions unchanged; no `ref('fct_trip')` remains.
- [ ] Run `cd transformation && dbt build --select agg_trip_zone_daily`; expect the model, its enforced contract and its data tests to pass.
- [ ] Run the `R-03` acceptance on `target: "ephemeral"`: `select sum(trip_count) as trips, round(sum(total_revenue), 2) as revenue from agg.agg_trip_zone_daily where pickup_date between date '2024-01-01' and date '2024-03-31'`; expect `9722336` and `260487920.62`, and the same query with `and zone_name = 'JFK Airport'` expects `429806` and `33140983.67`.
- [ ] Run the row-for-row comparison: the count of rows in `agg.agg_trip_zone_daily` on `target: "ephemeral"` whose full column set (money rounded to the cent) has no match in `agg.agg_trip_zone_daily` on `target: "domain"`, plus the reverse, both expect `0`.
- [ ] Run the `R-06` check: `cd transformation && dbt compile --select agg_trip_zone_daily` then `grep -c fct_trip target/compiled/nyc_taxi_analytics/models/marts/agg/agg_trip_zone_daily.sql`; expect `0`.
- [ ] Commit and push `transformation/models/marts/agg/agg_trip_zone_daily.sql`.

### Task 3: `mart_daily_zone_revenue` reads the shared computation

**Requirements:** `R-01`, `R-02`, `R-05`, `R-06` · **Design:** `docs/design/models/finance/mart_daily_zone_revenue.md` · **Skill:** `generating-dbt-model` · **Depends on:** Tasks 1, 2

- [ ] Rewrite `transformation/models/marts/finance/mart_daily_zone_revenue.sql` to select `pickup_date as trip_date`, the four `dim_zone` labels and the six billable measures from `int_trip_zone_daily`, joined to `dim_zone` on `pickup_zone_key = zone_key`, with no window filter and no `is_billable` predicate of its own; replace the header comment that puts the billable rule in gold with one naming ADR 0018.
- [ ] Update the `mart_daily_zone_revenue` description in `transformation/models/marts/finance/_finance.yml` so it no longer says the rule is applied "here and nowhere upstream"; the `trip_count` column description says billable trips, not "Trips, billable or not." Nothing else in the file changes.
- [ ] Run `cd transformation && dbt build --select mart_daily_zone_revenue`; expect the model, its enforced contract and its data tests to pass.
- [ ] Run the `R-02` acceptance on `target: "ephemeral"`: `select sum(trip_count) as trips, round(sum(total_revenue), 2) as revenue, round(sum(fare_revenue), 2) as fare, round(sum(tip_revenue), 2) as tip, round(sum(surcharge_revenue), 2) as surcharge, round(sum(toll_revenue), 2) as toll from finance.mart_daily_zone_revenue where trip_date between date '2024-01-01' and date '2024-03-31'`; expect `9604511`, `263480834.99`, `180344530.29`, `31635312.62`, `48402767.94`, `5125834.39`, and the same query with `and zone_name = 'JFK Airport'` expects `416460` and `33881378.28`.
- [ ] Run the row-for-row comparison against `finance.mart_daily_zone_revenue` on `target: "domain"` (money at the cent, every non-money column exactly), both directions; expect `0` unmatched rows each way.
- [ ] Run the `R-06` check: `cd transformation && dbt compile --select mart_daily_zone_revenue` then `grep -c fct_trip` on both compiled reports; expect `0` each, and `grep -c int_trip_zone_daily` on both compiled reports expects at least `1` each — the `R-01` graph evidence.
- [ ] Run `python3 .agents/skills/data-contract/scripts/odcs.py check`; expect the two contracts unchanged and passing.
- [ ] Run `cd transformation && dbt test --select path:models/agg path:models/finance --exclude test_type:unit`; expect the generated semantic tests to pass unchanged.
- [ ] Commit and push `transformation/models/marts/finance/mart_daily_zone_revenue.sql` and `transformation/models/marts/finance/_finance.yml`.

## Execution evidence

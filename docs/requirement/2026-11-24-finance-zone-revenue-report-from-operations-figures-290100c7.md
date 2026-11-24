---
kinds: [transformation]
---

# Requirement: Finance zone revenue report from operations figures

## Ask

Ravi Menon, who owns the finance reports, asked us for this: finance reads a daily zone revenue report every morning, operations keeps its own daily figures by zone, and the Domain pays for two builds that should give the same answers. The finance report should be built from the operations figures so that there is one source, and no number in the report may change.

Acceptance is finance's usual Q1 2024 check, as corrected by the user: 9,604,511 trips and 263,480,834.99 revenue in total, and 416,460 trips and 33,881,378.28 revenue for JFK Airport.

Read against this repository, the request has no build that satisfies it as worded. `ops_raw.trip_assignment` is the operator's own trip feed: 463,848 assigned trips in Q1 2024, 457,991 of them billable, $12,627,435.27 of total amount — 4.8% of the report's 9,604,511 — and it carries `total_amount` only, with no fare, tip, surcharge or toll. `agg.agg_trip_zone_daily` is the Domain's only daily-by-zone build: 9,722,336 trips and $260,487,920.62 in Q1 2024, because it counts every trip rather than the billable ones, and it too carries no component measures. Both consumers of daily zone figures are built separately from `fct_trip`.

The user's answer to that finding: one shared daily-zone computation from the trip fact, read by both the finance report and the operations daily-zone figure, with the report's grain, billable rule and five measures unchanged. That is what this Requirement fixes.

## Requirements

- [ ] `R-01` Daily zone figures are computed once. A single shared model produces the daily per-zone figures, and both `finance.mart_daily_zone_revenue` and `agg.agg_trip_zone_daily` read it rather than aggregating `fct_trip` themselves — accept when the compiled graph shows both models taking their trip-level input from that one model and neither selecting from `fct_trip` — source: user answer (shared computation).
- [ ] `R-02` The finance report keeps its published promise. Same columns, names and types as `contracts/finance/mart_daily_zone_revenue.odcs.yaml` declares, same grain (one row per pickup zone and trip date), and every value unchanged — accept when the built relation, over 2024-01-01 to 2024-03-31 inclusive, returns 9,604,511 trips and 263,480,834.99 total revenue; 416,460 trips and 33,881,378.28 total revenue for JFK Airport; component totals of 180,344,530.29 fare, 31,635,312.62 tip, 48,402,767.94 surcharge and 5,125,834.39 toll; and a row-for-row, value-for-value comparison against the deployed `finance.mart_daily_zone_revenue` at the change baseline shows no difference — source: request, user correction of the JFK figure.
- [ ] `R-03` The operations daily-zone figure keeps its published promise and its values. Same columns, names and types as `contracts/agg/agg_trip_zone_daily.odcs.yaml` declares, same grain (one row per pickup zone and trip date), every value unchanged — accept when the built relation returns 9,722,336 trips and 260,487,920.62 total revenue over Q1 2024, 429,806 trips and 33,140,983.67 for JFK Airport, and is row-for-row identical to the deployed `agg.agg_trip_zone_daily` at the change baseline — source: request (no number may change), user answer.
- [ ] `R-04` Nothing new is published and nothing outside the two reports moves. No new relation appears in `core`, `agg`, `finance` or `ops`; both relations keep their schema and name; their enforced dbt contracts compile; the ODCS contracts are unchanged; the semantic layer's Ossie documents and bindings are unchanged — accept when `dbt ls` shows no new boundary relation, `odcs.py check` passes, the semantic bindings check is unchanged, and both models build under their enforced contracts — source: request (one source, no number changes), repository (`artifact_paths.contracts`, `logical-model/`).
- [ ] `R-05` The billable population is still ADR 0003's. Finance's report counts exactly the trips with a positive total amount inside the reporting window, and `fct_trip` still exposes every trip, billable or not — accept when the report's trip counts equal a direct `count(*) filter (where is_billable)` over `fct_trip` inside the window, and `core.fct_trip`'s row count is unchanged — source: ADR 0003, request (no number changes).
- [ ] `R-06` The daily-zone reports carry no duplicate trip-level aggregation. Neither report re-aggregates `fct_trip` — accept when the compiled SQL of `mart_daily_zone_revenue` and `agg_trip_zone_daily` contains no `from` of `fct_trip`, directly or through another aggregate — source: user answer.

## Business decisions

| Decision | Value | Source |
| --- | --- | --- |
| Grain of `mart_daily_zone_revenue` | One row per pickup zone and trip date | existing model (`transformation/models/marts/finance/mart_daily_zone_revenue.sql`), request |
| Grain of `agg_trip_zone_daily` | One row per pickup zone and trip date | existing model (`transformation/models/marts/agg/agg_trip_zone_daily.sql`), request |
| Grain of the shared model | One row per pickup zone and trip date, or a finer grain from which both reports are exact | design carries it; both published grains are fixed above |
| Period boundary | `report_start` 2024-01-01 inclusive to `report_end` 2024-04-01 exclusive | `transformation/dbt_project.yml`, ADR 0003 |
| Edge periods | not applicable: the report's period is the day, and the data window's first and last days are whole days (trips span 2024-01-01 to 2024-03-31), so no period is cut short | repository (`core.fct_trip` window bounds) |
| Population of the finance report | "A trip is **billable** when its total amount is positive… Gold marts that report revenue or flows apply it, inside the reporting window: `mart_daily_zone_revenue`…" | ADR 0003 (quoted), request |
| Population of `agg_trip_zone_daily` | Every trip in the window, billable or not, with revenue summed over the same population | existing model, request |
| Metric definitions | Preserved exactly: `trip_count` = count of billable trips; `fare_revenue` = sum of `fare_amount`; `tip_revenue` = sum of `tip_amount`; `surcharge_revenue` = sum of `total_surcharges`; `toll_revenue` = sum of `tolls_amount`; `total_revenue` = sum of `total_amount`; `agg_trip_zone_daily.total_miles` = sum of `trip_distance` and `attributed_driver_count` = distinct `driver_key`, over all trips | existing models, request |
| Periods with no qualifying rows | Omitted, not emitted as zero, as today | existing models, request |
| NULLs in the aggregates | None present: all five revenue measures and `trip_distance` are non-null on every billable trip in the window, so sum-ignores-null and sum-over-nullable coincide | repository (`core.fct_trip`, Q1 2024) |
| Coverage | No new count column: the existing `trip_count` stands beside the measures and the published shapes must not change | request |
| Reuse | Build on the two published models and move their shared aggregation into one model, proven equivalent at the changed values; no published column is added, removed or retyped | user answer (shared computation), transformation playbook (Reuse) |
| Unmatched and null keys | Keep today's inner join from the trip fact to `dim_zone`; no report row is added or dropped | existing models, request |
| Where the billable rule is applied | The population is fixed here; whether the shared model filters or carries both populations is a design decision carried to the design stop, because the mart's design record `D-01` says the rule is applied "in gold, and nowhere upstream" | ADR 0003, design record `mart_daily_zone_revenue` `D-01` |

## Out of scope

- `ops_raw` and the ingestion pipelines: no operation-source table gains columns or rows, and the simulated operator is not extended to carry trips it does not attribute.
- The other finance marts (`mart_monthly_service_summary`, `mart_revenue_component_bridge`) and every `core`, `ops` and `intermediate` relation not named above.
- The published shape of either report: no column added, removed, renamed or retyped; no schema or model rename.
- The semantic layer and the ontology: `logical-model/` and `ontology/` are not edited, because no boundary shape changes.
- Orchestration and schedules.

## Open questions

None. The Q1 2024 JFK revenue baseline was corrected by the user to 33,881,378.28.

## Approvals
- 2026-11-24T04:52:15Z — requirement approved — "approve_design" — 7e3d3cf

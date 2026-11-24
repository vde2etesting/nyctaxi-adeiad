---
artifacts: [int_trip_zone_daily]
---

# int_trip_zone_daily

One row per pickup zone and trip date, carrying the billable and the all-trip populations of the same trips, so the finance revenue report and the operations daily-zone figure read one computation instead of each aggregating the trip fact.

## Grain

One row per `pickup_date` and `pickup_zone_key`. Chosen over a `(pickup_date, pickup_zone_key, is_billable)` grain because `attributed_driver_count` is a distinct count that is not additive across the verdict, so `agg_trip_zone_daily` could not recover its published value by summing the per-verdict rows.

## Schema

- `transformation/models/intermediate`: `intermediate` (default). Source: user answer at the schema question, R-01.

## Decisions

- `D-01` Aggregate `fct_trip` once per pickup zone and trip date inside the reporting window, carrying both populations as conditional aggregates: `trip_count`, `total_miles`, `total_revenue` and `attributed_driver_count` over every trip, and `billable_trip_count` with the five billable revenue measures ([ADR 0018](../../../adr/0018-billable-verdict-applied-where-the-daily-zone-figures-are-built.md)). Source: R-01, R-05, R-06, user answer.
- `D-02` Keep `pickup_zone_key` and join no dimension here: each report already joins `dim_zone` for the labels it publishes, and `dim_zone.zone_key` is unique, so the join neither adds nor drops rows (Verification `## Discovery`). Source: existing models, R-02, R-03.
- `D-03` Materialise as a table, the `intermediate` folder's setting, not as a view: two reports read it and the trip fact is scanned once. Source: `transformation/dbt_project.yml`, R-06.
- `D-04` `attributed_driver_count` stays `count(distinct driver_key)` over every trip in the reporting window, exactly as `agg_trip_zone_daily` computes it, because that report publishes it. Source: R-03.
- `D-05` Keep `pickup_date_key` beside `pickup_date` so `agg_trip_zone_daily` publishes its existing column without re-deriving it. Source: R-03.

## Rejected

- Grouping by the billable verdict — the distinct driver count is not additive across it, so the demand report would lose its published value.
- Carrying `dim_zone` labels here — the two reports publish different subsets of them and each already joins the dimension, so the labels would either duplicate or narrow one report's choice.

## Consumers

- `mart_daily_zone_revenue`: the billable population.
- `agg_trip_zone_daily`: the all-trip population.

## History

- 2026-11-24 — finance-zone-revenue-report-from-operations-figures — design record written — D-01 to D-05 — terms: none new

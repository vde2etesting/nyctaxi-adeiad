---
artifacts: [agg_trip_zone_daily]
---

# agg_trip_zone_daily

Daily zone demand with period-over-period context. Every trip in the reporting window, billable or not, with the day-over-day context a raw count cannot answer.

## Grain

One row per pickup zone and trip date.

## Schema

- `transformation/models/agg`: `agg` (default). Source: user answer at the schema question, R-03.

## Decisions

- `D-01` Read the daily figures from `int_trip_zone_daily` and join `dim_zone` for the labels, instead of aggregating `fct_trip` here. The published columns, grain and every value stay as they are ([ADR 0018](../../../adr/0018-billable-verdict-applied-where-the-daily-zone-figures-are-built.md)). Source: R-01, R-03, R-06, user answer.
- `D-02` `trip_count`, `total_revenue`, `total_miles` and `attributed_driver_count` are the all-trip population: every trip in the reporting window, billable or not. The report keeps publishing both populations' demand rather than the billable one alone. Source: existing model, R-03.
- `D-03` The window functions stay in this model, unchanged: `prev_day_trip_count`, `same_day_last_week_trip_count`, `trip_count_7d_avg`, `revenue_28d_rolling` and `revenue_rank_that_day` are this report's own context and are not shared. Source: existing model, R-03.
- `D-05` `revenue_rank_that_day` ranks on `round(total_revenue, 2)`, so two zone-days equal at the cent tie instead of being ordered by float summation noise. The column was previously ranked on the raw double and split such ties arbitrarily, including ties production stores with distinct ranks; two cells change from the deployed table, and the ranking stops drifting between rebuilds. Money columns are unaffected ([ADR 0018](../../../adr/0018-billable-verdict-applied-where-the-daily-zone-figures-are-built.md)). Source: user answer (rank on the cent), R-03, `.agents/skills/dbt-testing/SKILL.md` comparison precision.
- `D-04` Keep the inner join to `dim_zone`: the dimension's key is unique and the trip fact has no null pickup zone key, so the join neither drops nor duplicates a row (Verification `## Discovery`). Source: existing model, R-03.

## Logical Model

```yaml
documents:
  - logical-model/nyc_taxi_analytics.ossie.yaml
datasets: []
metrics: []
logical_sources: []
```

`LTS2_zone_day_agg` binds `pickup_date` and `trip_count` with a content filter this change does not touch; no field, metric or binding changes.

## Rejected

- Reading the finance report's billable rows and deriving the all-trip figures from a second build — that is the duplicate computation this intent removes.
- Moving the window functions into the shared model — they are this report's own context and a second consumer would have to filter them out.

## Consumers

- `assert_semantic_levels_hold` and `assert_semantic_content_holds` (singular dbt tests).
- Ossie document `logical-model/nyc_taxi_analytics.ossie.yaml`, logical source `LTS2_zone_day_agg`.

## History

- 2026-11-24 — finance-zone-revenue-report-from-operations-figures — design record written; aggregation moved to `int_trip_zone_daily` — D-01 to D-04 — terms: none new

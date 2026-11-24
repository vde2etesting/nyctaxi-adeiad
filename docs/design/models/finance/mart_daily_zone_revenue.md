---
artifacts: [mart_daily_zone_revenue]
---

# mart_daily_zone_revenue

Daily revenue by pickup zone.

## Grain

One row per pickup zone and trip date.

## Schema

- `transformation/models/finance`: `finance` (default). Source: user answer at the schema question, R-02.

## Decisions

- `D-01` Apply the billable rule and the reporting window here, in gold, and nowhere upstream, so quality work can still see the rows this excludes ([ADR 0003](../../../adr/0003-billable-trip-definition-and-where-it-applies.md)). Source: docs/requirement/2026-08-29-the-trip-fact.md R-03, [ADR 0003](../../../adr/0003-billable-trip-definition-and-where-it-applies.md).
- `D-02` Take the billable population from `int_trip_zone_daily` instead of filtering `fct_trip` here; this supersedes `D-01`'s placement, not its rule. The report publishes the billable columns of a build that carries every trip beside them, so the excluded rows stay visible to quality work in the same relation ([ADR 0018](../../../adr/0018-billable-verdict-applied-where-the-daily-zone-figures-are-built.md)). Source: docs/requirement/2026-11-24-finance-zone-revenue-report-from-operations-figures-290100c7.md R-02, R-05, R-06, user answer.
- `D-03` Join `dim_zone` here for `pickup_location_id`, `borough`, `zone_name` and `reporting_region`, as before: the dimension's key is unique and the shared model carries one row per zone and day, so the join adds no row (Verification `## Discovery`). Source: existing model, R-02.

## Logical Model

```yaml
documents:
  - logical-model/nyc_taxi_analytics.ossie.yaml
datasets: []
metrics: []
logical_sources: []
```

`LTS7_daily_zone_revenue` binds `trip_date`, `trip_count` and `total_revenue` with a content filter this change does not touch; no field, metric or binding changes.

## Rejected

- Applying the rule in silver by dropping the non-billable rows: the excluded rows would be invisible to quality work. The shared model carries both populations instead.
- Filtering `fct_trip` here while the operations figure filters it separately: the two scans of the trip fact are what this intent removes.

## Consumers

None in this repo beyond its own tests: `assert_semantic_content_holds` and `assert_semantic_levels_hold` read it through the Ossie binding `LTS7_daily_zone_revenue`. Outside the repository: finance's morning daily zone revenue report.

## History

- 2026-10-14 — trip-fact — design record written; audience wording removed from the model description — D-01
- 2026-11-24 — finance-zone-revenue-report-from-operations-figures — billable population read from `int_trip_zone_daily`; schema and logical model recorded — D-02, D-03 — terms: none new

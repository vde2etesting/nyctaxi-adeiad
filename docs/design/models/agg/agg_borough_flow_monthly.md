---
artifacts: [agg_borough_flow_monthly]
---

# agg_borough_flow_monthly

Monthly origin-borough to destination-borough flow: the trip star rolled up to two boroughs and a month, with the origin borough's cross-borough share on every row.

## Grain

One row per (pickup month, origin borough, destination borough) that carried at least one billable trip. The alternatives were a separate origin-borough row set for the share, and a separate table; the user chose the share as a column so the three measures sit in one row. Source: R-01, user answer.

## Schema

- `transformation/models/marts/agg/`: `agg` (default). Source: user answer.

## Decisions

- `D-01` Aggregate `fct_trip` joined to `dim_zone` twice, once per zone role, and publish one row per month, origin borough and destination borough. Borough is the label the city's question uses, and the two roles are the same dimension joined twice. Source: R-01.
- `D-02` Billable trips only, inside the reporting window, applied here in gold and nowhere upstream. Source: R-02, R-07, [ADR 0003](../../../adr/0003-billable-trip-definition-and-where-it-applies.md).
- `D-03` No trip-count floor. Every borough pair that carried a billable trip is published. Source: R-03, [ADR 0018](../../../adr/0018-the-published-flow-floor-does-not-apply-to-a-borough-rollup.md).
- `D-04` Build from the star, not from `agg_od_flow_matrix`: that surface has already dropped every zone pair under 25 billable trips, so a rollup of it could not publish every borough pair. Source: R-03, [ADR 0018](../../../adr/0018-the-published-flow-floor-does-not-apply-to-a-borough-rollup.md).
- `D-05` Keep `Unknown` and `N/A` as origins and destinations and flag each side with `origin_is_unresolved_borough` / `dest_is_unresolved_borough`, so the matrix sums to the star's population and a consumer can filter the unresolved zones. Source: R-04, [ADR 0012](../../../adr/0012-unresolved-zones-are-retained-and-flagged.md).
- `D-06` The cross-borough share is computed per origin and month over the published rows, and the numerator and denominator are published beside it (`origin_cross_borough_trip_count`, `origin_trip_count`), the way `agg_trip_zone_daypart_dow` publishes `measurable_tip_trip_count` beside `tip_measurable_share`. The denominator is the sum of that origin's rows, so no trip is counted in the share and missing from the table. Source: R-05, user answer.
- `D-07` The month is `cast(date_trunc('month', pickup_datetime) as date)` as `month_start_date`, the same date the `dim_date` spine carries, so a month joins the calendar without a cast. Source: R-07.
- `D-08` Pairs with no billable trip in the month have no row; the grid is not zero-filled. Source: R-06, user answer.
- `D-09` `is_intra_borough` is published as a derived flag beside the two borough labels, as `agg_od_flow_matrix` does, so a consumer does not re-derive the same predicate. Source: R-01.
- `D-10` Materialised as a table, like the rest of the `agg` folder, with an enforced contract. Source: `dbt_project.yml`, sibling aggregate models.
- `D-11` The relation is an aggregate logical source of the trips star, not a new star and not a `semantic_exclusions` entry: it is the star's rows rolled up and it carries no group-level cut. The share is published as its own metric. Source: R-08, `semantic-model` routing.
- `D-12` The contract is a new ODCS file for the relation, `status: proposed` until the relation ships. Source: R-08, `repo-map.json` `artifact_paths.data_contract`.

## Rejected

- Rolling up `agg_od_flow_matrix` — its 25-trip zone floor would drop borough pairs ([ADR 0018](../../../adr/0018-the-published-flow-floor-does-not-apply-to-a-borough-rollup.md)).
- A separate origin-borough relation for the share — the user chose one row set.
- Zero-filling the 64-cell grid — the user chose to omit absent pairs.
- Filtering `Unknown` and `N/A` out of the matrix — the user chose to keep and flag them ([ADR 0012](../../../adr/0012-unresolved-zones-are-retained-and-flagged.md)).

## Consumers

None in this repo yet. Intended for reports and ad-hoc analysis of traffic between boroughs; the canonical model publishes it as an aggregate source of the trips star.

## Logical Model

```yaml
documents:
  - logical-model/nyc_taxi_analytics.ossie.yaml
    datasets:
      added: [borough_flows]
      changed: []
      retired: []
    metrics:
      added: [cross_borough_trip_share]
      changed: []
      retired: []
    logical_sources:
      added: [borough_flows]
      changed: []
      retired: []
ontology:
  - ontology/nyc_taxi_analytics.mapping.yaml
    concepts:
      added: []
      changed: []
      retired: []
    mappings: []
    reason: the aggregate carries no concept identity (no trip key, no zone key), so no concept is reached.
```

## History

- 2026-11-24 — borough-flow — design record written — D-01 to D-12 — terms: added Cross-borough trip share

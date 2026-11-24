---
status: decided
date: 2026-11-24
---

# The billable verdict is applied where the daily zone figures are built

A trip is **billable** when its total amount is positive. The verdict is still computed once, in `int_trip_quality_flags`, and `fct_trip` still keeps every trip and exposes it as `is_billable`. What changes from ADR 0003 is where the verdict is applied when two published reports read the same numbers: `int_trip_zone_daily` aggregates the billable population and the all-trip population in one pass over `fct_trip`, `mart_daily_zone_revenue` publishes the billable one, and `agg_trip_zone_daily` publishes both. Every other revenue and flow mart — `mart_monthly_service_summary`, `mart_revenue_component_bridge` and `agg_od_flow_matrix` — still applies the rule in gold; the quality marts still report billable and non-billable counts side by side, and the fleet-operations marts still do not use the rule at all.

The report's owner supplied the choice: the finance daily zone revenue report and the operations daily-zone figure were two builds of the same numbers, and one shared computation was required to leave every published value unchanged (docs/requirement/2026-11-24-finance-zone-revenue-report-from-operations-figures-290100c7.md R-01).

## Considered options

- **Apply the verdict in each gold mart** (ADR 0003) — rejected for the daily zone pair: it is what produced two scans of the trip fact, and a change to the population has to be made in two places.
- **Group the shared build by the verdict and let each report filter** — rejected: `agg_trip_zone_daily` publishes a distinct driver count, which is not additive across the verdict, so the demand report could not recover its published value by summing.
- **One shared aggregate with both populations side by side, the verdict applied there** — chosen: one pass, the published values reproduced exactly, and the excluded trips still visible as the all-trip columns of the same relation.

## Consequences

- A report that shares its daily zone figures with another report takes the billable population from the build that computes it, not from a filter of its own.
- The shared build reduces rows and never replaces `fct_trip` in quality work: the excluded trips survive as its all-trip columns, and `fct_trip` is unchanged.
- Changing the reporting window or the verdict restates both reports at once.
- A revenue or flow mart that does not share its build with another report still applies the rule in gold.

## Affected designs

- [`models/core/fct_trip.md`](../design/models/core/fct_trip.md)
- [`models/intermediate/int_trip_quality_flags.md`](../design/models/intermediate/int_trip_quality_flags.md)
- [`models/intermediate/int_trip_zone_daily.md`](../design/models/intermediate/int_trip_zone_daily.md)
- [`models/finance/mart_daily_zone_revenue.md`](../design/models/finance/mart_daily_zone_revenue.md)
- [`models/agg/agg_od_flow_matrix.md`](../design/models/agg/agg_od_flow_matrix.md)
- [`models/agg/agg_trip_zone_daily.md`](../design/models/agg/agg_trip_zone_daily.md)

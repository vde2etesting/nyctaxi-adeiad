---
status: decided
date: 2026-11-24
---

# The published-flow floor stops at zone pairs and does not apply to a borough rollup

`agg_od_flow_matrix` publishes a zone pair only at 25 billable trips (ADR 0017), because the 265 × 265 cross product of zones is mostly ones and twos and publishing it invites reading noise as a route. A borough rollup has at most 64 cells a month, so the same floor removes no noise; it removes traffic the city asked about. At monthly grain in Q1 2024 it drops 49 of the 180 borough pairs that carried a billable trip — more than a quarter — and the smallest published pairs would be reduced to nothing while the smallest dropped ones carry a single trip on a real route. A surface that reports every borough pair therefore publishes every pair that carried a billable trip, whatever its size, and the floor stays where ADR 0017 put it.

The user set this on the requirement: asked whether the borough table should carry the floor or publish every pair, they chose every pair, and the answer is the source of this decision.

## Considered options

- **Apply the 25-trip floor at borough-month grain** — rejected: it removes 49 of the 180 populated cells in Q1 2024, and the reason for the floor does not hold at 64 cells.
- **Reuse `agg_od_flow_matrix` and roll it up to boroughs** — rejected: the zone matrix has already dropped every pair under the floor, so a rollup of it inherits the floor and cannot publish every borough pair.
- **Publish every borough pair that carried a billable trip, aggregated from the star** — chosen.

## Consequences

- A borough table's totals are the star's billable population over trips whose pickup and dropoff zones both resolve, where `agg_od_flow_matrix`'s totals are a subset. The two surfaces are not interchangeable, and each states its own population.
- A borough pair with no billable trips in a month has no row; the grid is not zero-filled.
- The floor stays defined for published zone pairs only. A future surface at a coarser geography decides its own population rather than inheriting 25.

## Affected designs

- [`models/agg/agg_borough_flow_monthly.md`](../design/models/agg/agg_borough_flow_monthly.md)

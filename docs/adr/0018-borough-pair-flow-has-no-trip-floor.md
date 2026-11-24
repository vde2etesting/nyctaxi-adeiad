---
status: decided
date: 2026-11-24
---

# A borough-pair flow publishes every pair; the 25-trip floor belongs to zone pairs

`agg_borough_flow_monthly` publishes one row per month, origin borough and destination borough with at least one billable trip, with no minimum-trip floor. ADR 0017's floor of 25 billable trips is a rule about the zone-pair surface `agg_od_flow_matrix`: there the full 265 × 265 cross product is mostly ones and twos, and a thin pair reads as a route that does not exist. At borough grain the population is eight groups, not 265, a borough pair is already a coarse statement about a whole area, and the floor would break the aggregate's own arithmetic: each borough's outbound total and its cross-borough share are computed over all of that borough's trips, so dropping thin pairs would make the published rows disagree with the trips they claim to describe while still looking like a complete matrix.

The consequence is that the two surfaces answer different questions and are not interchangeable. `agg_od_flow_matrix` reports published corridors and is a subset of the star's billable totals (ADR 0017); `agg_borough_flow_monthly` reports every borough pair and reconciles to the star over the reporting window. A pair-month with no billable trip at all has no row: the table is a rollup of trips, not a dense grid, and Q1 2024 leaves 12 of its 192 possible borough-pair-month cells empty for that reason.

## Considered options

- **Apply the 25-trip floor per borough pair per month** — rejected: it drops thin pairs whose trips are counted in the origin borough's own total, so the share column and the trips column stop agreeing with each other.
- **Apply the floor per borough pair over the whole window** — rejected: it keeps a pair's rows for all three months or none, so a month's cell can still be a single trip while the pair qualifies, and the floor no longer describes any population a reader can name.
- **No floor, omit empty cells** — chosen, and the trade-off accepted is that a thin borough pair is published beside a corridor as if the two were comparable; the reader who cares is answered by the trip count on every row, not by a filter.
- **No floor, emit every pair as a dense grid with zero rows** — rejected: those rows would carry trips the warehouse does not hold, and no other aggregate in this project invents empty members.

## Consequences

- The threshold stays in one place, `agg_od_flow_matrix.sql`. A floor added to a borough-grain aggregate is a new decision, not a reuse of this one.
- `agg_borough_flow_monthly` reconciles to `fct_trip`'s billable totals for the reporting window; `agg_od_flow_matrix` deliberately does not.
- A borough pair that appears or disappears between runs changes the row count; that is the trips changing, not the surface's rule.
- Adding a ninth borough group (a new unresolved zone) adds rows without a rule change.

## Affected designs

- [`models/agg/agg_borough_flow_monthly.md`](../design/models/agg/agg_borough_flow_monthly.md)

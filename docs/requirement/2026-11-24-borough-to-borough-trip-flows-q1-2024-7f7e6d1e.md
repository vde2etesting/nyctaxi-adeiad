---
kinds: [transformation]
---

# Requirement: Borough-to-borough trip flows Q1 2024

## Ask

Mobility Planning Lead Leila Haddad asked, on the city's question, for a monthly Q1 2024 view of the trips and revenue from each borough to each borough, and the share of trips that leave the borough they started in. She consumes it as a published table in the boundary layer, and the city reads the cross-borough share from the same rows.

## Requirements

- [ ] `R-01` A new boundary dbt model publishes one row per (pickup month, origin borough, destination borough) over the reporting window, which is Q1 2024 — accept when a uniqueness test on the three columns passes and the row count equals the number of distinct (month, origin borough, destination borough) groups in `fct_trip` for billable trips in the window — source: request; user answer on grain
- [ ] `R-02` Each row carries the billable trips of the pair and their revenue — accept when `sum(trip_count)` equals 9,604,511 and `sum(revenue)` equals 263,480,834.99, recomputed independently from `fct_trip` and `dim_zone` over the window — source: ADR 0003; `agg_od_flow_matrix`, `mart_daily_zone_revenue`
- [ ] `R-03` No trip-count floor: every borough pair that carried at least one billable trip in its month is published — accept when the model's minimum `trip_count` is 1 and no (month, origin, destination) group present in `fct_trip` is missing from the table — source: user answer; ADR 0018
- [ ] `R-04` The unresolved boroughs `Unknown` and `N/A` appear as origins and destinations and are flagged — accept when a boolean flag is true exactly on rows whose origin or destination borough is one of those two, and those rows are present — source: user answer; ADR 0012
- [ ] `R-05` Each row carries the origin borough's cross-borough trip share for the month, the cross-borough billable trips divided by all billable trips starting in that borough that month — accept when every row of one (month, origin borough) carries the same value and an independent recomputation from `fct_trip` matches on every row — source: user answer; `CONTEXT.md` `Cross-borough trip share`
- [ ] `R-06` A borough pair with no billable trips in a month has no row and no row carries a zero `trip_count` — accept when the table holds fewer than the 192 cells the 8 borough values and 3 months allow and `min(trip_count)` is 1 — source: user answer
- [ ] `R-07` Months are the pickup month and revenue counts only billable trips inside the reporting window — accept when a trip picked up on the first and last day of each month lands in that month, and a refund or zero-total trip is absent from the table — source: ADR 0003; request
- [ ] `R-08` The new relation publishes as the other aggregate marts do: a data contract, an Ossie logical source (or a recorded reason it is excluded), an ontology mapping where a concept is reached, a design record, and a description that states grain and population — accept when `odcs check`, `ossie_lint`, `ossie bindings` and the semantic-model and ontology validation gates pass for it — source: `repo-map.json` `contracts`, `logical-model`, `ontology`

## Business decisions

| Decision | Value | Source |
| --- | --- | --- |
| Grain | One row per pickup month, origin borough and destination borough; the share is a column on each origin→destination row, repeated per origin and month | request; user answer |
| Trip population | Billable trips only (`total_amount > 0`), inside the reporting window | ADR 0003: "A new revenue or flow mart applies the rule" |
| Revenue measure | Sum of `total_amount` over those trips | `agg_od_flow_matrix`, `mart_daily_zone_revenue` |
| Cross-borough share | Cross-borough billable trips ÷ all billable trips starting in that borough that month, the same value on every row of the origin-month | user answer; `CONTEXT.md` |
| Trip-count floor | None: every borough pair that carried a billable trip is published | user answer; ADR 0018 |
| Unresolved boroughs | `Unknown` and `N/A` kept as their own origins and destinations, flagged | user answer; ADR 0012 |
| Empty pairs | Omitted, not zero-filled | user answer |
| Period boundary | Month of `pickup_datetime`, through the existing reporting-window macro; the window is exactly Q1 2024 | request; ADR 0003 |
| Edge periods | Not applicable: January, February and March 2024 are each complete calendar months in the warehouse (2024-01-01 to 2024-01-31, 2024-02-01 to 2024-02-29, 2024-03-01 to 2024-03-31) | data |
| Coverage | Not applicable: revenue is summed over billable trips, whose `total_amount` is positive by definition and null on none of them | ADR 0003; data |
| Unmatched and null keys | No Q1 trip lacks a pickup or dropoff zone key, and a trip that cannot be placed in a borough cannot enter the matrix; the join drops nothing today | data; ADR 0015 |
| Reuse | Built from `fct_trip` joined to `dim_zone` twice, not from `agg_od_flow_matrix`, whose zone-pair floor would drop borough pairs | ADR 0018 |
| Extended scope | The contract, logical model and ontology mapping stay in `transformation`; no schedule or orchestration item | playbook |

## Out of scope

- Any change to `fct_trip`, `dim_zone`, `agg_od_flow_matrix` or another published model.
- Zone-level detail: the table is at borough grain.
- An orchestration item or schedule.

## Open questions

None. The grain, the floor, the unresolved boroughs and the empty pairs were each settled by the user before this requirement was written.

## Approvals
- 2026-11-24T04:14:08Z — requirement approved — "Approve — continue to design" — 6438d2d

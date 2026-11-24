---
kinds: [transformation]
---

# Requirement: Borough-to-borough monthly flow and cross-borough share

## Ask

Leila Haddad, Mobility Planning Lead, asked for this on behalf of a city question about how much traffic crosses borough lines:

> "The city asked how much of our traffic crosses borough lines. For each month of Q1 2024, I need the trips and the revenue from each borough to each borough, and the share of trips that leave the borough they started in."

Delivered as a new gold aggregate table so planners and the city answer can read it repeatedly rather than each rewriting the group-by.

## Requirements

- [ ] `R-01` Each calendar month of Q1 2024 carries one row per origin borough and destination borough with the billable trips and the revenue between them — accept when, for the built table, `sum(trip_count)` and `sum(total_revenue)` equal an independent `fct_trip` group-by over the reporting window (9,604,511 billable trips and 263,480,834.99 in total_amount at this commit), and every row's month falls inside 2024-01-01 to 2024-03-31 — source: request
- [ ] `R-02` Each row carries the cross-borough share of its origin borough and month: the borough's trips to a different borough over all billable trips picked up in that borough that month, the same value on every row of that borough and month — accept when, for every origin borough and month, `cross_borough_trip_share * origin_borough_trip_count` equals the summed `trip_count` of that borough's rows whose destination differs, and the share is between 0 and 1 — source: answer "origin_denominator"
- [ ] `R-03` No minimum-trip floor applies: every borough pair with at least one billable trip in a month is published, and a pair-month with none is omitted — accept when the built table holds 180 rows and includes pairs as thin as one trip — source: answer "no_floor", answer "omit"
- [ ] `R-04` Trips that start or end in a borough the TLC could not resolve stay in the table as their own borough group, marked by the borough's own name, and their share is computed the same way — accept when the table holds rows for `Unknown` and `N/A` and their origin-borough-month shares reconcile like every other borough — source: `docs/adr/0012-unresolved-zones-are-retained-and-flagged.md`
- [ ] `R-05` The table is a boundary relation of the aggregate layer with an enforced contract, documented to the data it holds: descriptions and its design record state billable-only, the absent floor, the share definition and the retained unresolved boroughs — accept when `verifying`'s docs-match-data check finds no disagreement between them and the built relation — source: request, `repo-map.json` layers

## Business decisions

| Decision | Value | Source |
| --- | --- | --- |
| Grain | One row per calendar month × origin borough × destination borough; the month key is the first day of the calendar month of the pickup date | request |
| Edge periods | Not applicable: the reporting window covers every day of all three months (91 distinct pickup dates, 2024-01-01 to 2024-03-31), so no period is cut short and no incomplete mark is needed | query on `core.fct_trip` at this commit |
| Population | Billable trips only, inside the reporting window, per ADR 0003, because the table reports revenue and flows | `docs/adr/0003-billable-trip-definition-and-where-it-applies.md` |
| Minimum-trip floor | None. ADR 0017's 25-trip floor is a rule about zone pairs on the OD surface; a borough pair is a coarse unit already, and applying it here would make each borough's outbound total and its cross-borough share disagree with the trips they are drawn from | answer "no_floor" |
| Metric: trips | Count of billable trips on the borough pair in the month | request |
| Metric: revenue | Sum of `total_amount` over those billable trips, the same measure `mart_daily_zone_revenue` and `agg_od_flow_matrix` publish | request, `transformation/models/marts/agg/agg_od_flow_matrix.sql` |
| Metric: cross-borough share | Per origin borough and month: billable trips to a different borough ÷ all billable trips picked up in that borough, repeated on each of the borough's rows, never summed across them | answer "origin_denominator" |
| Coverage | Every published row carries both measures, so no measure is missing where a row exists; the origin borough and month's billable trip total is published beside the share as its denominator | playbook default |
| Empty cells | A borough pair with no billable trips in a month is omitted, not emitted as a zero row: 12 of the 192 possible borough-pair-month cells are empty in Q1 2024 | answer "omit" |
| Reuse | A new relation built from `fct_trip`, not on a published model: `agg_od_flow_matrix` is finer but filtered by ADR 0017's floor, so rolling it up would lose pairs and stop the table reconciling to the trips it reports; `mart_daily_zone_revenue` has no destination borough | `transformation/models/marts/agg/agg_od_flow_matrix.sql`, `transformation/models/marts/finance/mart_daily_zone_revenue.sql` |
| Unmatched and null keys | Keep every row. No trip in the window has a null pickup or dropoff zone key; a zone whose borough is `Unknown` or `N/A` is a real unresolved zone (ADR 0012) and groups under its own borough name | query on `core.fct_trip` at this commit, `docs/adr/0012-unresolved-zones-are-retained-and-flagged.md` |
| Extended scope | Not applicable: no schedule is added, and the contract and semantic-model deliverables stay in the `transformation` kind | playbook default |

## Out of scope

- Any change to `agg_od_flow_matrix`, `mart_daily_zone_revenue` or any other published model, and to ADR 0017's floor on the zone-pair surface.
- Any new source, ingestion change or schedule.
- Periods outside the reporting window, and making the period a parameter.
- Zone-level detail: this table is borough-grain only.

## Open questions

None.

## Approvals

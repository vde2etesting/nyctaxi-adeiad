---
kinds: [fix]
---

# Case: the airport fee is counted twice in the revenue walk

## Defect

**Anchor:** `finance.mart_revenue_component_bridge`, a boundary relation under an enforced dbt contract (`transformation/models/marts/finance/_finance.yml`) and an ODCS contract (`contracts/finance/mart_revenue_component_bridge.odcs.yaml`). It is fed by `fct_trip.fare_residual`, which `int_trip_fare_components` computes with the `fare_residual` macro.

**Statement:** over the whole report window (2024-01-01 ≤ pickup < 2024-04-01), the bridge's nine components sum to **$264,722,304.24** while billable revenue is **$263,480,834.99**. The walk is higher by **$1,241,469.25**, exactly `sum(coalesce(airport_fee, 0))` over billable trips. The walk's own `total_amount` column sums to billable revenue, so scope, population and trip totals agree on both sides; only the components overstate.

**Window:** the three-month load in the Domain warehouse at the Change Baseline (`1184020`).

**Category:** `data-quality`. No test asserts that the walk balances, so the build stays green.

## Root-cause analysis

**Blast radius.** Changing the residual's definition restates a published value in four places, and one of them is the fact itself:

| Relation | Column | Effect |
| --- | --- | --- |
| `intermediate.int_trip_fare_components` (internal) | `fare_residual`, `has_unexplained_residual` | residual falls by the trip's airport fee; fewer trips flagged unbalanced |
| `core.fct_trip` (boundary, contracted, incremental) | `fare_residual` | published value restated; existing rows only change on a full refresh, because the incremental predicate loads only later pickups |
| `finance.mart_revenue_component_bridge` (boundary, contracted) | `c_residual` | the walk balances; components then sum to `total_amount` |
| `ops.mart_trip_quality_scorecard` (boundary, contracted) | `unbalanced_total_count` | falls where the airport fee was the only unexplained amount |
| Semantic model `logical-model/nyc_taxi_analytics.ossie.yaml` | metric `fare_residual_total` | restated with `fct_trip.fare_residual` |

No column is added, removed or retyped: the dbt contract of each relation and the ODCS contracts keep their shape, and only values move. Because `fct_trip` is incremental, restating its existing rows needs `dbt build --full-refresh --select fct_trip`, a full refresh of a published model and therefore a breaking delta. The semantic-layer exclusion of the bridge (`repo-map.json` `semantic_exclusions`) is about row fan-out when its measures are summed across components; it says nothing about this arithmetic error.

**Root cause.**

1. `fare_residual(alias)` subtracts fare, tip, tolls and `total_surcharges()`, and `surcharge_columns()` is `extra, mta_tax, improvement_surcharge, congestion_surcharge`. `airport_fee` is never subtracted, so it stays inside the residual. [`code-inspection`: `transformation/macros/finance.sql`]
2. The bridge emits `sum(coalesce(f.airport_fee, 0))` as `c_airport_fee` (component order 8) and `sum(f.fare_residual)` as `c_residual` (component order 9). [`code-inspection`: `transformation/models/marts/finance/mart_revenue_component_bridge.sql`]
3. The sum of the nine components is therefore `total_amount + airport_fee` in every group that carries a fee. Over the 48 `(trip_month, service_type_key, borough_name)` groups, 21 are off by more than a cent; the total absolute gap is $1,241,469.250002 and `(component sum − total_amount) − group airport fee` sums to $0.000016 in absolute value, with a maximum group gap of $460,503.75. [`sql-probe`: grouped `finance.mart_revenue_component_bridge`]
4. Component sum $264,722,304.24, billable revenue $263,480,834.99, airport fee $1,241,469.25. [`sql-probe`: bridge and `core.fct_trip` over the window]
5. The residual is consistently defined, not randomly wrong: `sum(fare_residual)` on `fct_trip` and `sum(c_residual)` on the bridge both read −$2,027,610.25. [`sql-probe`]
6. The airport fee is yellow-only and present in every month: Jan $407,312.50 from 232,750 trips, Feb $372,771.00 from 213,012, Mar $461,385.75 from 263,649 — 709,411 trips in all. [`sql-probe`: `core.fct_trip` grouped by month and service type]
7. `CONTEXT.md` defines the fare residual as "what is left of a trip's total after every modelled fare component". The bridge treats the airport fee as a modelled component (order 8), so the residual must be net of it. [`provenance`: `CONTEXT.md`, "Fare residual"]

**Checks run.**

| Check | Outcome |
| --- | --- |
| Component sum against billable revenue | gap $1,241,469.25, equal to the airport fee: confirms |
| Per-group gap minus group airport fee | $0.000016 absolute in total: confirms the fee explains the whole gap |
| `fct_trip.fare_residual` against bridge `c_residual` | both −$2,027,610.25: the residual is one consistent definition |
| Airport fee by month and service type | yellow only, three months, 709,411 trips: confirms the population |
| Contract shape (`_finance.yml`, ODCS, `fct_trip` ODCS) | same columns and types; no shape change |
| Run history (`list_runs`, 90 days, domain) | no runs recorded: the runtime plane is unavailable here |
| `git log` over the implicated files | the clone is shallow (one grafted commit): history cannot discriminate |

**Confidence.** High. The per-group probe and the global totals agree to the cent, and the residual reconciliation shows the arithmetic is systematic rather than a data defect.

**Data-loss check.** The fix adds one subtraction inside a computed expression. It deduplicates nothing, filters nothing and keeps every row.

**Decision check.** No accepted ADR or design record defines the residual without the airport fee. `CONTEXT.md` requires the residual to be net of every modelled component, and `ADR 0003` keeps the billable filter where the bridge already applies it. The bridge has no design record yet; the fix supplies one.

**Decision.** `code-change`. Class: failing or missing dbt test — no test asserts that the walk balances. Sandbox verification: re-run the affected models with `fct_trip` full-refreshed, plus a new singular test that sums the nine components per group and compares them with `total_amount`, which fails on the current code and passes after the fix.

Proposed change:

- `transformation/macros/finance.sql`: subtract `coalesce({{ alias }}.airport_fee, 0)` in `fare_residual`, so the residual is net of every component the bridge models.
- `transformation/models/docs.md`: add the airport fee to the `fare_residual` documentation's list of components.
- `transformation/tests/assert_revenue_bridge_components_sum_to_total.sql`: new singular test, the failing-first assertion.
- `docs/design/models/finance/mart_revenue_component_bridge.md`: the missing design record, recording the residual's definition.
- `test-map.json`: list the new test under the finance module.

## Approvals
- 2026-11-24T05:44:55Z — design approved — "approve" — fa73e5b
- 2026-11-24T05:44:55Z — breaking contract approved — "approve" — fa73e5b — promised shape: `fct_trip.fare_residual` restated to total minus every modelled component including the airport fee; columns and types unchanged, a full refresh of the published `fct_trip` required to restate existing rows

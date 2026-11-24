-- The matrix is the star's rows rolled up, not a filtered sample: every billable
-- in-window trip appears exactly once, and the revenue adds up at the cent (ADR
-- 0018). Money is compared at two decimals because DuckDB's double sums are not
-- reproducible bit for bit.
with published as (
    select
        sum(trip_count) as trips,
        round(sum(total_revenue), 2) as revenue
    from {{ ref('agg_borough_flow_monthly') }}
),

fact as (
    select
        count(*) as trips,
        round(sum(f.total_amount), 2) as revenue
    from {{ ref('fct_trip') }} f
    where
        {{ in_report_window('f.pickup_datetime') }}
        and f.is_billable
)

select
    f.trips as fact_trips,
    p.trips as published_trips,
    f.revenue as fact_revenue,
    p.revenue as published_revenue
from fact f
cross join published p
where
    f.trips is distinct from p.trips
    or f.revenue is distinct from p.revenue

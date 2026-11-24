-- No floor and no zero filling (ADR 0018): every borough pair-month that carried
-- a billable trip is published once, and a cell with no such trip has no row.
-- A missing cell, an extra cell and a zero-trip row all come back here.
with star as (
    select
        cast(date_trunc('month', f.pickup_datetime) as date) as month_start_date,
        o.borough_name as origin_borough,
        dz.borough_name as dest_borough,
        count(*) as trip_count
    from {{ ref('fct_trip') }} f
    join {{ ref('dim_zone') }} o on f.pickup_zone_key = o.zone_key
    join {{ ref('dim_zone') }} dz on f.dropoff_zone_key = dz.zone_key
    where
        {{ in_report_window('f.pickup_datetime') }}
        and f.is_billable
    group by 1, 2, 3
),

published as (
    select month_start_date, origin_borough, dest_borough, trip_count
    from {{ ref('agg_borough_flow_monthly') }}
)

select
    coalesce(s.month_start_date, p.month_start_date) as month_start_date,
    coalesce(s.origin_borough, p.origin_borough) as origin_borough,
    coalesce(s.dest_borough, p.dest_borough) as dest_borough,
    s.trip_count as star_trips,
    p.trip_count as published_trips
from star s
full outer join published p
    on
        s.month_start_date = p.month_start_date
        and s.origin_borough = p.origin_borough
        and s.dest_borough = p.dest_borough
where s.trip_count is null or p.trip_count is null or p.trip_count < 1

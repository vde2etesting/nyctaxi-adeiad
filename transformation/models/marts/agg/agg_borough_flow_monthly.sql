-- Monthly borough-to-borough flow: the trip star rolled up to the pickup month,
-- the pickup borough and the dropoff borough, with the origin borough's
-- cross-borough share on every row.
--
-- No trip-count floor. The twenty-five-trip floor belongs to the published zone
-- pairs (ADR 0017); at borough level it would hide whole boroughs, so every pair
-- that carried a billable trip is published (ADR 0018). A pair with no billable
-- trip in the month has no row: the grid is not zero-filled.
--
-- Unknown and N/A zones stay in as boroughs, flagged per side, so the matrix sums
-- to the star's population (ADR 0012).
with flows as (
    select
        cast(date_trunc('month', f.pickup_datetime) as date) as month_start_date,
        o.borough_name as origin_borough,
        dz.borough_name as dest_borough,
        o.is_unresolved_zone as origin_is_unresolved_borough,
        dz.is_unresolved_zone as dest_is_unresolved_borough,
        o.borough_name = dz.borough_name as is_intra_borough,
        count(*) as trip_count,
        sum(f.total_amount) as total_revenue
    from {{ ref('fct_trip') }} f
    join {{ ref('dim_zone') }} o on f.pickup_zone_key = o.zone_key
    join {{ ref('dim_zone') }} dz on f.dropoff_zone_key = dz.zone_key
    where
        {{ in_report_window('f.pickup_datetime') }}
        and f.is_billable
    group by 1, 2, 3, 4, 5, 6
),

origin_month as (
    select
        month_start_date,
        origin_borough,
        dest_borough,
        origin_is_unresolved_borough,
        dest_is_unresolved_borough,
        is_intra_borough,
        trip_count,
        total_revenue,
        sum(trip_count) over (
            partition by month_start_date, origin_borough
        ) as origin_trip_count,
        sum(case when is_intra_borough then 0 else trip_count end) over (
            partition by month_start_date, origin_borough
        ) as origin_cross_borough_trip_count
    from flows
)

select
    month_start_date,
    origin_borough,
    dest_borough,
    origin_is_unresolved_borough,
    dest_is_unresolved_borough,
    is_intra_borough,
    cast(trip_count as bigint) as trip_count,
    cast(total_revenue as double) as total_revenue,
    cast(origin_trip_count as bigint) as origin_trip_count,
    cast(origin_cross_borough_trip_count as bigint) as origin_cross_borough_trip_count,
    cast(
        {{ safe_divide('origin_cross_borough_trip_count', 'origin_trip_count') }} as double
    ) as cross_borough_trip_share
from origin_month

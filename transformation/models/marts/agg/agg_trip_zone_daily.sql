-- Daily zone demand, with period-over-period context computed once here rather
-- than in every consuming report. The window functions are the point: a raw
-- daily count answers "how many", the lag and rolling average answer "is
-- that normal", which is the question anyone actually asks next.
--
-- The daily figures come from the one shared computation (ADR 0018), not from
-- fct_trip: this report and finance's daily zone revenue read the same rows.
with daily as (
    select
        d.pickup_date_key,
        d.pickup_date,
        z.zone_natural_key as pickup_location_id,
        z.zone_name,
        z.borough_name,
        d.trip_count,
        d.total_revenue,
        d.total_miles,
        d.attributed_driver_count
    from {{ ref('int_trip_zone_daily') }} d
    join {{ ref('dim_zone') }} z on d.pickup_zone_key = z.zone_key
)

select
    d.pickup_date_key,
    d.pickup_date,
    d.pickup_location_id,
    d.zone_name,
    d.borough_name,
    d.trip_count,
    d.total_revenue,
    d.total_miles,
    d.attributed_driver_count,
    lag(d.trip_count, 1) over w as prev_day_trip_count,
    lag(d.trip_count, 7) over w as same_day_last_week_trip_count,
    avg(d.trip_count) over (
        partition by d.pickup_location_id
        order by d.pickup_date
        rows between 6 preceding and current row
    ) as trip_count_7d_avg,
    sum(d.total_revenue) over (
        partition by d.pickup_location_id
        order by d.pickup_date
        rows between 27 preceding and current row
    ) as revenue_28d_rolling,
    rank() over (
        partition by d.pickup_date
        order by round(d.total_revenue, 2) desc
    ) as revenue_rank_that_day
from daily d
window w as (partition by d.pickup_location_id order by d.pickup_date)

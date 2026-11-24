-- Daily revenue by pickup zone.
--
-- The billable verdict (ADR 0018) is applied in int_trip_zone_daily, above both
-- daily zone reports, so the rows this excludes stay visible there to
-- data-quality work. Only the billable columns are published here.
select
    d.pickup_date as trip_date,
    z.zone_natural_key as pickup_location_id,
    z.borough_name as borough,
    z.zone_name,
    z.reporting_region,
    d.billable_trip_count as trip_count,
    d.billable_fare_revenue as fare_revenue,
    d.billable_tip_revenue as tip_revenue,
    d.billable_surcharge_revenue as surcharge_revenue,
    d.billable_toll_revenue as toll_revenue,
    d.billable_total_revenue as total_revenue
from {{ ref('int_trip_zone_daily') }} d
join {{ ref('dim_zone') }} z on d.pickup_zone_key = z.zone_key
where d.billable_trip_count > 0

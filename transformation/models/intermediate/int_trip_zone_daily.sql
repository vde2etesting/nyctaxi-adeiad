-- The one daily-zone computation: every trip in the reporting window, grouped by
-- pickup zone and trip date, with the billable population carried beside it.
--
-- The billable verdict (ADR 0018) is applied here, above the two reports that
-- share these numbers, so neither re-aggregates fct_trip and a change to the
-- population restates both at once. The all-trip columns keep the excluded rows
-- in view for the demand report and for anyone reconciling the two.
select
    cast(f.pickup_date_key as integer) as pickup_date_key,
    cast(f.pickup_date as date) as pickup_date,
    cast(f.pickup_zone_key as varchar) as pickup_zone_key,
    cast(count(*) as bigint) as trip_count,
    cast(sum(f.trip_distance) as double) as total_miles,
    cast(sum(f.total_amount) as double) as total_revenue,
    cast(count(distinct f.driver_key) as bigint) as attributed_driver_count,
    cast(count(*) filter (where f.is_billable) as bigint) as billable_trip_count,
    cast(sum(f.fare_amount) filter (where f.is_billable) as double) as billable_fare_revenue,
    cast(sum(f.tip_amount) filter (where f.is_billable) as double) as billable_tip_revenue,
    cast(sum(f.total_surcharges) filter (where f.is_billable) as double) as billable_surcharge_revenue,
    cast(sum(f.tolls_amount) filter (where f.is_billable) as double) as billable_toll_revenue,
    cast(sum(f.total_amount) filter (where f.is_billable) as double) as billable_total_revenue
from {{ ref('fct_trip') }} f
where {{ in_report_window('f.pickup_datetime') }}
group by 1, 2, 3

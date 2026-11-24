-- The share is the origin borough's cross-borough trips over all its billable
-- trips in the month (CONTEXT.md), and every row of an origin and month carries
-- the same value. The counts are rebuilt from the published rows, so a share
-- computed over some other population shows up here, and so does a share that
-- drifts between rows of one origin and month.
with per_origin as (
    select
        month_start_date,
        origin_borough,
        sum(trip_count) as trips,
        sum(case when is_intra_borough then 0 else trip_count end) as cross_trips,
        count(distinct cross_borough_trip_share) as share_values,
        min(origin_trip_count) as min_origin_trips,
        max(origin_trip_count) as max_origin_trips,
        min(origin_cross_borough_trip_count) as min_origin_cross,
        max(origin_cross_borough_trip_count) as max_origin_cross,
        min(cross_borough_trip_share) as min_share
    from {{ ref('agg_borough_flow_monthly') }}
    group by 1, 2
)

select
    month_start_date,
    origin_borough,
    trips,
    cross_trips,
    min_origin_trips,
    min_origin_cross,
    min_share
from per_origin
where
    min_origin_trips <> max_origin_trips
    or min_origin_cross <> max_origin_cross
    or min_origin_trips <> trips
    or min_origin_cross <> cross_trips
    or share_values > 1
    or abs(min_share - cross_trips::double / nullif(trips, 0)) > 0.000000001

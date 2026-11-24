-- The shared daily-zone model's grain, as its description states it: one row per
-- pickup zone and trip date.
select pickup_date, pickup_zone_key, count(*) as n
from {{ ref('int_trip_zone_daily') }}
group by all
having count(*) > 1

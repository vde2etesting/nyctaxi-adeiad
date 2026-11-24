-- The grain the contract states: one row per pickup month, origin borough and
-- destination borough.
select month_start_date, origin_borough, dest_borough, count(*) as n
from {{ ref('agg_borough_flow_monthly') }}
group by all
having count(*) > 1

-- Unresolved zones are kept and flagged (ADR 0012). A flag that disagrees with
-- the borough label would send a consumer filtering nothing, or filtering out a
-- real borough; `is distinct from` keeps the check honest on a null flag.
select
    month_start_date,
    origin_borough,
    dest_borough,
    origin_is_unresolved_borough,
    dest_is_unresolved_borough
from {{ ref('agg_borough_flow_monthly') }}
where
    origin_is_unresolved_borough is distinct from (origin_borough in ('Unknown', 'N/A'))
    or dest_is_unresolved_borough is distinct from (dest_borough in ('Unknown', 'N/A'))

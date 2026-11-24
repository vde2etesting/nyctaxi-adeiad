---
type: contracts
date: 2026-10-25
commit: 2805630
source: contracts/, domain.duckdb
---

# Contracts review: the questions `reverse` could not settle

## Scope

The 93 contracts under `contracts/`, read against the built warehouse in `domain.duckdb`: every relation a contract is owed, its `information_schema` columns, and one aggregate per column — rows, nulls, distinct values — over the whole table. `reverse` states a finding wherever the contract, the canonical model, the dbt tests and the data leave a point open; this artifact is that queue. Nothing in it is a defect: each row is a question the contract cannot answer for itself, and every answer lands in the contract as prose, a quality rule, a relationship, or a test.

Not queued, because something already settled it:

- a nullable column the data never nulls — a null rate of zero is the answer to "can it be null";
- an enum-shaped column carrying an `accepted_values` test, or any rule that asserts zero violations;
- an enum-shaped column whose name ends in `_key` or `_id` — an identifier's value set is not a domain, so the value-set question never applies to it. A repeating `_key` is asked in class 4, where the question asks what it targets; a non-repeating `_key` or an `_id` is asked in class 6, where the question asks what it references or whether it is the relation's own identifier, unless the contract declares it `primaryKey`;
- a reference-shaped column that declares a `relationships` target;
- a `*_key` column the contract declares `primaryKey` — it states row identity, not a reference;
- an empty relation, whose data settles nothing and so is only asked about where the contract is silent.

The reverse pass is deterministic: the same warehouse yields the same findings in the same order, and `reverse --force` on this tree reproduces all 93 contracts byte for byte. The findings are computed against the contract on disk, so this queue describes the reviewed contracts and not a fresh draft.

`domain.duckdb` is gitignored and rebuilt — `orchestration/run_all.py` runs ingest and then the dbt build over it. The data behind classes 3–6 is therefore this build's, and the counts move when the warehouse is rebuilt; classes 1 and 2 read the contracts and the canonical model, so a rebuild leaves them alone.

## Findings

| ID | Kind | Finding | Evidence | Suggested action | Status |
| --- | --- | --- | --- | --- | --- |
| R-1 | gap | 27 relations state no grain, so nothing in the contract says what one row is. | `reverse` reports them as `finding/no-grain`; `check` warns about the same relations | One sentence per relation in `dataGranularityDescription`. Start here: the grain answers class 4. | open |
| R-2 | gap | 1035 contract entries — 21 tables and 1014 of 1170 declared columns — carry no description. | sections 2a and 2b | One pass per table in the dbt properties file; `generate` carries the enforceable half into the tests. | open |
| R-3 | gap | 127 nullable columns hold nulls with no rule saying whether a null is allowed. | section 3, with the null count per column | A `nullValues` rule where null is a defect, a description sentence where it is a state. | open |
| R-4 | gap | 45 key-shaped columns repeat, so none of them is the row key on its own. | section 4, with the duplicate count per column | Name the identifying combination in the grain, and for each column that is a repeated reference, the target it points at. | open |
| R-5 | gap | 155 string columns are enum-shaped with nothing closing their value set. | section 5, with the distinct count per column | An `accepted_values` rule where the set is closed, a description where it is a lookup. | open |
| R-6 | gap | 112 reference-shaped columns declare no `relationships` target. | section 6 | A `relationships` entry per column; `generate` writes the dbt test it reduces to. | open |

**1501 findings across the six classes below.** The table is the class-level view the triage works from; each section that follows lists the rows it counts, and every row carries the evidence gathered so far and the question that closes it. A finding here is a question, not a defect: the contract cannot answer it for itself, and no other artifact in the repository can answer it either.

## 1. No grain statement

`dataGranularityDescription` is absent, so nothing in the contract says what one row is. These are the same 27 relations `check` already warns about as `contract/no-grain`: a warning there, a queued question here. Answering one is a sentence in prose, and it is the sentence every other question tests against.

| Relation | Evidence | Question | Status |
| --- | --- | --- | --- |
| `bronze.audit_runs` | no grain statement | What does one row of audit_runs represent? | open |
| `bronze.audit_table_loads` | no grain statement | What does one row of audit_table_loads represent? | open |
| `bronze.green_tripdata` | no grain statement | What does one row of green_tripdata represent? | open |
| `bronze.taxi_zone_lookup` | no grain statement | What does one row of taxi_zone_lookup represent? | open |
| `bronze.yellow_tripdata` | no grain statement | What does one row of yellow_tripdata represent? | open |
| `intermediate.int_shift_occupancy` | no grain statement | What does one row of int_shift_occupancy represent? | open |
| `mdm_raw.audit_runs` | no grain statement | What does one row of audit_runs represent? | open |
| `mdm_raw.audit_table_loads` | no grain statement | What does one row of audit_table_loads represent? | open |
| `mdm_raw.borough_master` | no grain statement | What does one row of borough_master represent? | open |
| `mdm_raw.calendar_master` | no grain statement | What does one row of calendar_master represent? | open |
| `mdm_raw.fare_regime_master` | no grain statement | What does one row of fare_regime_master represent? | open |
| `mdm_raw.payment_method_master` | no grain statement | What does one row of payment_method_master represent? | open |
| `mdm_raw.rate_plan_master` | no grain statement | What does one row of rate_plan_master represent? | open |
| `mdm_raw.vendor_master` | no grain statement | What does one row of vendor_master represent? | open |
| `mdm_raw.weather_daily` | no grain statement | What does one row of weather_daily represent? | open |
| `mdm_raw.zone_master` | no grain statement | What does one row of zone_master represent? | open |
| `mdm_raw.zone_poi` | no grain statement | What does one row of zone_poi represent? | open |
| `ops_raw.audit_runs` | no grain statement | What does one row of audit_runs represent? | open |
| `ops_raw.audit_table_loads` | no grain statement | What does one row of audit_table_loads represent? | open |
| `ops_raw.driver` | no grain statement | What does one row of driver represent? | open |
| `ops_raw.driver_status_event` | no grain statement | What does one row of driver_status_event represent? | open |
| `ops_raw.garage` | no grain statement | What does one row of garage represent? | open |
| `ops_raw.lease_agreement` | no grain statement | What does one row of lease_agreement represent? | open |
| `ops_raw.maintenance_event` | no grain statement | What does one row of maintenance_event represent? | open |
| `ops_raw.shift` | no grain statement | What does one row of shift represent? | open |
| `ops_raw.trip_assignment` | no grain statement | What does one row of trip_assignment represent? | open |
| `ops_raw.vehicle` | no grain statement | What does one row of vehicle represent? | open |

## 2. Undescribed table or column

21 tables carry no prose at all, and 1014 of 1170 declared columns carry no `description`. A description is the one thing the catalog, the model and the tests cannot supply: the loader knows a column's type and never its meaning.

### 2a. Tables with nothing describing them (21)

| Relation | Evidence | Question | Status |
| --- | --- | --- | --- |
| `bronze.green_tripdata` | nothing describes this table | What is green_tripdata for? | open |
| `bronze.taxi_zone_lookup` | nothing describes this table | What is taxi_zone_lookup for? | open |
| `bronze.yellow_tripdata` | nothing describes this table | What is yellow_tripdata for? | open |
| `intermediate.int_shift_occupancy` | nothing describes this table | What is int_shift_occupancy for? | open |
| `mdm_raw.borough_master` | nothing describes this table | What is borough_master for? | open |
| `mdm_raw.calendar_master` | nothing describes this table | What is calendar_master for? | open |
| `mdm_raw.fare_regime_master` | nothing describes this table | What is fare_regime_master for? | open |
| `mdm_raw.payment_method_master` | nothing describes this table | What is payment_method_master for? | open |
| `mdm_raw.rate_plan_master` | nothing describes this table | What is rate_plan_master for? | open |
| `mdm_raw.vendor_master` | nothing describes this table | What is vendor_master for? | open |
| `mdm_raw.weather_daily` | nothing describes this table | What is weather_daily for? | open |
| `mdm_raw.zone_master` | nothing describes this table | What is zone_master for? | open |
| `mdm_raw.zone_poi` | nothing describes this table | What is zone_poi for? | open |
| `ops_raw.driver` | nothing describes this table | What is driver for? | open |
| `ops_raw.driver_status_event` | nothing describes this table | What is driver_status_event for? | open |
| `ops_raw.garage` | nothing describes this table | What is garage for? | open |
| `ops_raw.lease_agreement` | nothing describes this table | What is lease_agreement for? | open |
| `ops_raw.maintenance_event` | nothing describes this table | What is maintenance_event for? | open |
| `ops_raw.shift` | nothing describes this table | What is shift for? | open |
| `ops_raw.trip_assignment` | nothing describes this table | What is trip_assignment for? | open |
| `ops_raw.vehicle` | nothing describes this table | What is vehicle for? | open |

### 2b. Undescribed columns (1014)

One row per table; every column named in it is one finding, and one answer in the dbt properties file closes all of a table's rows at once. Columns are listed alphabetically, the order the contracts declare them in.

| Relation | Columns | Evidence | Question | Status |
| --- | --- | --- | --- | --- |
| `agg.agg_driver_daily` | `airport_fee_collected`, `break_hours`, `date_key`, `driver_key`, `driver_ref`, `engagement_type`, `garage_key`, `gross_revenue`, `home_garage_name`, `occupancy_rate`, `on_trip_hours`, `online_hours`, `paid_miles`, `revenue_per_online_hour`, `revenue_per_trip`, `shift_count`, `shift_date`, `tip_revenue`, `total_cost`, `total_margin`, `trip_count`, `unclosed_shift_count`, `vehicles_driven` (23) | no `description` | What does each column mean? | open |
| `agg.agg_driver_monthly` | `active_days`, `driver_key`, `driver_ref`, `engagement_type`, `garage_key`, `gross_revenue`, `home_garage_name`, `margin_rate`, `month_start_date`, `occupancy_rate`, `on_trip_hours`, `online_hours`, `paid_miles`, `revenue_per_online_hour`, `shift_count`, `tip_revenue`, `total_cost`, `total_margin`, `trip_count`, `trips_per_online_hour` (20) | no `description` | What does each column mean? | open |
| `agg.agg_garage_monthly` | `active_vehicles`, `bay_capacity`, `bay_occupancy_rate`, `borough_name`, `down_days`, `garage_key`, `garage_name`, `gross_revenue`, `maintenance_cost`, `month_start_date`, `occupancy_rate`, `on_trip_hours`, `online_hours`, `revenue_per_online_hour`, `shift_count`, `trip_count` (16) | no `description` | What does each column mean? | open |
| `agg.agg_od_flow_matrix` | `avg_corridor_mph`, `avg_distance`, `avg_fare`, `avg_minutes`, `dest_borough`, `dest_is_airport`, `dest_location_id`, `dest_zone`, `is_intra_borough`, `origin_borough`, `origin_is_airport`, `origin_location_id`, `origin_zone`, `total_revenue`, `trip_count` (15) | no `description` | What does each column mean? | open |
| `agg.agg_trip_band_profile` | `avg_measurable_tip_rate`, `avg_total_amount`, `daypart_code`, `distance_band`, `distance_band_order`, `duration_band`, `duration_band_order`, `fare_band`, `fare_band_order`, `non_billable_count`, `pickup_borough`, `service_type_key`, `total_revenue`, `trip_count` (14) | no `description` | What does each column mean? | open |
| `agg.agg_trip_zone_daily` | `attributed_driver_count`, `borough_name`, `pickup_date`, `pickup_date_key`, `pickup_location_id`, `prev_day_trip_count`, `revenue_28d_rolling`, `revenue_rank_that_day`, `same_day_last_week_trip_count`, `total_miles`, `total_revenue`, `trip_count`, `trip_count_7d_avg`, `zone_name` (14) | no `description` | What does each column mean? | open |
| `agg.agg_trip_zone_daypart_dow` | `avg_measurable_tip_rate`, `avg_total_amount`, `avg_trip_distance`, `avg_trip_minutes`, `billable_trip_count`, `borough_name`, `day_name`, `day_of_week`, `daypart_code`, `daypart_name`, `fare_revenue`, `is_airport_zone`, `is_non_working_day`, `is_peak`, `is_weekend`, `measurable_tip_trip_count`, `median_total_amount`, `pickup_location_id`, `reporting_region`, `service_type_key`, `surcharge_revenue`, `tip_measurable_share`, `tip_revenue`, `total_miles`, `total_paid_hours`, `total_revenue`, `trip_count`, `zone_class`, `zone_name` (29) | no `description` | What does each column mean? | open |
| `agg.agg_vehicle_daily` | `asset_utilisation_rate`, `date_key`, `distinct_drivers`, `fuel_type`, `garage_key`, `gross_revenue`, `is_low_emission`, `make_model`, `medallion_number`, `occupancy_rate`, `odometer_miles`, `on_trip_hours`, `online_hours`, `paid_mile_ratio`, `paid_miles`, `shift_count`, `shift_date`, `trip_count`, `vehicle_key` (19) | no `description` | What does each column mean? | open |
| `agg.agg_vehicle_monthly` | `active_days`, `availability_adjusted_activity_rate`, `available_days`, `calendar_days`, `down_days`, `fuel_type`, `garage_key`, `gross_revenue`, `maintenance_cost`, `make_model`, `medallion_number`, `month_start_date`, `occupancy_rate`, `on_trip_hours`, `online_hours`, `paid_miles`, `revenue_per_online_hour`, `shift_count`, `trip_count`, `vehicle_key` (20) | no `description` | What does each column mean? | open |
| `agg.agg_weather_demand_daily` | `avg_fare`, `avg_paid_hours_per_trip`, `avg_trip_distance`, `borough_name`, `day_name`, `is_holiday`, `is_snow_day`, `is_weekend`, `is_wet_day`, `obs_date`, `precip_inches`, `snow_inches`, `temp_avg_f`, `total_revenue`, `trip_count`, `weather_class` (16) | no `description` | What does each column mean? | open |
| `agg.agg_zone_occupancy_hourly` | `available_hours`, `borough_name`, `break_hours`, `daypart_code`, `distinct_drivers`, `distinct_vehicles`, `interval_count`, `interval_date`, `interval_hour`, `is_airport_zone`, `location_id`, `on_trip_hours`, `total_hours`, `zone_name`, `zone_occupancy_rate` (15) | no `description` | What does each column mean? | open |
| `bronze.audit_runs` | `dataset_name`, `destination_name`, `extract_finished_at`, `extract_started_at`, `finished_at`, `first_run`, `load_finished_at`, `load_id`, `load_started_at`, `normalize_finished_at`, `normalize_started_at`, `pipeline_name`, `started_at`, `status`, `total_rows_extracted` (15) | no `description` | What does each column mean? | open |
| `bronze.audit_table_loads` | `file_size`, `load_elapsed`, `load_id`, `load_state`, `rows_extracted`, `rows_normalized`, `table_name` (7) | no `description` | What does each column mean? | open |
| `bronze.green_tripdata` | `DOLocationID`, `PULocationID`, `RatecodeID`, `VendorID`, `congestion_surcharge`, `ehail_fee`, `extra`, `fare_amount`, `improvement_surcharge`, `lpep_dropoff_datetime`, `lpep_pickup_datetime`, `mta_tax`, `passenger_count`, `payment_type`, `store_and_fwd_flag`, `tip_amount`, `tolls_amount`, `total_amount`, `trip_distance`, `trip_type` (20) | no `description` | What does each column mean? | open |
| `bronze.taxi_zone_lookup` | `Borough`, `LocationID`, `Zone`, `service_zone` (4) | no `description` | What does each column mean? | open |
| `bronze.yellow_tripdata` | `Airport_fee`, `DOLocationID`, `PULocationID`, `RatecodeID`, `VendorID`, `congestion_surcharge`, `extra`, `fare_amount`, `improvement_surcharge`, `mta_tax`, `passenger_count`, `payment_type`, `store_and_fwd_flag`, `tip_amount`, `tolls_amount`, `total_amount`, `tpep_dropoff_datetime`, `tpep_pickup_datetime`, `trip_distance` (19) | no `description` | What does each column mean? | open |
| `core.dim_date` | `day_name`, `day_of_week`, `holiday_class`, `holiday_name`, `is_school_term`, `iso_week` (6) | no `description` | What does each column mean? | open |
| `core.dim_driver` | `hack_licence_no`, `lease_id`, `primary_vehicle_id` (3) | no `description` | What does each column mean? | open |
| `core.dim_payment_method` | `counts_as_revenue`, `processor_fee_pct`, `settlement_class`, `settlement_days` (4) | no `description` | What does each column mean? | open |
| `core.dim_trip_quality` | `is_billable`, `is_clean_trip`, `is_implausibly_fast`, `is_implausibly_short`, `is_missing_airport_fee`, `is_missing_passenger_count`, `is_negative_duration`, `is_refund`, `is_sparse_vendor_feed`, `is_undocumented_rate_code`, `is_unresolved_pickup_zone`, `is_zero_distance`, `is_zero_passenger` (13) | no `description` | What does each column mean? | open |
| `core.dim_vehicle` | `make`, `model`, `vin` (3) | no `description` | What does each column mean? | open |
| `core.dim_vendor` | `contract_tier`, `is_approved`, `vendor_legal_name`, `vendor_short_code`, `vendor_version` (5) | no `description` | What does each column mean? | open |
| `core.dim_zone` | `area_sq_mi`, `borough_code`, `centroid_lat`, `centroid_lon`, `demand_tier`, `is_airport_zone`, `is_congestion_zone`, `is_core_market`, `is_nyc`, `is_unresolved_zone`, `poi_categories`, `poi_count`, `resident_population`, `tlc_service_zone`, `zone_class`, `zone_version` (16) | no `description` | What does each column mean? | open |
| `core.fct_shift` | `airport_fee_collected`, `available_seconds`, `break_seconds`, `effective_end_ts`, `fare_revenue`, `idle_rate`, `negative_interval_count`, `occupancy_rate`, `odometer_miles`, `paid_mile_ratio`, `paid_miles`, `paid_seconds`, `recognised_revenue`, `revenue_per_online_hour`, `revenue_per_paid_mile`, `shift_cost`, `shift_margin`, `surcharge_collected`, `telematics_source`, `tip_revenue`, `unaccounted_seconds` (21) | no `description` | What does each column mean? | open |
| `core.fct_status_interval` | `interval_end_ts`, `interval_start_ts`, `is_terminal_interval`, `skew_seconds` (4) | no `description` | What does each column mean? | open |
| `core.fct_trip` | `assignment_method`, `avg_mph`, `congestion_surcharge`, `driver_key`, `dropoff_datetime`, `ehail_fee`, `extra`, `fare_amount`, `improvement_surcharge`, `measurable_tip_rate`, `mta_tax`, `passenger_count`, `pickup_datetime`, `store_and_fwd_flag`, `tip_amount`, `tolls_amount`, `total_surcharges`, `trip_distance`, `trip_seconds`, `trip_type`, `vehicle_key` (21) | no `description` | What does each column mean? | open |
| `finance.mart_daily_zone_revenue` | `borough`, `fare_revenue`, `pickup_location_id`, `reporting_region`, `surcharge_revenue`, `tip_revenue`, `toll_revenue`, `total_revenue`, `trip_count`, `trip_date`, `zone_name` (11) | no `description` | What does each column mean? | open |
| `finance.mart_monthly_service_summary` | `avg_fare`, `counts_as_revenue`, `est_processor_fees`, `payment_method_name`, `service_type`, `settlement_class`, `total_miles`, `total_revenue`, `trip_count`, `trip_month` (10) | no `description` | What does each column mean? | open |
| `finance.mart_revenue_component_bridge` | `borough_name`, `component_amount`, `component_name`, `component_order`, `component_share`, `service_type_key`, `total_amount`, `trip_count`, `trip_month` (9) | no `description` | What does each column mean? | open |
| `intermediate.int_shift_economics` | `airport_fee_collected`, `driver_id`, `engagement_type`, `fare_revenue`, `gross_revenue`, `lease_rate`, `lease_type`, `occupancy_rate`, `on_trip_seconds`, `online_seconds`, `paid_miles`, `paid_seconds`, `recognised_revenue`, `revenue_per_online_hour`, `revenue_per_paid_mile`, `revenue_share_pct`, `shift_cost`, `shift_date`, `shift_id`, `shift_margin`, `surcharge_collected`, `tip_revenue`, `trip_count`, `vehicle_id` (24) | no `description` | What does each column mean? | open |
| `intermediate.int_shift_occupancy` | `available_seconds`, `break_seconds`, `dispatch_seconds`, `driver_id`, `effective_end_ts`, `event_count`, `had_open_interval`, `idle_rate`, `is_unclosed_shift`, `negative_interval_count`, `occupancy_rate`, `odometer_miles`, `on_trip_seconds`, `online_seconds`, `shift_date`, `shift_id`, `shift_start_ts`, `telematics_source`, `unaccounted_seconds`, `vehicle_id` (20) | no `description` | What does each column mean? | open |
| `intermediate.int_status_intervals` | `driver_id`, `interval_date`, `interval_end_ts`, `interval_hour`, `interval_id`, `interval_start_ts`, `is_negative_interval`, `is_terminal_interval`, `shift_id`, `skew_seconds`, `status_code`, `vehicle_id`, `zone_id` (13) | no `description` | What does each column mean? | open |
| `intermediate.int_trip_fare_components` | `airport_fee`, `congestion_surcharge`, `counts_as_revenue`, `extra`, `fare_amount`, `fare_residual`, `has_unexplained_residual`, `improvement_surcharge`, `measurable_tip_rate`, `mta_tax`, `pickup_date`, `service_type`, `settlement_class`, `tip_amount`, `tip_is_captured`, `tip_rate_on_fare`, `tolls_amount`, `total_amount`, `total_surcharges`, `trip_key` (20) | no `description` | What does each column mean? | open |
| `intermediate.int_trip_quality_flags` | `is_billable`, `is_implausibly_fast`, `is_implausibly_short`, `is_missing_airport_fee`, `is_missing_passenger_count`, `is_negative_duration`, `is_refund`, `is_sparse_vendor_feed`, `is_undocumented_rate_code`, `is_unresolved_dropoff_zone`, `is_unresolved_pickup_zone`, `is_zero_distance`, `is_zero_passenger`, `trip_key` (14) | no `description` | What does each column mean? | open |
| `intermediate.int_trips_conformed` | `_dlt_load_id`, `avg_mph`, `congestion_surcharge`, `dropoff_datetime`, `dropoff_location_id`, `extra`, `fare_amount`, `improvement_surcharge`, `mta_tax`, `passenger_count`, `payment_type`, `pickup_date`, `pickup_datetime`, `pickup_hour`, `rate_code_id`, `service_type`, `store_and_fwd_flag`, `tip_amount`, `tolls_amount`, `total_amount`, `trip_distance`, `trip_key`, `vendor_id` (23) | no `description` | What does each column mean? | open |
| `intermediate.int_trips_enriched` | `_dlt_load_id`, `airport_fee`, `avg_mph`, `congestion_surcharge`, `dropoff_datetime`, `dropoff_location_id`, `ehail_fee`, `extra`, `fare_amount`, `improvement_surcharge`, `mta_tax`, `passenger_count`, `payment_type`, `pickup_date`, `pickup_datetime`, `pickup_hour`, `pickup_location_id`, `rate_code_id`, `service_type`, `store_and_fwd_flag`, `tip_amount`, `tolls_amount`, `total_amount`, `trip_distance`, `trip_key`, `trip_seconds`, `trip_type`, `vendor_id` (28) | no `description` | What does each column mean? | open |
| `intermediate.int_zone_attributes` | `area_sq_mi`, `borough_code`, `borough_name`, `centroid_lat`, `centroid_lon`, `demand_tier`, `has_airport_poi`, `is_airport_zone`, `is_congestion_zone`, `is_core_market`, `is_nyc`, `location_id`, `poi_categories`, `poi_count`, `poi_demand_weight`, `reporting_region`, `resident_population`, `tlc_service_zone`, `zone_class`, `zone_name` (20) | no `description` | What does each column mean? | open |
| `mdm_raw.audit_runs` | `dataset_name`, `destination_name`, `extract_finished_at`, `extract_started_at`, `finished_at`, `first_run`, `load_finished_at`, `load_id`, `load_started_at`, `normalize_finished_at`, `normalize_started_at`, `pipeline_name`, `started_at`, `status`, `total_rows_extracted` (15) | no `description` | What does each column mean? | open |
| `mdm_raw.audit_table_loads` | `file_size`, `load_elapsed`, `load_id`, `load_state`, `rows_extracted`, `rows_normalized`, `table_name` (7) | no `description` | What does each column mean? | open |
| `mdm_raw.borough_master` | `area_sq_mi`, `borough_code`, `borough_name`, `is_core_market`, `is_nyc`, `reporting_region`, `resident_population` (7) | no `description` | What does each column mean? | open |
| `mdm_raw.calendar_master` | `calendar_date`, `holiday_class`, `holiday_name`, `is_holiday`, `is_school_term`, `is_weekend` (6) | no `description` | What does each column mean? | open |
| `mdm_raw.fare_regime_master` | `applies_to_fleet`, `fare_component`, `rate_amount`, `regime_code`, `valid_from_date`, `valid_to_date` (6) | no `description` | What does each column mean? | open |
| `mdm_raw.payment_method_master` | `counts_as_revenue`, `payment_method_name`, `payment_type_code`, `processor_fee_pct`, `settlement_class`, `settlement_days`, `tip_is_captured` (7) | no `description` | What does each column mean? | open |
| `mdm_raw.rate_plan_master` | `flat_fare_amount`, `is_airport_plan`, `is_flat_fare`, `is_metered_baseline`, `pricing_model`, `rate_code`, `rate_plan_name` (7) | no `description` | What does each column mean? | open |
| `mdm_raw.vendor_master` | `contract_tier`, `is_approved`, `source_version`, `valid_from_date`, `valid_to_date`, `vendor_id`, `vendor_legal_name`, `vendor_short_code` (8) | no `description` | What does each column mean? | open |
| `mdm_raw.weather_daily` | `borough_name`, `obs_date`, `observation_id`, `precip_inches`, `snow_inches`, `temp_avg_f`, `wind_mph` (7) | no `description` | What does each column mean? | open |
| `mdm_raw.zone_master` | `area_sq_mi`, `borough_name`, `centroid_lat`, `centroid_lon`, `demand_tier`, `is_airport_zone`, `is_congestion_zone`, `location_id`, `resident_population`, `source_version`, `tlc_service_zone`, `valid_from_date`, `valid_to_date`, `zone_class`, `zone_label` (15) | no `description` | What does each column mean? | open |
| `mdm_raw.zone_poi` | `demand_weight`, `location_id`, `poi_category`, `poi_category_name`, `poi_id`, `poi_name` (6) | no `description` | What does each column mean? | open |
| `ops.mart_driver_scorecard` | `active_days`, `driver_key`, `driver_ref`, `engagement_type`, `fleet_rank`, `garage_key`, `garage_rank`, `gross_revenue`, `home_garage_name`, `is_below_ranking_floor`, `occupancy_percentile`, `occupancy_rate`, `on_trip_hours`, `online_hours`, `paid_miles`, `revenue_per_online_hour`, `revenue_per_trip`, `revenue_quartile`, `shift_count`, `tip_revenue`, `tip_share`, `total_cost`, `total_margin`, `trip_count`, `trips_per_online_hour` (25) | no `description` | What does each column mean? | open |
| `ops.mart_trip_quality_scorecard` | `clean_rate`, `clean_trip_count`, `implausible_speed_count`, `non_billable_count`, `refund_count`, `service_type_key`, `sparse_feed_count`, `sparse_feed_rate`, `trip_count`, `trip_month`, `unbalanced_total_count`, `undocumented_rate_count`, `unresolved_zone_count`, `vendor_id`, `vendor_legal_name`, `zero_distance_count` (16) | no `description` | What does each column mean? | open |
| `ops.mart_vehicle_utilisation` | `active_days`, `availability_adjusted_rate`, `available_days`, `down_days`, `fuel_type`, `garage_key`, `garage_name`, `gross_revenue`, `is_in_service`, `is_low_emission`, `maintenance_cost`, `make_model`, `medallion_number`, `model_year`, `net_revenue_per_active_day`, `occupancy_rate`, `on_trip_hours`, `online_hours`, `paid_miles`, `revenue_per_online_hour`, `shift_count`, `trip_count`, `vehicle_key` (23) | no `description` | What does each column mean? | open |
| `ops_raw.audit_runs` | `dataset_name`, `destination_name`, `extract_finished_at`, `extract_started_at`, `finished_at`, `first_run`, `load_finished_at`, `load_id`, `load_started_at`, `normalize_finished_at`, `normalize_started_at`, `pipeline_name`, `started_at`, `status`, `total_rows_extracted` (15) | no `description` | What does each column mean? | open |
| `ops_raw.audit_table_loads` | `file_size`, `load_elapsed`, `load_id`, `load_state`, `rows_extracted`, `rows_normalized`, `table_name` (7) | no `description` | What does each column mean? | open |
| `ops_raw.driver` | `driver_id`, `driver_ref`, `driver_status`, `engagement_type`, `hack_licence_no`, `hire_date`, `home_garage_id`, `is_wav_certified`, `termination_date` (9) | no `description` | What does each column mean? | open |
| `ops_raw.driver_status_event` | `driver_id`, `event_id`, `event_ts`, `received_ts`, `shift_id`, `source_system`, `status_code`, `vehicle_id`, `zone_id` (9) | no `description` | What does each column mean? | open |
| `ops_raw.garage` | `bay_capacity`, `borough`, `garage_id`, `garage_name`, `opened_date` (5) | no `description` | What does each column mean? | open |
| `ops_raw.lease_agreement` | `driver_id`, `lease_end_date`, `lease_id`, `lease_rate`, `lease_start_date`, `lease_type`, `primary_vehicle_id`, `revenue_share_pct` (8) | no `description` | What does each column mean? | open |
| `ops_raw.maintenance_event` | `cost_usd`, `down_days`, `maintenance_id`, `maintenance_type`, `started_date`, `vehicle_id` (6) | no `description` | What does each column mean? | open |
| `ops_raw.shift` | `derived_end_ts`, `driver_id`, `odometer_end`, `odometer_start`, `reported_trip_count`, `shift_end_ts`, `shift_id`, `shift_start_ts`, `telematics_source`, `vehicle_id` (10) | no `description` | What does each column mean? | open |
| `ops_raw.trip_assignment` | `assigned_ts`, `assignment_id`, `assignment_method`, `driver_id`, `dropoff_datetime`, `dropoff_location_id`, `pickup_datetime`, `pickup_location_id`, `service_type`, `shift_id`, `total_amount`, `trip_distance`, `vehicle_id`, `vendor_id` (14) | no `description` | What does each column mean? | open |
| `ops_raw.vehicle` | `fuel_type`, `garage_id`, `in_service_date`, `make`, `medallion_number`, `model`, `model_year`, `retired_date`, `vehicle_id`, `vin`, `wheelchair_accessible` (11) | no `description` | What does each column mean? | open |
| `seeds.daypart_bands` | `daypart_code`, `daypart_name`, `hour_of_day`, `is_peak` (4) | no `description` | What does each column mean? | open |
| `seeds.distance_bands` | `band_order`, `distance_band`, `max_miles`, `min_miles` (4) | no `description` | What does each column mean? | open |
| `seeds.duration_bands` | `band_order`, `duration_band`, `max_minutes`, `min_minutes` (4) | no `description` | What does each column mean? | open |
| `seeds.fare_bands` | `band_order`, `fare_band`, `max_total`, `min_total` (4) | no `description` | What does each column mean? | open |
| `staging.stg_mdm__boroughs` | `area_sq_mi`, `borough_code`, `borough_name`, `is_core_market`, `is_nyc`, `reporting_region`, `resident_population` (7) | no `description` | What does each column mean? | open |
| `staging.stg_mdm__calendar` | `calendar_date`, `holiday_class`, `holiday_name`, `is_holiday`, `is_school_term`, `is_weekend` (6) | no `description` | What does each column mean? | open |
| `staging.stg_mdm__fare_regimes` | `applies_to_fleet`, `fare_component`, `rate_amount`, `regime_code`, `valid_from_date`, `valid_to_date` (6) | no `description` | What does each column mean? | open |
| `staging.stg_mdm__payment_methods` | `counts_as_revenue`, `payment_method_name`, `payment_type`, `processor_fee_pct`, `settlement_class`, `settlement_days`, `tip_is_captured` (7) | no `description` | What does each column mean? | open |
| `staging.stg_mdm__rate_plans` | `flat_fare_amount`, `is_airport_plan`, `is_flat_fare`, `is_metered_baseline`, `pricing_model`, `rate_code_id`, `rate_plan_name` (7) | no `description` | What does each column mean? | open |
| `staging.stg_mdm__vendors` | `contract_tier`, `is_approved`, `source_version`, `valid_from_date`, `valid_to_date`, `vendor_id`, `vendor_legal_name`, `vendor_short_code` (8) | no `description` | What does each column mean? | open |
| `staging.stg_mdm__weather` | `borough_name`, `is_snow_day`, `is_wet_day`, `obs_date`, `observation_id`, `precip_inches`, `snow_inches`, `temp_avg_f`, `wind_mph` (9) | no `description` | What does each column mean? | open |
| `staging.stg_mdm__zone_poi` | `demand_weight`, `location_id`, `poi_category`, `poi_category_name`, `poi_id`, `poi_name` (6) | no `description` | What does each column mean? | open |
| `staging.stg_mdm__zones` | `_dlt_load_id`, `area_sq_mi`, `borough_name`, `centroid_lat`, `centroid_lon`, `demand_tier`, `is_airport_zone`, `is_congestion_zone`, `location_id`, `resident_population`, `source_version`, `tlc_service_zone`, `valid_from_date`, `valid_to_date`, `zone_class`, `zone_name` (16) | no `description` | What does each column mean? | open |
| `staging.stg_ops__drivers` | `driver_id`, `driver_ref`, `driver_status`, `engagement_type`, `hack_licence_no`, `hire_date`, `home_garage_id`, `is_wav_certified`, `termination_date` (9) | no `description` | What does each column mean? | open |
| `staging.stg_ops__garages` | `bay_capacity`, `borough_name`, `garage_id`, `garage_name`, `opened_date` (5) | no `description` | What does each column mean? | open |
| `staging.stg_ops__leases` | `driver_id`, `lease_end_date`, `lease_id`, `lease_rate`, `lease_start_date`, `lease_type`, `primary_vehicle_id`, `revenue_share_pct` (8) | no `description` | What does each column mean? | open |
| `staging.stg_ops__maintenance` | `cost_usd`, `down_days`, `ended_date`, `maintenance_id`, `maintenance_type`, `started_date`, `vehicle_id` (7) | no `description` | What does each column mean? | open |
| `staging.stg_ops__shifts` | `derived_end_ts`, `driver_id`, `effective_end_ts`, `is_unclosed_shift`, `odometer_end`, `odometer_miles`, `odometer_start`, `reported_trip_count`, `shift_date`, `shift_end_ts`, `shift_id`, `shift_seconds`, `shift_start_ts`, `telematics_source`, `vehicle_id` (15) | no `description` | What does each column mean? | open |
| `staging.stg_ops__status_events` | `driver_id`, `event_id`, `event_ts`, `is_available_status`, `is_occupied_status`, `received_ts`, `shift_id`, `skew_seconds`, `source_system`, `status_code`, `vehicle_id`, `zone_id` (12) | no `description` | What does each column mean? | open |
| `staging.stg_ops__trip_assignments` | `assigned_ts`, `assignment_id`, `assignment_method`, `driver_id`, `shift_id`, `trip_key`, `vehicle_id` (7) | no `description` | What does each column mean? | open |
| `staging.stg_ops__vehicles` | `fuel_type`, `garage_id`, `in_service_date`, `is_in_service`, `make`, `medallion_number`, `model`, `model_year`, `retired_date`, `vehicle_id`, `vin`, `wheelchair_accessible` (12) | no `description` | What does each column mean? | open |
| `staging.stg_tlc__green_trip_extras` | `ehail_fee`, `pickup_datetime`, `trip_key`, `trip_type` (4) | no `description` | What does each column mean? | open |
| `staging.stg_tlc__green_tripdata` | `_dlt_load_id`, `congestion_surcharge`, `dropoff_datetime`, `dropoff_location_id`, `ehail_fee`, `extra`, `fare_amount`, `improvement_surcharge`, `mta_tax`, `passenger_count`, `payment_type`, `pickup_datetime`, `pickup_location_id`, `rate_code_id`, `store_and_fwd_flag`, `tip_amount`, `tolls_amount`, `total_amount`, `trip_distance`, `trip_type`, `vendor_id` (21) | no `description` | What does each column mean? | open |
| `staging.stg_tlc__yellow_trip_extras` | `pickup_datetime`, `pickup_location_id`, `trip_key` (3) | no `description` | What does each column mean? | open |
| `staging.stg_tlc__yellow_tripdata` | `_dlt_load_id`, `airport_fee`, `congestion_surcharge`, `dropoff_datetime`, `dropoff_location_id`, `extra`, `fare_amount`, `improvement_surcharge`, `mta_tax`, `passenger_count`, `payment_type`, `pickup_datetime`, `pickup_location_id`, `rate_code_id`, `store_and_fwd_flag`, `tip_amount`, `tolls_amount`, `total_amount`, `trip_distance`, `vendor_id` (20) | no `description` | What does each column mean? | open |

## 3. Nullable with no evidence either way

127 columns admit nulls, hold at least one, and carry no rule that says whether that is allowed. The data settles that a null occurs; only the business settles whether it may. The alternative — a column the data never nulls — is not listed: the null rate is the evidence, and zero is an answer.

| Column | Evidence | Question | Status |
| --- | --- | --- | --- |
| `agg.agg_driver_daily.revenue_per_trip` | 20,622 of 32,153 rows are null and no rule settles whether that is allowed | Is revenue_per_trip required, or is a null a real state? | open |
| `agg.agg_driver_monthly.margin_rate` | 1,486 of 2,354 rows are null and no rule settles whether that is allowed | Is margin_rate required, or is a null a real state? | open |
| `agg.agg_trip_band_profile.avg_measurable_tip_rate` | 1,036 of 4,577 rows are null and no rule settles whether that is allowed | Is avg_measurable_tip_rate required, or is a null a real state? | open |
| `agg.agg_trip_zone_daily.prev_day_trip_count` | 260 of 7,017 rows are null and no rule settles whether that is allowed | Is prev_day_trip_count required, or is a null a real state? | open |
| `agg.agg_trip_zone_daily.same_day_last_week_trip_count` | 1,719 of 7,017 rows are null and no rule settles whether that is allowed | Is same_day_last_week_trip_count required, or is a null a real state? | open |
| `agg.agg_trip_zone_daypart_dow.avg_measurable_tip_rate` | 1,372 of 14,446 rows are null and no rule settles whether that is allowed | Is avg_measurable_tip_rate required, or is a null a real state? | open |
| `agg.agg_vehicle_daily.odometer_miles` | 580 of 33,893 rows are null and no rule settles whether that is allowed | Is odometer_miles required, or is a null a real state? | open |
| `agg.agg_vehicle_daily.paid_mile_ratio` | 585 of 33,893 rows are null and no rule settles whether that is allowed | Is paid_mile_ratio required, or is a null a real state? | open |
| `agg.agg_weather_demand_daily.avg_fare` | 572 of 819 rows are null and no rule settles whether that is allowed | Is avg_fare required, or is a null a real state? | open |
| `agg.agg_weather_demand_daily.avg_paid_hours_per_trip` | 572 of 819 rows are null and no rule settles whether that is allowed | Is avg_paid_hours_per_trip required, or is a null a real state? | open |
| `agg.agg_weather_demand_daily.avg_trip_distance` | 572 of 819 rows are null and no rule settles whether that is allowed | Is avg_trip_distance required, or is a null a real state? | open |
| `agg.agg_weather_demand_daily.is_snow_day` | 273 of 819 rows are null and no rule settles whether that is allowed | Is is_snow_day required, or is a null a real state? | open |
| `agg.agg_weather_demand_daily.is_wet_day` | 273 of 819 rows are null and no rule settles whether that is allowed | Is is_wet_day required, or is a null a real state? | open |
| `agg.agg_weather_demand_daily.precip_inches` | 273 of 819 rows are null and no rule settles whether that is allowed | Is precip_inches required, or is a null a real state? | open |
| `agg.agg_weather_demand_daily.snow_inches` | 273 of 819 rows are null and no rule settles whether that is allowed | Is snow_inches required, or is a null a real state? | open |
| `agg.agg_weather_demand_daily.temp_avg_f` | 273 of 819 rows are null and no rule settles whether that is allowed | Is temp_avg_f required, or is a null a real state? | open |
| `agg.agg_weather_demand_daily.total_revenue` | 572 of 819 rows are null and no rule settles whether that is allowed | Is total_revenue required, or is a null a real state? | open |
| `agg.agg_zone_occupancy_hourly.available_hours` | 21,594 of 150,479 rows are null and no rule settles whether that is allowed | Is available_hours required, or is a null a real state? | open |
| `agg.agg_zone_occupancy_hourly.break_hours` | 45,108 of 150,479 rows are null and no rule settles whether that is allowed | Is break_hours required, or is a null a real state? | open |
| `agg.agg_zone_occupancy_hourly.on_trip_hours` | 50,457 of 150,479 rows are null and no rule settles whether that is allowed | Is on_trip_hours required, or is a null a real state? | open |
| `agg.agg_zone_occupancy_hourly.zone_occupancy_rate` | 50,457 of 150,479 rows are null and no rule settles whether that is allowed | Is zone_occupancy_rate required, or is a null a real state? | open |
| `bronze.green_tripdata.RatecodeID` | 3,415 of 56,551 rows are null and no rule settles whether that is allowed | Is RatecodeID required, or is a null a real state? | open |
| `bronze.green_tripdata.congestion_surcharge` | 3,415 of 56,551 rows are null and no rule settles whether that is allowed | Is congestion_surcharge required, or is a null a real state? | open |
| `bronze.green_tripdata.ehail_fee` | 56,551 of 56,551 rows are null and no rule settles whether that is allowed | Is ehail_fee required, or is a null a real state? | open |
| `bronze.green_tripdata.passenger_count` | 3,415 of 56,551 rows are null and no rule settles whether that is allowed | Is passenger_count required, or is a null a real state? | open |
| `bronze.green_tripdata.payment_type` | 3,415 of 56,551 rows are null and no rule settles whether that is allowed | Is payment_type required, or is a null a real state? | open |
| `bronze.green_tripdata.store_and_fwd_flag` | 3,415 of 56,551 rows are null and no rule settles whether that is allowed | Is store_and_fwd_flag required, or is a null a real state? | open |
| `bronze.green_tripdata.trip_type` | 3,418 of 56,551 rows are null and no rule settles whether that is allowed | Is trip_type required, or is a null a real state? | open |
| `bronze.yellow_tripdata.Airport_fee` | 140,162 of 2,964,624 rows are null and no rule settles whether that is allowed | Is Airport_fee required, or is a null a real state? | open |
| `bronze.yellow_tripdata.RatecodeID` | 140,162 of 2,964,624 rows are null and no rule settles whether that is allowed | Is RatecodeID required, or is a null a real state? | open |
| `bronze.yellow_tripdata.congestion_surcharge` | 140,162 of 2,964,624 rows are null and no rule settles whether that is allowed | Is congestion_surcharge required, or is a null a real state? | open |
| `bronze.yellow_tripdata.passenger_count` | 140,162 of 2,964,624 rows are null and no rule settles whether that is allowed | Is passenger_count required, or is a null a real state? | open |
| `bronze.yellow_tripdata.store_and_fwd_flag` | 140,162 of 2,964,624 rows are null and no rule settles whether that is allowed | Is store_and_fwd_flag required, or is a null a real state? | open |
| `core.dim_date.holiday_class` | 386 of 397 rows are null and no rule settles whether that is allowed | Is holiday_class required, or is a null a real state? | open |
| `core.dim_date.holiday_name` | 386 of 397 rows are null and no rule settles whether that is allowed | Is holiday_name required, or is a null a real state? | open |
| `core.dim_driver.termination_date` | 736 of 760 rows are null and no rule settles whether that is allowed | Is termination_date required, or is a null a real state? | open |
| `core.dim_rate_plan.flat_fare_amount` | 6 of 7 rows are null and no rule settles whether that is allowed | Is flat_fare_amount required, or is a null a real state? | open |
| `core.dim_trip_quality.is_undocumented_rate_code` | 25 of 89 rows are null and no rule settles whether that is allowed | Is is_undocumented_rate_code required, or is a null a real state? | open |
| `core.dim_trip_quality.is_zero_passenger` | 25 of 89 rows are null and no rule settles whether that is allowed | Is is_zero_passenger required, or is a null a real state? | open |
| `core.dim_vehicle.retired_date` | 412 of 420 rows are null and no rule settles whether that is allowed | Is retired_date required, or is a null a real state? | open |
| `core.dim_zone.poi_categories` | 96 of 272 rows are null and no rule settles whether that is allowed | Is poi_categories required, or is a null a real state? | open |
| `core.fct_shift.odometer_miles` | 736 of 38,205 rows are null and no rule settles whether that is allowed | Is odometer_miles required, or is a null a real state? | open |
| `core.fct_shift.paid_mile_ratio` | 870 of 38,205 rows are null and no rule settles whether that is allowed | Is paid_mile_ratio required, or is a null a real state? | open |
| `core.fct_shift.revenue_per_paid_mile` | 24,195 of 38,205 rows are null and no rule settles whether that is allowed | Is revenue_per_paid_mile required, or is a null a real state? | open |
| `core.fct_status_interval.zone_key` | 113,997 of 1,807,117 rows are null and no rule settles whether that is allowed | Is zone_key required, or is a null a real state? | open |
| `core.fct_status_interval.zone_natural_key` | 113,997 of 1,807,117 rows are null and no rule settles whether that is allowed | Is zone_natural_key required, or is a null a real state? | open |
| `core.fct_trip.airport_fee` | 196,713 of 3,021,175 rows are null and no rule settles whether that is allowed | Is airport_fee required, or is a null a real state? | open |
| `core.fct_trip.assignment_method` | 2,873,741 of 3,021,175 rows are null and no rule settles whether that is allowed | Is assignment_method required, or is a null a real state? | open |
| `core.fct_trip.avg_mph` | 890 of 3,021,175 rows are null and no rule settles whether that is allowed | Is avg_mph required, or is a null a real state? | open |
| `core.fct_trip.congestion_surcharge` | 143,577 of 3,021,175 rows are null and no rule settles whether that is allowed | Is congestion_surcharge required, or is a null a real state? | open |
| `core.fct_trip.driver_key` | 2,873,741 of 3,021,175 rows are null and no rule settles whether that is allowed | Is driver_key required, or is a null a real state? | open |
| `core.fct_trip.dropoff_zone_key` | 5 of 3,021,175 rows are null and no rule settles whether that is allowed | Is dropoff_zone_key required, or is a null a real state? | open |
| `core.fct_trip.ehail_fee` | 3,021,175 of 3,021,175 rows are null and no rule settles whether that is allowed | Is ehail_fee required, or is a null a real state? | open |
| `core.fct_trip.measurable_tip_rate` | 525,546 of 3,021,175 rows are null and no rule settles whether that is allowed | Is measurable_tip_rate required, or is a null a real state? | open |
| `core.fct_trip.passenger_count` | 143,577 of 3,021,175 rows are null and no rule settles whether that is allowed | Is passenger_count required, or is a null a real state? | open |
| `core.fct_trip.payment_method_key` | 3,415 of 3,021,175 rows are null and no rule settles whether that is allowed | Is payment_method_key required, or is a null a real state? | open |
| `core.fct_trip.pickup_date_key` | 5 of 3,021,175 rows are null and no rule settles whether that is allowed | Is pickup_date_key required, or is a null a real state? | open |
| `core.fct_trip.pickup_zone_key` | 5 of 3,021,175 rows are null and no rule settles whether that is allowed | Is pickup_zone_key required, or is a null a real state? | open |
| `core.fct_trip.rate_plan_key` | 143,577 of 3,021,175 rows are null and no rule settles whether that is allowed | Is rate_plan_key required, or is a null a real state? | open |
| `core.fct_trip.shift_id` | 2,873,741 of 3,021,175 rows are null and no rule settles whether that is allowed | Is shift_id required, or is a null a real state? | open |
| `core.fct_trip.store_and_fwd_flag` | 143,577 of 3,021,175 rows are null and no rule settles whether that is allowed | Is store_and_fwd_flag required, or is a null a real state? | open |
| `core.fct_trip.trip_type` | 2,968,042 of 3,021,175 rows are null and no rule settles whether that is allowed | Is trip_type required, or is a null a real state? | open |
| `core.fct_trip.vehicle_key` | 2,873,741 of 3,021,175 rows are null and no rule settles whether that is allowed | Is vehicle_key required, or is a null a real state? | open |
| `core.fct_trip.vendor_key` | 5 of 3,021,175 rows are null and no rule settles whether that is allowed | Is vendor_key required, or is a null a real state? | open |
| `intermediate.int_shift_economics.revenue_per_paid_mile` | 24,195 of 38,205 rows are null and no rule settles whether that is allowed | Is revenue_per_paid_mile required, or is a null a real state? | open |
| `intermediate.int_shift_occupancy.odometer_miles` | 736 of 38,205 rows are null and no rule settles whether that is allowed | Is odometer_miles required, or is a null a real state? | open |
| `intermediate.int_status_intervals.zone_id` | 113,997 of 1,807,117 rows are null and no rule settles whether that is allowed | Is zone_id required, or is a null a real state? | open |
| `intermediate.int_trip_fare_components.congestion_surcharge` | 143,577 of 3,021,175 rows are null and no rule settles whether that is allowed | Is congestion_surcharge required, or is a null a real state? | open |
| `intermediate.int_trip_fare_components.counts_as_revenue` | 3,415 of 3,021,175 rows are null and no rule settles whether that is allowed | Is counts_as_revenue required, or is a null a real state? | open |
| `intermediate.int_trip_fare_components.measurable_tip_rate` | 525,546 of 3,021,175 rows are null and no rule settles whether that is allowed | Is measurable_tip_rate required, or is a null a real state? | open |
| `intermediate.int_trip_fare_components.settlement_class` | 3,415 of 3,021,175 rows are null and no rule settles whether that is allowed | Is settlement_class required, or is a null a real state? | open |
| `intermediate.int_trip_fare_components.tip_is_captured` | 3,415 of 3,021,175 rows are null and no rule settles whether that is allowed | Is tip_is_captured required, or is a null a real state? | open |
| `intermediate.int_trip_fare_components.tip_rate_on_fare` | 945 of 3,021,175 rows are null and no rule settles whether that is allowed | Is tip_rate_on_fare required, or is a null a real state? | open |
| `intermediate.int_trip_quality_flags.is_undocumented_rate_code` | 143,577 of 3,021,175 rows are null and no rule settles whether that is allowed | Is is_undocumented_rate_code required, or is a null a real state? | open |
| `intermediate.int_trip_quality_flags.is_zero_passenger` | 143,577 of 3,021,175 rows are null and no rule settles whether that is allowed | Is is_zero_passenger required, or is a null a real state? | open |
| `intermediate.int_trips_conformed.avg_mph` | 890 of 3,021,175 rows are null and no rule settles whether that is allowed | Is avg_mph required, or is a null a real state? | open |
| `intermediate.int_trips_conformed.congestion_surcharge` | 143,577 of 3,021,175 rows are null and no rule settles whether that is allowed | Is congestion_surcharge required, or is a null a real state? | open |
| `intermediate.int_trips_conformed.passenger_count` | 143,577 of 3,021,175 rows are null and no rule settles whether that is allowed | Is passenger_count required, or is a null a real state? | open |
| `intermediate.int_trips_conformed.payment_type` | 3,415 of 3,021,175 rows are null and no rule settles whether that is allowed | Is payment_type required, or is a null a real state? | open |
| `intermediate.int_trips_conformed.rate_code_id` | 143,577 of 3,021,175 rows are null and no rule settles whether that is allowed | Is rate_code_id required, or is a null a real state? | open |
| `intermediate.int_trips_conformed.store_and_fwd_flag` | 143,577 of 3,021,175 rows are null and no rule settles whether that is allowed | Is store_and_fwd_flag required, or is a null a real state? | open |
| `intermediate.int_trips_enriched.airport_fee` | 196,713 of 3,021,175 rows are null and no rule settles whether that is allowed | Is airport_fee required, or is a null a real state? | open |
| `intermediate.int_trips_enriched.avg_mph` | 890 of 3,021,175 rows are null and no rule settles whether that is allowed | Is avg_mph required, or is a null a real state? | open |
| `intermediate.int_trips_enriched.congestion_surcharge` | 143,577 of 3,021,175 rows are null and no rule settles whether that is allowed | Is congestion_surcharge required, or is a null a real state? | open |
| `intermediate.int_trips_enriched.ehail_fee` | 3,021,175 of 3,021,175 rows are null and no rule settles whether that is allowed | Is ehail_fee required, or is a null a real state? | open |
| `intermediate.int_trips_enriched.passenger_count` | 143,577 of 3,021,175 rows are null and no rule settles whether that is allowed | Is passenger_count required, or is a null a real state? | open |
| `intermediate.int_trips_enriched.payment_type` | 3,415 of 3,021,175 rows are null and no rule settles whether that is allowed | Is payment_type required, or is a null a real state? | open |
| `intermediate.int_trips_enriched.rate_code_id` | 143,577 of 3,021,175 rows are null and no rule settles whether that is allowed | Is rate_code_id required, or is a null a real state? | open |
| `intermediate.int_trips_enriched.store_and_fwd_flag` | 143,577 of 3,021,175 rows are null and no rule settles whether that is allowed | Is store_and_fwd_flag required, or is a null a real state? | open |
| `intermediate.int_trips_enriched.trip_type` | 2,968,042 of 3,021,175 rows are null and no rule settles whether that is allowed | Is trip_type required, or is a null a real state? | open |
| `intermediate.int_zone_attributes.poi_categories` | 92 of 265 rows are null and no rule settles whether that is allowed | Is poi_categories required, or is a null a real state? | open |
| `mdm_raw.calendar_master.holiday_class` | 386 of 397 rows are null and no rule settles whether that is allowed | Is holiday_class required, or is a null a real state? | open |
| `mdm_raw.calendar_master.holiday_name` | 386 of 397 rows are null and no rule settles whether that is allowed | Is holiday_name required, or is a null a real state? | open |
| `mdm_raw.rate_plan_master.flat_fare_amount` | 6 of 7 rows are null and no rule settles whether that is allowed | Is flat_fare_amount required, or is a null a real state? | open |
| `ops.mart_driver_scorecard.revenue_per_trip` | 7 of 760 rows are null and no rule settles whether that is allowed | Is revenue_per_trip required, or is a null a real state? | open |
| `ops.mart_driver_scorecard.tip_share` | 7 of 760 rows are null and no rule settles whether that is allowed | Is tip_share required, or is a null a real state? | open |
| `ops_raw.driver.termination_date` | 736 of 760 rows are null and no rule settles whether that is allowed | Is termination_date required, or is a null a real state? | open |
| `ops_raw.driver_status_event.zone_id` | 113,997 of 1,807,117 rows are null and no rule settles whether that is allowed | Is zone_id required, or is a null a real state? | open |
| `ops_raw.lease_agreement.lease_end_date` | 736 of 760 rows are null and no rule settles whether that is allowed | Is lease_end_date required, or is a null a real state? | open |
| `ops_raw.shift.odometer_end` | 736 of 38,205 rows are null and no rule settles whether that is allowed | Is odometer_end required, or is a null a real state? | open |
| `ops_raw.shift.shift_end_ts` | 618 of 38,205 rows are null and no rule settles whether that is allowed | Is shift_end_ts required, or is a null a real state? | open |
| `ops_raw.vehicle.retired_date` | 412 of 420 rows are null and no rule settles whether that is allowed | Is retired_date required, or is a null a real state? | open |
| `staging.stg_mdm__calendar.holiday_class` | 386 of 397 rows are null and no rule settles whether that is allowed | Is holiday_class required, or is a null a real state? | open |
| `staging.stg_mdm__calendar.holiday_name` | 386 of 397 rows are null and no rule settles whether that is allowed | Is holiday_name required, or is a null a real state? | open |
| `staging.stg_mdm__rate_plans.flat_fare_amount` | 6 of 7 rows are null and no rule settles whether that is allowed | Is flat_fare_amount required, or is a null a real state? | open |
| `staging.stg_ops__drivers.termination_date` | 736 of 760 rows are null and no rule settles whether that is allowed | Is termination_date required, or is a null a real state? | open |
| `staging.stg_ops__leases.lease_end_date` | 736 of 760 rows are null and no rule settles whether that is allowed | Is lease_end_date required, or is a null a real state? | open |
| `staging.stg_ops__shifts.odometer_end` | 736 of 38,205 rows are null and no rule settles whether that is allowed | Is odometer_end required, or is a null a real state? | open |
| `staging.stg_ops__shifts.odometer_miles` | 736 of 38,205 rows are null and no rule settles whether that is allowed | Is odometer_miles required, or is a null a real state? | open |
| `staging.stg_ops__shifts.shift_end_ts` | 618 of 38,205 rows are null and no rule settles whether that is allowed | Is shift_end_ts required, or is a null a real state? | open |
| `staging.stg_ops__status_events.zone_id` | 113,997 of 1,807,117 rows are null and no rule settles whether that is allowed | Is zone_id required, or is a null a real state? | open |
| `staging.stg_ops__vehicles.retired_date` | 412 of 420 rows are null and no rule settles whether that is allowed | Is retired_date required, or is a null a real state? | open |
| `staging.stg_tlc__green_trip_extras.ehail_fee` | 56,551 of 56,551 rows are null and no rule settles whether that is allowed | Is ehail_fee required, or is a null a real state? | open |
| `staging.stg_tlc__green_trip_extras.trip_type` | 3,418 of 56,551 rows are null and no rule settles whether that is allowed | Is trip_type required, or is a null a real state? | open |
| `staging.stg_tlc__green_tripdata.congestion_surcharge` | 3,415 of 56,551 rows are null and no rule settles whether that is allowed | Is congestion_surcharge required, or is a null a real state? | open |
| `staging.stg_tlc__green_tripdata.ehail_fee` | 56,551 of 56,551 rows are null and no rule settles whether that is allowed | Is ehail_fee required, or is a null a real state? | open |
| `staging.stg_tlc__green_tripdata.passenger_count` | 3,415 of 56,551 rows are null and no rule settles whether that is allowed | Is passenger_count required, or is a null a real state? | open |
| `staging.stg_tlc__green_tripdata.payment_type` | 3,415 of 56,551 rows are null and no rule settles whether that is allowed | Is payment_type required, or is a null a real state? | open |
| `staging.stg_tlc__green_tripdata.rate_code_id` | 3,415 of 56,551 rows are null and no rule settles whether that is allowed | Is rate_code_id required, or is a null a real state? | open |
| `staging.stg_tlc__green_tripdata.store_and_fwd_flag` | 3,415 of 56,551 rows are null and no rule settles whether that is allowed | Is store_and_fwd_flag required, or is a null a real state? | open |
| `staging.stg_tlc__green_tripdata.trip_type` | 3,418 of 56,551 rows are null and no rule settles whether that is allowed | Is trip_type required, or is a null a real state? | open |
| `staging.stg_tlc__yellow_trip_extras.airport_fee` | 140,162 of 2,964,624 rows are null and no rule settles whether that is allowed | Is airport_fee required, or is a null a real state? | open |
| `staging.stg_tlc__yellow_tripdata.airport_fee` | 140,162 of 2,964,624 rows are null and no rule settles whether that is allowed | Is airport_fee required, or is a null a real state? | open |
| `staging.stg_tlc__yellow_tripdata.congestion_surcharge` | 140,162 of 2,964,624 rows are null and no rule settles whether that is allowed | Is congestion_surcharge required, or is a null a real state? | open |
| `staging.stg_tlc__yellow_tripdata.passenger_count` | 140,162 of 2,964,624 rows are null and no rule settles whether that is allowed | Is passenger_count required, or is a null a real state? | open |
| `staging.stg_tlc__yellow_tripdata.rate_code_id` | 140,162 of 2,964,624 rows are null and no rule settles whether that is allowed | Is rate_code_id required, or is a null a real state? | open |
| `staging.stg_tlc__yellow_tripdata.store_and_fwd_flag` | 140,162 of 2,964,624 rows are null and no rule settles whether that is allowed | Is store_and_fwd_flag required, or is a null a real state? | open |

## 4. Candidate key that repeats in the data

45 columns are named or declared as a key — a `_key` or `_natural_key` suffix, or the canonical model's `primary_key` — and hold duplicate values. Either the relation's grain is a combination these columns are only part of, or the column is a repeated reference. The data answers which combination is unique; the model answers what to call it. A repeated reference is also a foreign key nobody declared, so each row asks what it targets as well.

| Column | Evidence | Question | Status |
| --- | --- | --- | --- |
| `agg.agg_driver_daily.date_key` | 32,061 duplicate value(s) across 32,153 non-null rows under a key name | Which column(s) identify one row of agg_driver_daily, and is date_key one of them or a repeated reference — if a reference, what does it target? | open |
| `agg.agg_driver_daily.driver_key` | 31,393 duplicate value(s) across 32,153 non-null rows under a key name | Which column(s) identify one row of agg_driver_daily, and is driver_key one of them or a repeated reference — if a reference, what does it target? | open |
| `agg.agg_driver_daily.garage_key` | 32,147 duplicate value(s) across 32,153 non-null rows under a key name | Which column(s) identify one row of agg_driver_daily, and is garage_key one of them or a repeated reference — if a reference, what does it target? | open |
| `agg.agg_driver_monthly.driver_key` | 1,594 duplicate value(s) across 2,354 non-null rows under a key name | Which column(s) identify one row of agg_driver_monthly, and is driver_key one of them or a repeated reference — if a reference, what does it target? | open |
| `agg.agg_driver_monthly.garage_key` | 2,348 duplicate value(s) across 2,354 non-null rows under a key name | Which column(s) identify one row of agg_driver_monthly, and is garage_key one of them or a repeated reference — if a reference, what does it target? | open |
| `agg.agg_garage_monthly.garage_key` | 18 duplicate value(s) across 24 non-null rows under a key name | Which column(s) identify one row of agg_garage_monthly, and is garage_key one of them or a repeated reference — if a reference, what does it target? | open |
| `agg.agg_trip_band_profile.service_type_key` | 4,575 duplicate value(s) across 4,577 non-null rows under a key name | Which column(s) identify one row of agg_trip_band_profile, and is service_type_key one of them or a repeated reference — if a reference, what does it target? | open |
| `agg.agg_trip_zone_daily.pickup_date_key` | 6,985 duplicate value(s) across 7,017 non-null rows under a key name | Which column(s) identify one row of agg_trip_zone_daily, and is pickup_date_key one of them or a repeated reference — if a reference, what does it target? | open |
| `agg.agg_trip_zone_daypart_dow.service_type_key` | 14,444 duplicate value(s) across 14,446 non-null rows under a key name | Which column(s) identify one row of agg_trip_zone_daypart_dow, and is service_type_key one of them or a repeated reference — if a reference, what does it target? | open |
| `agg.agg_vehicle_daily.date_key` | 33,801 duplicate value(s) across 33,893 non-null rows under a key name | Which column(s) identify one row of agg_vehicle_daily, and is date_key one of them or a repeated reference — if a reference, what does it target? | open |
| `agg.agg_vehicle_daily.garage_key` | 33,887 duplicate value(s) across 33,893 non-null rows under a key name | Which column(s) identify one row of agg_vehicle_daily, and is garage_key one of them or a repeated reference — if a reference, what does it target? | open |
| `agg.agg_vehicle_daily.vehicle_key` | 33,473 duplicate value(s) across 33,893 non-null rows under a key name | Which column(s) identify one row of agg_vehicle_daily, and is vehicle_key one of them or a repeated reference — if a reference, what does it target? | open |
| `agg.agg_vehicle_monthly.garage_key` | 1,370 duplicate value(s) across 1,376 non-null rows under a key name | Which column(s) identify one row of agg_vehicle_monthly, and is garage_key one of them or a repeated reference — if a reference, what does it target? | open |
| `agg.agg_vehicle_monthly.vehicle_key` | 956 duplicate value(s) across 1,376 non-null rows under a key name | Which column(s) identify one row of agg_vehicle_monthly, and is vehicle_key one of them or a repeated reference — if a reference, what does it target? | open |
| `core.bridge_zone_poi.zone_natural_key` | 99 duplicate value(s) across 272 non-null rows under a key name | Which column(s) identify one row of bridge_zone_poi, and is zone_natural_key one of them or a repeated reference — if a reference, what does it target? | open |
| `core.dim_driver.garage_key` | 754 duplicate value(s) across 760 non-null rows under a key name | Which column(s) identify one row of dim_driver, and is garage_key one of them or a repeated reference — if a reference, what does it target? | open |
| `core.dim_vehicle.garage_key` | 414 duplicate value(s) across 420 non-null rows under a key name | Which column(s) identify one row of dim_vehicle, and is garage_key one of them or a repeated reference — if a reference, what does it target? | open |
| `core.dim_vendor.vendor_natural_key` | 1 duplicate value(s) across 5 non-null rows under a key name | Which column(s) identify one row of dim_vendor, and is vendor_natural_key one of them or a repeated reference — if a reference, what does it target? | open |
| `core.dim_zone.zone_natural_key` | 7 duplicate value(s) across 272 non-null rows under a key name | Which column(s) identify one row of dim_zone, and is zone_natural_key one of them or a repeated reference — if a reference, what does it target? | open |
| `core.fct_maintenance.garage_key` | 842 duplicate value(s) across 848 non-null rows under a key name | Which column(s) identify one row of fct_maintenance, and is garage_key one of them or a repeated reference — if a reference, what does it target? | open |
| `core.fct_maintenance.started_date_key` | 758 duplicate value(s) across 848 non-null rows under a key name | Which column(s) identify one row of fct_maintenance, and is started_date_key one of them or a repeated reference — if a reference, what does it target? | open |
| `core.fct_maintenance.vehicle_key` | 437 duplicate value(s) across 848 non-null rows under a key name | Which column(s) identify one row of fct_maintenance, and is vehicle_key one of them or a repeated reference — if a reference, what does it target? | open |
| `core.fct_shift.driver_key` | 37,445 duplicate value(s) across 38,205 non-null rows under a key name | Which column(s) identify one row of fct_shift, and is driver_key one of them or a repeated reference — if a reference, what does it target? | open |
| `core.fct_shift.garage_key` | 38,199 duplicate value(s) across 38,205 non-null rows under a key name | Which column(s) identify one row of fct_shift, and is garage_key one of them or a repeated reference — if a reference, what does it target? | open |
| `core.fct_shift.shift_date_key` | 38,113 duplicate value(s) across 38,205 non-null rows under a key name | Which column(s) identify one row of fct_shift, and is shift_date_key one of them or a repeated reference — if a reference, what does it target? | open |
| `core.fct_shift.vehicle_key` | 37,785 duplicate value(s) across 38,205 non-null rows under a key name | Which column(s) identify one row of fct_shift, and is vehicle_key one of them or a repeated reference — if a reference, what does it target? | open |
| `core.fct_status_interval.driver_key` | 1,806,357 duplicate value(s) across 1,807,117 non-null rows under a key name | Which column(s) identify one row of fct_status_interval, and is driver_key one of them or a repeated reference — if a reference, what does it target? | open |
| `core.fct_status_interval.interval_date_key` | 1,807,024 duplicate value(s) across 1,807,117 non-null rows under a key name | Which column(s) identify one row of fct_status_interval, and is interval_date_key one of them or a repeated reference — if a reference, what does it target? | open |
| `core.fct_status_interval.vehicle_key` | 1,806,697 duplicate value(s) across 1,807,117 non-null rows under a key name | Which column(s) identify one row of fct_status_interval, and is vehicle_key one of them or a repeated reference — if a reference, what does it target? | open |
| `core.fct_status_interval.zone_key` | 1,692,861 duplicate value(s) across 1,693,120 non-null rows under a key name | Which column(s) identify one row of fct_status_interval, and is zone_key one of them or a repeated reference — if a reference, what does it target? | open |
| `core.fct_status_interval.zone_natural_key` | 1,692,861 duplicate value(s) across 1,693,120 non-null rows under a key name | Which column(s) identify one row of fct_status_interval, and is zone_natural_key one of them or a repeated reference — if a reference, what does it target? | open |
| `core.fct_trip.driver_key` | 146,681 duplicate value(s) across 147,434 non-null rows under a key name | Which column(s) identify one row of fct_trip, and is driver_key one of them or a repeated reference — if a reference, what does it target? | open |
| `core.fct_trip.dropoff_zone_key` | 3,020,909 duplicate value(s) across 3,021,170 non-null rows under a key name | Which column(s) identify one row of fct_trip, and is dropoff_zone_key one of them or a repeated reference — if a reference, what does it target? | open |
| `core.fct_trip.payment_method_key` | 3,017,754 duplicate value(s) across 3,017,760 non-null rows under a key name | Which column(s) identify one row of fct_trip, and is payment_method_key one of them or a repeated reference — if a reference, what does it target? | open |
| `core.fct_trip.pickup_date_key` | 3,021,137 duplicate value(s) across 3,021,170 non-null rows under a key name | Which column(s) identify one row of fct_trip, and is pickup_date_key one of them or a repeated reference — if a reference, what does it target? | open |
| `core.fct_trip.pickup_zone_key` | 3,020,910 duplicate value(s) across 3,021,170 non-null rows under a key name | Which column(s) identify one row of fct_trip, and is pickup_zone_key one of them or a repeated reference — if a reference, what does it target? | open |
| `core.fct_trip.rate_plan_key` | 2,877,591 duplicate value(s) across 2,877,598 non-null rows under a key name | Which column(s) identify one row of fct_trip, and is rate_plan_key one of them or a repeated reference — if a reference, what does it target? | open |
| `core.fct_trip.service_type_key` | 3,021,173 duplicate value(s) across 3,021,175 non-null rows under a key name | Which column(s) identify one row of fct_trip, and is service_type_key one of them or a repeated reference — if a reference, what does it target? | open |
| `core.fct_trip.trip_quality_key` | 3,021,086 duplicate value(s) across 3,021,175 non-null rows under a key name | Which column(s) identify one row of fct_trip, and is trip_quality_key one of them or a repeated reference — if a reference, what does it target? | open |
| `core.fct_trip.vehicle_key` | 147,014 duplicate value(s) across 147,434 non-null rows under a key name | Which column(s) identify one row of fct_trip, and is vehicle_key one of them or a repeated reference — if a reference, what does it target? | open |
| `core.fct_trip.vendor_key` | 3,021,167 duplicate value(s) across 3,021,170 non-null rows under a key name | Which column(s) identify one row of fct_trip, and is vendor_key one of them or a repeated reference — if a reference, what does it target? | open |
| `finance.mart_revenue_component_bridge.service_type_key` | 160 duplicate value(s) across 162 non-null rows under a key name | Which column(s) identify one row of mart_revenue_component_bridge, and is service_type_key one of them or a repeated reference — if a reference, what does it target? | open |
| `ops.mart_driver_scorecard.garage_key` | 754 duplicate value(s) across 760 non-null rows under a key name | Which column(s) identify one row of mart_driver_scorecard, and is garage_key one of them or a repeated reference — if a reference, what does it target? | open |
| `ops.mart_trip_quality_scorecard.service_type_key` | 4 duplicate value(s) across 6 non-null rows under a key name | Which column(s) identify one row of mart_trip_quality_scorecard, and is service_type_key one of them or a repeated reference — if a reference, what does it target? | open |
| `ops.mart_vehicle_utilisation.garage_key` | 414 duplicate value(s) across 420 non-null rows under a key name | Which column(s) identify one row of mart_vehicle_utilisation, and is garage_key one of them or a repeated reference — if a reference, what does it target? | open |

## 5. Enum-shaped column whose set may be open

155 string columns hold between two and twelve distinct values and repeat them, with no `accepted_values` test. That is the shape of an enum and equally the shape of a small lookup — a borough name, a garage name, a classification that may grow. The twelve-value bound is a judgement, not a fact: above it a column reads as free text, a name or a code, and below it the question is worth asking. `open by design` is a complete answer. A column whose name ends in `_key` or `_id` is not listed: an identifier's value set is not a domain. A repeating `_key` is asked in class 4, where the question asks what it targets; a non-repeating `_key` or an `_id` is asked in class 6, where the question asks what it references or whether it is the relation's own identifier, unless the contract declares it `primaryKey`.

| Column | Evidence | Question | Status |
| --- | --- | --- | --- |
| `agg.agg_driver_daily.engagement_type` | 3 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `agg.agg_driver_daily.home_garage_name` | 6 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `agg.agg_driver_monthly.engagement_type` | 3 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `agg.agg_driver_monthly.home_garage_name` | 6 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `agg.agg_garage_monthly.borough_name` | 4 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `agg.agg_garage_monthly.garage_name` | 6 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `agg.agg_od_flow_matrix.dest_borough` | 8 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `agg.agg_od_flow_matrix.origin_borough` | 7 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `agg.agg_trip_band_profile.daypart_code` | 6 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `agg.agg_trip_band_profile.distance_band` | 7 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `agg.agg_trip_band_profile.duration_band` | 6 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `agg.agg_trip_band_profile.fare_band` | 6 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `agg.agg_trip_band_profile.pickup_borough` | 8 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `agg.agg_trip_zone_daily.borough_name` | 8 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `agg.agg_trip_zone_daypart_dow.borough_name` | 8 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `agg.agg_trip_zone_daypart_dow.day_name` | 7 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `agg.agg_trip_zone_daypart_dow.daypart_code` | 6 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `agg.agg_trip_zone_daypart_dow.daypart_name` | 6 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `agg.agg_trip_zone_daypart_dow.reporting_region` | 4 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `agg.agg_trip_zone_daypart_dow.zone_class` | 4 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `agg.agg_vehicle_daily.fuel_type` | 3 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `agg.agg_vehicle_daily.make_model` | 5 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `agg.agg_vehicle_monthly.fuel_type` | 3 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `agg.agg_vehicle_monthly.make_model` | 5 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `agg.agg_weather_demand_daily.borough_name` | 9 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `agg.agg_weather_demand_daily.day_name` | 7 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `agg.agg_weather_demand_daily.weather_class` | 5 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `agg.agg_zone_occupancy_hourly.borough_name` | 8 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `agg.agg_zone_occupancy_hourly.daypart_code` | 6 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `bronze.green_tripdata.store_and_fwd_flag` | 2 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `bronze.taxi_zone_lookup.Borough` | 8 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `bronze.taxi_zone_lookup.service_zone` | 5 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `bronze.yellow_tripdata.store_and_fwd_flag` | 2 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.bridge_zone_poi.poi_category` | 10 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.bridge_zone_poi.poi_category_name` | 10 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.dim_date.day_name` | 7 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.dim_date.holiday_class` | 2 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.dim_date.holiday_name` | 11 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.dim_date.month_name` | 12 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.dim_daypart.daypart_code` | 6 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.dim_daypart.daypart_name` | 6 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.dim_driver.driver_status` | 2 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.dim_driver.engagement_type` | 3 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.dim_driver.home_garage_name` | 6 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.dim_driver.lease_type` | 3 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.dim_fare_regime.fare_component` | 4 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.dim_garage.borough_name` | 4 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.dim_payment_method.settlement_class` | 6 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.dim_rate_plan.pricing_model` | 5 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.dim_vehicle.fuel_type` | 3 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.dim_vehicle.garage_name` | 6 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.dim_vehicle.make` | 4 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.dim_vehicle.make_model` | 5 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.dim_vehicle.model` | 5 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.dim_vendor.contract_tier` | 3 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.dim_zone.borough_code` | 7 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.dim_zone.demand_tier` | 4 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.dim_zone.reporting_region` | 4 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.dim_zone.tlc_service_zone` | 5 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.dim_zone.zone_class` | 4 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.fct_maintenance.maintenance_type` | 3 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.fct_shift.engagement_type` | 3 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.fct_shift.lease_type` | 3 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.fct_shift.telematics_source` | 2 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.fct_status_interval.daypart_code` | 6 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.fct_trip.airport_fee_status` | 3 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.fct_trip.assignment_method` | 2 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.fct_trip.daypart_code` | 6 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `core.fct_trip.store_and_fwd_flag` | 2 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `finance.mart_daily_zone_revenue.borough` | 8 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `finance.mart_daily_zone_revenue.reporting_region` | 4 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `finance.mart_monthly_service_summary.payment_method_name` | 6 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `finance.mart_monthly_service_summary.settlement_class` | 5 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `finance.mart_revenue_component_bridge.borough_name` | 8 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `finance.mart_revenue_component_bridge.component_name` | 9 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `intermediate.int_shift_economics.engagement_type` | 3 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `intermediate.int_shift_economics.lease_type` | 3 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `intermediate.int_shift_occupancy.telematics_source` | 2 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `intermediate.int_status_intervals.status_code` | 6 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `intermediate.int_trip_fare_components.service_type` | 2 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `intermediate.int_trip_fare_components.settlement_class` | 5 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `intermediate.int_trips_conformed.store_and_fwd_flag` | 2 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `intermediate.int_trips_enriched.service_type` | 2 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `intermediate.int_trips_enriched.store_and_fwd_flag` | 2 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `intermediate.int_zone_attributes.borough_code` | 7 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `intermediate.int_zone_attributes.borough_name` | 8 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `intermediate.int_zone_attributes.demand_tier` | 4 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `intermediate.int_zone_attributes.reporting_region` | 4 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `intermediate.int_zone_attributes.tlc_service_zone` | 5 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `intermediate.int_zone_attributes.zone_class` | 4 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `mdm_raw.borough_master.borough_code` | 7 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `mdm_raw.borough_master.reporting_region` | 4 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `mdm_raw.calendar_master.holiday_class` | 2 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `mdm_raw.calendar_master.holiday_name` | 11 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `mdm_raw.fare_regime_master.applies_to_fleet` | 3 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `mdm_raw.fare_regime_master.fare_component` | 4 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `mdm_raw.payment_method_master.settlement_class` | 6 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `mdm_raw.rate_plan_master.pricing_model` | 5 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `mdm_raw.vendor_master.contract_tier` | 3 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `mdm_raw.weather_daily.borough_name` | 6 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `mdm_raw.zone_master.borough_name` | 8 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `mdm_raw.zone_master.demand_tier` | 4 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `mdm_raw.zone_master.tlc_service_zone` | 5 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `mdm_raw.zone_master.zone_class` | 4 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `mdm_raw.zone_poi.poi_category` | 10 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `mdm_raw.zone_poi.poi_category_name` | 10 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `ops.mart_driver_scorecard.engagement_type` | 3 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `ops.mart_driver_scorecard.home_garage_name` | 6 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `ops.mart_trip_quality_scorecard.vendor_legal_name` | 3 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `ops.mart_vehicle_utilisation.fuel_type` | 3 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `ops.mart_vehicle_utilisation.garage_name` | 6 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `ops.mart_vehicle_utilisation.make_model` | 5 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `ops_raw.driver.driver_status` | 2 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `ops_raw.driver.engagement_type` | 3 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `ops_raw.driver_status_event.source_system` | 2 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `ops_raw.driver_status_event.status_code` | 6 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `ops_raw.garage.borough` | 4 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `ops_raw.lease_agreement.lease_type` | 3 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `ops_raw.maintenance_event.maintenance_type` | 3 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `ops_raw.shift.telematics_source` | 2 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `ops_raw.trip_assignment.assignment_method` | 2 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `ops_raw.vehicle.fuel_type` | 3 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `ops_raw.vehicle.make` | 4 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `ops_raw.vehicle.model` | 5 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `seeds.daypart_bands.daypart_code` | 6 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `seeds.daypart_bands.daypart_name` | 6 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `staging.stg_mdm__boroughs.borough_code` | 7 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `staging.stg_mdm__boroughs.reporting_region` | 4 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `staging.stg_mdm__calendar.holiday_class` | 2 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `staging.stg_mdm__calendar.holiday_name` | 11 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `staging.stg_mdm__fare_regimes.applies_to_fleet` | 3 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `staging.stg_mdm__fare_regimes.fare_component` | 4 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `staging.stg_mdm__payment_methods.settlement_class` | 6 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `staging.stg_mdm__rate_plans.pricing_model` | 5 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `staging.stg_mdm__vendors.contract_tier` | 3 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `staging.stg_mdm__weather.borough_name` | 6 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `staging.stg_mdm__zone_poi.poi_category` | 10 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `staging.stg_mdm__zone_poi.poi_category_name` | 10 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `staging.stg_mdm__zones.borough_name` | 8 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `staging.stg_mdm__zones.demand_tier` | 4 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `staging.stg_mdm__zones.tlc_service_zone` | 5 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `staging.stg_mdm__zones.zone_class` | 4 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `staging.stg_ops__drivers.driver_status` | 2 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `staging.stg_ops__drivers.engagement_type` | 3 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `staging.stg_ops__garages.borough_name` | 4 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `staging.stg_ops__leases.lease_type` | 3 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `staging.stg_ops__maintenance.maintenance_type` | 3 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `staging.stg_ops__shifts.telematics_source` | 2 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `staging.stg_ops__status_events.source_system` | 2 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `staging.stg_ops__trip_assignments.assignment_method` | 2 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `staging.stg_ops__vehicles.fuel_type` | 3 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `staging.stg_ops__vehicles.make` | 4 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `staging.stg_ops__vehicles.model` | 5 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `staging.stg_tlc__green_tripdata.store_and_fwd_flag` | 2 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |
| `staging.stg_tlc__yellow_tripdata.store_and_fwd_flag` | 2 distinct values and no accepted_values test | Which values are valid, and is the set closed? | open |

## 6. Reference-shaped column with no `relationships` test

112 columns end in `_key` or `_id`, repeat their values, and declare no `relationships` target. A `primaryKey` column is not listed — it states row identity — a repeating key-shaped column is asked once, under class 4, because that question asks whether it is a key and, if it is a repeated reference, what it targets; a `_dlt_*` bookkeeping column is not asked about at all, because the loader owns both the column and whatever it points at.

| Column | Evidence | Question | Status |
| --- | --- | --- | --- |
| `agg.agg_od_flow_matrix.dest_location_id` | the name reads as a reference and no relationships test states its target | What does dest_location_id reference, or is it this relation's own identifier? | open |
| `agg.agg_od_flow_matrix.origin_location_id` | the name reads as a reference and no relationships test states its target | What does origin_location_id reference, or is it this relation's own identifier? | open |
| `agg.agg_trip_zone_daily.pickup_location_id` | the name reads as a reference and no relationships test states its target | What does pickup_location_id reference, or is it this relation's own identifier? | open |
| `agg.agg_trip_zone_daypart_dow.pickup_location_id` | the name reads as a reference and no relationships test states its target | What does pickup_location_id reference, or is it this relation's own identifier? | open |
| `agg.agg_zone_occupancy_hourly.location_id` | the name reads as a reference and no relationships test states its target | What does location_id reference, or is it this relation's own identifier? | open |
| `bronze.audit_runs.load_id` | the name reads as a reference and no relationships test states its target | What does load_id reference, or is it this relation's own identifier? | open |
| `bronze.audit_table_loads.load_id` | the name reads as a reference and no relationships test states its target | What does load_id reference, or is it this relation's own identifier? | open |
| `core.dim_driver.lease_id` | the name reads as a reference and no relationships test states its target | What does lease_id reference, or is it this relation's own identifier? | open |
| `core.dim_driver.primary_vehicle_id` | the name reads as a reference and no relationships test states its target | What does primary_vehicle_id reference, or is it this relation's own identifier? | open |
| `core.fct_status_interval.shift_id` | the name reads as a reference and no relationships test states its target | What does shift_id reference, or is it this relation's own identifier? | open |
| `core.fct_trip.dropoff_location_id` | the name reads as a reference and no relationships test states its target | What does dropoff_location_id reference, or is it this relation's own identifier? | open |
| `core.fct_trip.pickup_location_id` | the name reads as a reference and no relationships test states its target | What does pickup_location_id reference, or is it this relation's own identifier? | open |
| `core.fct_trip.shift_id` | the name reads as a reference and no relationships test states its target | What does shift_id reference, or is it this relation's own identifier? | open |
| `intermediate.int_shift_economics.driver_id` | the name reads as a reference and no relationships test states its target | What does driver_id reference, or is it this relation's own identifier? | open |
| `intermediate.int_shift_economics.shift_id` | the name reads as a reference and no relationships test states its target | What does shift_id reference, or is it this relation's own identifier? | open |
| `intermediate.int_shift_economics.vehicle_id` | the name reads as a reference and no relationships test states its target | What does vehicle_id reference, or is it this relation's own identifier? | open |
| `intermediate.int_shift_occupancy.driver_id` | the name reads as a reference and no relationships test states its target | What does driver_id reference, or is it this relation's own identifier? | open |
| `intermediate.int_shift_occupancy.shift_id` | the name reads as a reference and no relationships test states its target | What does shift_id reference, or is it this relation's own identifier? | open |
| `intermediate.int_shift_occupancy.vehicle_id` | the name reads as a reference and no relationships test states its target | What does vehicle_id reference, or is it this relation's own identifier? | open |
| `intermediate.int_status_intervals.driver_id` | the name reads as a reference and no relationships test states its target | What does driver_id reference, or is it this relation's own identifier? | open |
| `intermediate.int_status_intervals.interval_id` | the name reads as a reference and no relationships test states its target | What does interval_id reference, or is it this relation's own identifier? | open |
| `intermediate.int_status_intervals.shift_id` | the name reads as a reference and no relationships test states its target | What does shift_id reference, or is it this relation's own identifier? | open |
| `intermediate.int_status_intervals.vehicle_id` | the name reads as a reference and no relationships test states its target | What does vehicle_id reference, or is it this relation's own identifier? | open |
| `intermediate.int_status_intervals.zone_id` | the name reads as a reference and no relationships test states its target | What does zone_id reference, or is it this relation's own identifier? | open |
| `intermediate.int_trip_fare_components.trip_key` | the name reads as a reference and no relationships test states its target | What does trip_key reference, or is it this relation's own identifier? | open |
| `intermediate.int_trip_quality_flags.trip_key` | the name reads as a reference and no relationships test states its target | What does trip_key reference, or is it this relation's own identifier? | open |
| `intermediate.int_trips_conformed.dropoff_location_id` | the name reads as a reference and no relationships test states its target | What does dropoff_location_id reference, or is it this relation's own identifier? | open |
| `intermediate.int_trips_conformed.pickup_location_id` | the name reads as a reference and no relationships test states its target | What does pickup_location_id reference, or is it this relation's own identifier? | open |
| `intermediate.int_trips_conformed.rate_code_id` | the name reads as a reference and no relationships test states its target | What does rate_code_id reference, or is it this relation's own identifier? | open |
| `intermediate.int_trips_conformed.trip_key` | the name reads as a reference and no relationships test states its target | What does trip_key reference, or is it this relation's own identifier? | open |
| `intermediate.int_trips_conformed.vendor_id` | the name reads as a reference and no relationships test states its target | What does vendor_id reference, or is it this relation's own identifier? | open |
| `intermediate.int_trips_enriched.dropoff_location_id` | the name reads as a reference and no relationships test states its target | What does dropoff_location_id reference, or is it this relation's own identifier? | open |
| `intermediate.int_trips_enriched.pickup_location_id` | the name reads as a reference and no relationships test states its target | What does pickup_location_id reference, or is it this relation's own identifier? | open |
| `intermediate.int_trips_enriched.rate_code_id` | the name reads as a reference and no relationships test states its target | What does rate_code_id reference, or is it this relation's own identifier? | open |
| `intermediate.int_trips_enriched.trip_key` | the name reads as a reference and no relationships test states its target | What does trip_key reference, or is it this relation's own identifier? | open |
| `intermediate.int_trips_enriched.vendor_id` | the name reads as a reference and no relationships test states its target | What does vendor_id reference, or is it this relation's own identifier? | open |
| `intermediate.int_zone_attributes.location_id` | the name reads as a reference and no relationships test states its target | What does location_id reference, or is it this relation's own identifier? | open |
| `mdm_raw.audit_runs.load_id` | the name reads as a reference and no relationships test states its target | What does load_id reference, or is it this relation's own identifier? | open |
| `mdm_raw.audit_table_loads.load_id` | the name reads as a reference and no relationships test states its target | What does load_id reference, or is it this relation's own identifier? | open |
| `mdm_raw.vendor_master.vendor_id` | the name reads as a reference and no relationships test states its target | What does vendor_id reference, or is it this relation's own identifier? | open |
| `mdm_raw.weather_daily.observation_id` | the name reads as a reference and no relationships test states its target | What does observation_id reference, or is it this relation's own identifier? | open |
| `mdm_raw.zone_master.location_id` | the name reads as a reference and no relationships test states its target | What does location_id reference, or is it this relation's own identifier? | open |
| `mdm_raw.zone_poi.location_id` | the name reads as a reference and no relationships test states its target | What does location_id reference, or is it this relation's own identifier? | open |
| `mdm_raw.zone_poi.poi_id` | the name reads as a reference and no relationships test states its target | What does poi_id reference, or is it this relation's own identifier? | open |
| `ops.mart_driver_scorecard.driver_key` | the name reads as a reference and no relationships test states its target | What does driver_key reference, or is it this relation's own identifier? | open |
| `ops.mart_trip_quality_scorecard.vendor_id` | the name reads as a reference and no relationships test states its target | What does vendor_id reference, or is it this relation's own identifier? | open |
| `ops.mart_vehicle_utilisation.vehicle_key` | the name reads as a reference and no relationships test states its target | What does vehicle_key reference, or is it this relation's own identifier? | open |
| `ops_raw.audit_runs.load_id` | the name reads as a reference and no relationships test states its target | What does load_id reference, or is it this relation's own identifier? | open |
| `ops_raw.audit_table_loads.load_id` | the name reads as a reference and no relationships test states its target | What does load_id reference, or is it this relation's own identifier? | open |
| `ops_raw.driver.driver_id` | the name reads as a reference and no relationships test states its target | What does driver_id reference, or is it this relation's own identifier? | open |
| `ops_raw.driver.home_garage_id` | the name reads as a reference and no relationships test states its target | What does home_garage_id reference, or is it this relation's own identifier? | open |
| `ops_raw.driver_status_event.driver_id` | the name reads as a reference and no relationships test states its target | What does driver_id reference, or is it this relation's own identifier? | open |
| `ops_raw.driver_status_event.event_id` | the name reads as a reference and no relationships test states its target | What does event_id reference, or is it this relation's own identifier? | open |
| `ops_raw.driver_status_event.shift_id` | the name reads as a reference and no relationships test states its target | What does shift_id reference, or is it this relation's own identifier? | open |
| `ops_raw.driver_status_event.vehicle_id` | the name reads as a reference and no relationships test states its target | What does vehicle_id reference, or is it this relation's own identifier? | open |
| `ops_raw.driver_status_event.zone_id` | the name reads as a reference and no relationships test states its target | What does zone_id reference, or is it this relation's own identifier? | open |
| `ops_raw.garage.garage_id` | the name reads as a reference and no relationships test states its target | What does garage_id reference, or is it this relation's own identifier? | open |
| `ops_raw.lease_agreement.driver_id` | the name reads as a reference and no relationships test states its target | What does driver_id reference, or is it this relation's own identifier? | open |
| `ops_raw.lease_agreement.lease_id` | the name reads as a reference and no relationships test states its target | What does lease_id reference, or is it this relation's own identifier? | open |
| `ops_raw.lease_agreement.primary_vehicle_id` | the name reads as a reference and no relationships test states its target | What does primary_vehicle_id reference, or is it this relation's own identifier? | open |
| `ops_raw.maintenance_event.maintenance_id` | the name reads as a reference and no relationships test states its target | What does maintenance_id reference, or is it this relation's own identifier? | open |
| `ops_raw.maintenance_event.vehicle_id` | the name reads as a reference and no relationships test states its target | What does vehicle_id reference, or is it this relation's own identifier? | open |
| `ops_raw.shift.driver_id` | the name reads as a reference and no relationships test states its target | What does driver_id reference, or is it this relation's own identifier? | open |
| `ops_raw.shift.shift_id` | the name reads as a reference and no relationships test states its target | What does shift_id reference, or is it this relation's own identifier? | open |
| `ops_raw.shift.vehicle_id` | the name reads as a reference and no relationships test states its target | What does vehicle_id reference, or is it this relation's own identifier? | open |
| `ops_raw.trip_assignment.assignment_id` | the name reads as a reference and no relationships test states its target | What does assignment_id reference, or is it this relation's own identifier? | open |
| `ops_raw.trip_assignment.driver_id` | the name reads as a reference and no relationships test states its target | What does driver_id reference, or is it this relation's own identifier? | open |
| `ops_raw.trip_assignment.dropoff_location_id` | the name reads as a reference and no relationships test states its target | What does dropoff_location_id reference, or is it this relation's own identifier? | open |
| `ops_raw.trip_assignment.pickup_location_id` | the name reads as a reference and no relationships test states its target | What does pickup_location_id reference, or is it this relation's own identifier? | open |
| `ops_raw.trip_assignment.shift_id` | the name reads as a reference and no relationships test states its target | What does shift_id reference, or is it this relation's own identifier? | open |
| `ops_raw.trip_assignment.vehicle_id` | the name reads as a reference and no relationships test states its target | What does vehicle_id reference, or is it this relation's own identifier? | open |
| `ops_raw.trip_assignment.vendor_id` | the name reads as a reference and no relationships test states its target | What does vendor_id reference, or is it this relation's own identifier? | open |
| `ops_raw.vehicle.garage_id` | the name reads as a reference and no relationships test states its target | What does garage_id reference, or is it this relation's own identifier? | open |
| `ops_raw.vehicle.vehicle_id` | the name reads as a reference and no relationships test states its target | What does vehicle_id reference, or is it this relation's own identifier? | open |
| `staging.stg_mdm__rate_plans.rate_code_id` | the name reads as a reference and no relationships test states its target | What does rate_code_id reference, or is it this relation's own identifier? | open |
| `staging.stg_mdm__vendors.vendor_id` | the name reads as a reference and no relationships test states its target | What does vendor_id reference, or is it this relation's own identifier? | open |
| `staging.stg_mdm__weather.observation_id` | the name reads as a reference and no relationships test states its target | What does observation_id reference, or is it this relation's own identifier? | open |
| `staging.stg_mdm__zone_poi.location_id` | the name reads as a reference and no relationships test states its target | What does location_id reference, or is it this relation's own identifier? | open |
| `staging.stg_mdm__zone_poi.poi_id` | the name reads as a reference and no relationships test states its target | What does poi_id reference, or is it this relation's own identifier? | open |
| `staging.stg_mdm__zones.location_id` | the name reads as a reference and no relationships test states its target | What does location_id reference, or is it this relation's own identifier? | open |
| `staging.stg_ops__drivers.driver_id` | the name reads as a reference and no relationships test states its target | What does driver_id reference, or is it this relation's own identifier? | open |
| `staging.stg_ops__drivers.home_garage_id` | the name reads as a reference and no relationships test states its target | What does home_garage_id reference, or is it this relation's own identifier? | open |
| `staging.stg_ops__garages.garage_id` | the name reads as a reference and no relationships test states its target | What does garage_id reference, or is it this relation's own identifier? | open |
| `staging.stg_ops__leases.driver_id` | the name reads as a reference and no relationships test states its target | What does driver_id reference, or is it this relation's own identifier? | open |
| `staging.stg_ops__leases.lease_id` | the name reads as a reference and no relationships test states its target | What does lease_id reference, or is it this relation's own identifier? | open |
| `staging.stg_ops__leases.primary_vehicle_id` | the name reads as a reference and no relationships test states its target | What does primary_vehicle_id reference, or is it this relation's own identifier? | open |
| `staging.stg_ops__maintenance.maintenance_id` | the name reads as a reference and no relationships test states its target | What does maintenance_id reference, or is it this relation's own identifier? | open |
| `staging.stg_ops__maintenance.vehicle_id` | the name reads as a reference and no relationships test states its target | What does vehicle_id reference, or is it this relation's own identifier? | open |
| `staging.stg_ops__shifts.driver_id` | the name reads as a reference and no relationships test states its target | What does driver_id reference, or is it this relation's own identifier? | open |
| `staging.stg_ops__shifts.shift_id` | the name reads as a reference and no relationships test states its target | What does shift_id reference, or is it this relation's own identifier? | open |
| `staging.stg_ops__shifts.vehicle_id` | the name reads as a reference and no relationships test states its target | What does vehicle_id reference, or is it this relation's own identifier? | open |
| `staging.stg_ops__status_events.driver_id` | the name reads as a reference and no relationships test states its target | What does driver_id reference, or is it this relation's own identifier? | open |
| `staging.stg_ops__status_events.event_id` | the name reads as a reference and no relationships test states its target | What does event_id reference, or is it this relation's own identifier? | open |
| `staging.stg_ops__status_events.shift_id` | the name reads as a reference and no relationships test states its target | What does shift_id reference, or is it this relation's own identifier? | open |
| `staging.stg_ops__status_events.vehicle_id` | the name reads as a reference and no relationships test states its target | What does vehicle_id reference, or is it this relation's own identifier? | open |
| `staging.stg_ops__status_events.zone_id` | the name reads as a reference and no relationships test states its target | What does zone_id reference, or is it this relation's own identifier? | open |
| `staging.stg_ops__trip_assignments.assignment_id` | the name reads as a reference and no relationships test states its target | What does assignment_id reference, or is it this relation's own identifier? | open |
| `staging.stg_ops__trip_assignments.driver_id` | the name reads as a reference and no relationships test states its target | What does driver_id reference, or is it this relation's own identifier? | open |
| `staging.stg_ops__trip_assignments.trip_key` | the name reads as a reference and no relationships test states its target | What does trip_key reference, or is it this relation's own identifier? | open |
| `staging.stg_ops__trip_assignments.vehicle_id` | the name reads as a reference and no relationships test states its target | What does vehicle_id reference, or is it this relation's own identifier? | open |
| `staging.stg_ops__vehicles.vehicle_id` | the name reads as a reference and no relationships test states its target | What does vehicle_id reference, or is it this relation's own identifier? | open |
| `staging.stg_tlc__green_trip_extras.trip_key` | the name reads as a reference and no relationships test states its target | What does trip_key reference, or is it this relation's own identifier? | open |
| `staging.stg_tlc__green_tripdata.dropoff_location_id` | the name reads as a reference and no relationships test states its target | What does dropoff_location_id reference, or is it this relation's own identifier? | open |
| `staging.stg_tlc__green_tripdata.pickup_location_id` | the name reads as a reference and no relationships test states its target | What does pickup_location_id reference, or is it this relation's own identifier? | open |
| `staging.stg_tlc__green_tripdata.rate_code_id` | the name reads as a reference and no relationships test states its target | What does rate_code_id reference, or is it this relation's own identifier? | open |
| `staging.stg_tlc__green_tripdata.vendor_id` | the name reads as a reference and no relationships test states its target | What does vendor_id reference, or is it this relation's own identifier? | open |
| `staging.stg_tlc__yellow_trip_extras.pickup_location_id` | the name reads as a reference and no relationships test states its target | What does pickup_location_id reference, or is it this relation's own identifier? | open |
| `staging.stg_tlc__yellow_trip_extras.trip_key` | the name reads as a reference and no relationships test states its target | What does trip_key reference, or is it this relation's own identifier? | open |
| `staging.stg_tlc__yellow_tripdata.dropoff_location_id` | the name reads as a reference and no relationships test states its target | What does dropoff_location_id reference, or is it this relation's own identifier? | open |
| `staging.stg_tlc__yellow_tripdata.pickup_location_id` | the name reads as a reference and no relationships test states its target | What does pickup_location_id reference, or is it this relation's own identifier? | open |
| `staging.stg_tlc__yellow_tripdata.rate_code_id` | the name reads as a reference and no relationships test states its target | What does rate_code_id reference, or is it this relation's own identifier? | open |
| `staging.stg_tlc__yellow_tripdata.vendor_id` | the name reads as a reference and no relationships test states its target | What does vendor_id reference, or is it this relation's own identifier? | open |

## Triage

Every row is `open`. The status vocabulary is the one the other reviews use: `intent` when the answer needs a decision recorded before it is written, `open` while it is unanswered, `declined: <reason>` when the contract deliberately leaves the point unstated, and `deferred` when the answer depends on a source that is not this repository's.

Order matters, because answers feed each other:

1. **Grain (1), then key repeats (4).** A grain statement names the columns that identify a row, and that is exactly the class-4 question. Answering 27 grains is likely to close most of the 45 repeats — and where it does not, the column is a repeated reference, so its row also names the target it points at and the relationship to declare.
2. **Descriptions (2), in one pass per table.** A description gives a nullable column its meaning, which is most of the answer to whether null is legal. Answering the 86 tables in 2b closes 1014 columns at the widths listed.
3. **Nullability (3).** For each column, either a `nullValues` rule with `mustBe: 0` (the column is required) or a sentence in the description saying what a null means. Widening `required` where the data never nulls is a separate decision and not asked here.
4. **Enums (5).** An `accepted_values` rule where the set is closed; a note in the description where it is a lookup. The observed distinct values are in the evidence column, so a reviewer can propose the set without querying again.
5. **References (6).** A `relationships` entry on the property names the target and generates the dbt test; where the column is the relation's own identifier rather than a reference, say so in the contract; where it references something outside this Domain, the answer is a description sentence instead.

Nothing here asks for a new pipeline, a new model or a schema change. Each answer is a line in a contract, and `generate` carries the enforceable half of it into the dbt tests and the dlt hints.

## Findings this branch raised outside `reverse`

`reverse` grounds a draft in the catalog, the existing tests and the existing descriptions. Four things the branch
decided are not in that pass, and each needs a person:

### Relationships the canonical model declares and no contract carries

Fifteen. Each is a `gold/missing-relationship` warning: carrying one publishes an edge *and* adds a dbt
`relationships` test, so it is a modelling decision rather than a gate fix.

| Contract | The doubt | The question |
| --- | --- | --- |
| `core.bridge_zone_poi.zone_natural_key` | the model declares `zone_poi_to_zone` to `dim_zone.zone_natural_key`; the contract carries no such relationship | carry it — which publishes the edge and adds a dbt `relationships` test — or record why the contract should not |
| `core.fct_maintenance.vehicle_key` | the model declares `maintenance_to_vehicle` to `dim_vehicle.vehicle_key`; the contract carries no such relationship | carry it — which publishes the edge and adds a dbt `relationships` test — or record why the contract should not |
| `core.fct_maintenance.garage_key` | the model declares `maintenance_to_garage` to `dim_garage.garage_key`; the contract carries no such relationship | carry it — which publishes the edge and adds a dbt `relationships` test — or record why the contract should not |
| `core.fct_maintenance.started_date_key` | the model declares `maintenance_to_date` to `dim_date.date_key`; the contract carries no such relationship | carry it — which publishes the edge and adds a dbt `relationships` test — or record why the contract should not |
| `core.fct_shift.garage_key` | the model declares `shift_to_garage` to `dim_garage.garage_key`; the contract carries no such relationship | carry it — which publishes the edge and adds a dbt `relationships` test — or record why the contract should not |
| `core.fct_shift.shift_date_key` | the model declares `shift_to_date` to `dim_date.date_key`; the contract carries no such relationship | carry it — which publishes the edge and adds a dbt `relationships` test — or record why the contract should not |
| `core.fct_status_interval.driver_key` | the model declares `status_interval_to_driver` to `dim_driver.driver_key`; the contract carries no such relationship | carry it — which publishes the edge and adds a dbt `relationships` test — or record why the contract should not |
| `core.fct_status_interval.vehicle_key` | the model declares `status_interval_to_vehicle` to `dim_vehicle.vehicle_key`; the contract carries no such relationship | carry it — which publishes the edge and adds a dbt `relationships` test — or record why the contract should not |
| `core.fct_status_interval.interval_date_key` | the model declares `status_interval_to_date` to `dim_date.date_key`; the contract carries no such relationship | carry it — which publishes the edge and adds a dbt `relationships` test — or record why the contract should not |
| `core.fct_status_interval.interval_hour` | the model declares `status_interval_to_daypart` to `dim_daypart.hour_of_day`; the contract carries no such relationship | carry it — which publishes the edge and adds a dbt `relationships` test — or record why the contract should not |
| `core.fct_status_interval.zone_key` | the model declares `status_interval_to_zone` to `dim_zone.zone_key`; the contract carries no such relationship | carry it — which publishes the edge and adds a dbt `relationships` test — or record why the contract should not |
| `core.fct_trip.pickup_date_key` | the model declares `trips_to_date` to `dim_date.date_key`; the contract carries no such relationship | carry it — which publishes the edge and adds a dbt `relationships` test — or record why the contract should not |
| `core.fct_trip.pickup_hour` | the model declares `trips_to_daypart` to `dim_daypart.hour_of_day`; the contract carries no such relationship | carry it — which publishes the edge and adds a dbt `relationships` test — or record why the contract should not |
| `core.fct_trip.rate_plan_key` | the model declares `trips_to_rate_plan` to `dim_rate_plan.rate_plan_key`; the contract carries no such relationship | carry it — which publishes the edge and adds a dbt `relationships` test — or record why the contract should not |
| `core.fct_trip.service_type_key` | the model declares `trips_to_service_type` to `dim_service_type.service_type_key`; the contract carries no such relationship | carry it — which publishes the edge and adds a dbt `relationships` test — or record why the contract should not |

### A composite unique key ODCS cannot state

`the canonical model declares the composite unique key (fare_component, applies_to_fleet, valid_from_date)`. ODCS states uniqueness per property, so no contract edit can express a
multi-column key. The question is whether the contract should reference the document's key in prose, or
whether the model should state it as separate `unique` properties instead.

### Two requirement criteria deliberately left open

- **R-14** — the quality rules trace to dbt tests, but a contract cites its canonical document rather than each
  rule citing its ADR. Deciding whether per-rule ADR citations are worth the prose is a review call.
- **R-17** — the 1,501 findings above are queued and none is triaged. That is this artifact's own purpose.

### Deferred, each one line

- `tests/test_maps.py` still says "the map declares no gold layers, so the tool infers them"; the tool no longer infers.
- This artifact's `type: contracts` is outside `.agents/skills/reviewing/templates/review.md`'s enum.
- A `relationships` test targeting a `source()` renders as `ref()` in the generated dbt test.
- A corrupt catalog tracebacks with empty stdout instead of reporting `relations/*`.
- `data-contract`'s "the enforced contract proves it at the build" is true for a dbt model only; 30 of 93 relations are seeds or dlt-loaded.
- A single-column `unique_keys` entry is skipped although ODCS can express it as `unique: true`.
- `odcs.py generate` picks a column's dbt description by column *name*, not by the logical source's `column_map`: on `agg.agg_borough_flow_monthly` it wrote the star's `trip_count` text ("Trips, billable or not.") over the column the source binds to `billable_trip_count`, so that column's description is a `{{ doc() }}` pointer, which `generate` leaves alone.

-- Manual Query Library for Derived Nsight Compute SQLite Bundles
-- Usage:
--   sqlite3 -header -column artifacts/profiles/analysis/<run_id>/ncu_analysis.sqlite < profiling/sql/manual_queries_ncu.sql

-- ============================================================
-- Q01: Bundle metadata
SELECT key, value
FROM bundle_metadata
ORDER BY key;

-- ============================================================
-- Q02: Session import status
SELECT
  page,
  status,
  timeout_sec,
  ROUND(elapsed_sec, 3) AS elapsed_sec,
  line_count,
  row_count,
  reused_existing,
  stdout_path
FROM import_attempts
ORDER BY page;

-- ============================================================
-- Q03: Section import status
SELECT
  section_id,
  display_name,
  status,
  timeout_sec,
  ROUND(elapsed_sec, 3) AS elapsed_sec,
  line_count,
  row_count,
  reused_existing,
  stdout_path
FROM section_import_attempts
ORDER BY section_id;

-- ============================================================
-- Q04: Session attributes
SELECT attribute, value
FROM session_attributes
ORDER BY attribute;

-- ============================================================
-- Q05: Target kernel and string-hit confirmation
SELECT
  kernel_filter,
  kernel_name,
  matched_in_strings,
  string_occurrences
FROM kernel_targets;

-- ============================================================
-- Q06: Embedded section hit counts
SELECT
  section_name,
  occurrences
FROM report_sections
ORDER BY occurrences DESC, section_name ASC;

-- ============================================================
-- Q07: Rule counts by kind
SELECT
  rule_kind,
  COUNT(*) AS occurrences
FROM rule_occurrences
GROUP BY rule_kind
ORDER BY occurrences DESC, rule_kind ASC;

-- ============================================================
-- Q08: Sample rule occurrences
SELECT
  rule_kind,
  occurrence_index,
  ROUND(full_waves, 3) AS full_waves,
  ROUND(issue_every_cycles, 3) AS issue_every_cycles,
  ROUND(active_warps_per_scheduler, 3) AS active_warps_per_scheduler,
  ROUND(eligible_warps_per_cycle, 3) AS eligible_warps_per_cycle,
  rule_text
FROM rule_occurrences
ORDER BY rule_kind, occurrence_index
LIMIT 25;

-- ============================================================
-- Q09: Aggregated derived metrics from string-parsed rules
SELECT
  metric_name,
  occurrences,
  ROUND(min_value, 3) AS min_value,
  ROUND(max_value, 3) AS max_value,
  ROUND(avg_value, 3) AS avg_value,
  unit,
  source
FROM derived_metrics
ORDER BY metric_name;

-- ============================================================
-- Q10: Structured numeric metric summaries
SELECT
  section_id,
  metric_name,
  metric_unit,
  value_count,
  ROUND(min_value, 3) AS min_value,
  ROUND(max_value, 3) AS max_value,
  ROUND(avg_value, 3) AS avg_value
FROM numeric_metric_summaries
ORDER BY section_id, metric_name;

-- ============================================================
-- Q11: Sampled launch coverage
SELECT
  COUNT(*) AS sampled_launch_count,
  MIN(launch_id) AS min_launch_id,
  MAX(launch_id) AS max_launch_id
FROM sampled_launches;

-- ============================================================
-- Q12: Sample structured rows across sampled launches
SELECT
  section_id,
  launch_id,
  sample_rank,
  metric_name,
  metric_unit,
  metric_value_text
FROM sampled_section_metric_values
ORDER BY sample_rank, section_id, metric_name
LIMIT 50;

-- ============================================================
-- Q13: WorkloadDistribution resource-level ratios
WITH workload_raw AS (
  SELECT
    CASE
      WHEN metric_name LIKE 'Average % Active Cycles' THEN TRIM(REPLACE(REPLACE(metric_name, 'Average ', ''), ' Active Cycles', ''))
      WHEN metric_name LIKE 'Total % Elapsed Cycles' THEN TRIM(REPLACE(REPLACE(metric_name, 'Total ', ''), ' Elapsed Cycles', ''))
    END AS resource,
    CASE WHEN metric_name LIKE 'Average % Active Cycles' THEN avg_value END AS avg_active_cycles,
    CASE WHEN metric_name LIKE 'Total % Elapsed Cycles' THEN avg_value END AS avg_elapsed_cycles
  FROM numeric_metric_summaries
  WHERE section_id = 'WorkloadDistribution'
    AND (metric_name LIKE 'Average % Active Cycles' OR metric_name LIKE 'Total % Elapsed Cycles')
)
SELECT
  resource,
  ROUND(MAX(avg_active_cycles), 3) AS avg_active_cycles,
  ROUND(MAX(avg_elapsed_cycles), 3) AS avg_elapsed_cycles,
  ROUND(100.0 * MAX(avg_active_cycles) / NULLIF(MAX(avg_elapsed_cycles), 0), 3) AS active_over_elapsed_pct
FROM workload_raw
GROUP BY resource
ORDER BY active_over_elapsed_pct DESC, resource;

-- ============================================================
-- Q14: WorkloadDistribution cycle summaries
SELECT
  metric_name,
  metric_unit,
  value_count,
  ROUND(min_value, 3) AS min_value,
  ROUND(avg_value, 3) AS avg_value,
  ROUND(max_value, 3) AS max_value
FROM numeric_metric_summaries
WHERE section_id = 'WorkloadDistribution'
ORDER BY
  CASE
    WHEN metric_name LIKE '%Active Cycles%' THEN 0
    WHEN metric_name LIKE '%Elapsed Cycles%' THEN 1
    ELSE 2
  END,
  metric_name;

-- ============================================================
-- Q15: Extraction warnings
SELECT message
FROM extraction_warnings;

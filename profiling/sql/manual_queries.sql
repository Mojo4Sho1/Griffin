-- Manual Query Library for Nsight Systems SQLite Exports
-- Usage:
--   sqlite3 -header -column artifacts/profiles/nsys/<run_id>.sqlite < profiling/sql/manual_queries.sql

-- ============================================================
-- Q01: Top NVTX ranges by total time
-- Interpretation: identifies expensive labeled phases in the traced run.
SELECT
  COALESCE(ne.text, s.value) AS nvtx_label,
  COUNT(*) AS instances,
  ROUND(SUM(ne.end - ne.start) / 1e6, 3) AS total_ms,
  ROUND(AVG(ne.end - ne.start) / 1e3, 3) AS avg_us
FROM NVTX_EVENTS ne
LEFT JOIN StringIds s ON ne.textId = s.id
WHERE ne.eventType = 59 AND ne.end IS NOT NULL
GROUP BY nvtx_label
ORDER BY total_ms DESC
LIMIT 25;

-- ============================================================
-- Q02: Top GPU kernels by total time
-- Interpretation: top kernel hotspots in absolute GPU time.
SELECT
  sd.value AS kernel_name,
  COUNT(*) AS launches,
  ROUND(SUM(k.end - k.start) / 1e6, 3) AS total_ms,
  ROUND(AVG(k.end - k.start) / 1e3, 3) AS avg_us
FROM CUPTI_ACTIVITY_KIND_KERNEL k
JOIN StringIds sd ON k.demangledName = sd.id
GROUP BY kernel_name
ORDER BY total_ms DESC
LIMIT 25;

-- ============================================================
-- Q03: Top CUDA runtime APIs by total time
-- Interpretation: host-side runtime overhead (launch, sync, alloc, memcpy, etc.).
SELECT
  sr.value AS cuda_api,
  COUNT(*) AS calls,
  ROUND(SUM(r.end - r.start) / 1e6, 3) AS total_ms,
  ROUND(AVG(r.end - r.start) / 1e3, 3) AS avg_us
FROM CUPTI_ACTIVITY_KIND_RUNTIME r
JOIN StringIds sr ON r.nameId = sr.id
GROUP BY cuda_api
ORDER BY total_ms DESC
LIMIT 25;

-- ============================================================
-- Q04: Launch-frequency heavy kernels (many launches)
-- Interpretation: identifies tiny/frequent kernel patterns that may be launch-bound.
SELECT
  sd.value AS kernel_name,
  COUNT(*) AS launches,
  ROUND(AVG(k.end - k.start) / 1e3, 3) AS avg_us,
  ROUND(SUM(k.end - k.start) / 1e6, 3) AS total_ms
FROM CUPTI_ACTIVITY_KIND_KERNEL k
JOIN StringIds sd ON k.demangledName = sd.id
GROUP BY kernel_name
ORDER BY launches DESC
LIMIT 25;

-- ============================================================
-- Q05: Top streams by cumulative kernel time
-- Interpretation: checks distribution of work across CUDA streams.
SELECT
  k.streamId AS stream_id,
  COUNT(*) AS kernel_launches,
  ROUND(SUM(k.end - k.start) / 1e6, 3) AS total_ms,
  ROUND(AVG(k.end - k.start) / 1e3, 3) AS avg_us
FROM CUPTI_ACTIVITY_KIND_KERNEL k
GROUP BY k.streamId
ORDER BY total_ms DESC
LIMIT 25;

-- ============================================================
-- Q06: Process-level kernel time split
-- Interpretation: useful for multi-process/rank captures.
SELECT
  p.pid AS pid,
  p.name AS process_name,
  COUNT(*) AS kernel_launches,
  ROUND(SUM(k.end - k.start) / 1e6, 3) AS total_ms
FROM CUPTI_ACTIVITY_KIND_KERNEL k
LEFT JOIN PROCESSES p ON k.globalPid = p.globalPid
GROUP BY p.pid, p.name
ORDER BY total_ms DESC
LIMIT 25;

-- ============================================================
-- Q07: Top named threads by CUDA runtime time
-- Interpretation: finds CPU threads spending most time in CUDA runtime APIs.
SELECT
  COALESCE(ts.value, '(unnamed)') AS thread_name,
  COUNT(*) AS runtime_calls,
  ROUND(SUM(r.end - r.start) / 1e6, 3) AS total_ms,
  ROUND(AVG(r.end - r.start) / 1e3, 3) AS avg_us
FROM CUPTI_ACTIVITY_KIND_RUNTIME r
LEFT JOIN ThreadNames tn ON r.globalTid = tn.globalTid
LEFT JOIN StringIds ts ON tn.nameId = ts.id
GROUP BY thread_name
ORDER BY total_ms DESC
LIMIT 25;

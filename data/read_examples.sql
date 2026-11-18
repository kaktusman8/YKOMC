-- Read-only examples for fps_conditions.sqlite. Every statement is a runnable SELECT.
-- Open with Python sqlite3 URI mode=ro, or sqlite3 -readonly data/fps_conditions.sqlite.
-- The CTE named parameters supplies concrete sample values. In an application,
-- bind those values with your SQLite driver's parameter API; do not concatenate input.

-- Canonical games with explicit availability. Preserve excluded rows for provenance,
-- but omit is_available=0 entries from the application's selectable game list.
SELECT g.id, g.slug, g.name, g.fps_cap,
       CASE WHEN x.game_slug IS NULL THEN 1 ELSE 0 END AS is_available,
       x.reason AS exclusion_reason, x.provenance_id
FROM games AS g
LEFT JOIN fps_game_availability_exclusions AS x ON x.game_slug = g.slug
ORDER BY g.name, g.slug;

-- Hardware identities: slugs are keys; visible names may repeat.
SELECT id, slug, name, score, group_name FROM cpus ORDER BY name, slug;
SELECT id, slug, name, vendor, vram_gb, is_rtx, supports_rt
FROM gpus ORDER BY name, slug;

-- Use keys (2160p), not display labels (4K). The multiplier is already incorporated
-- in gpu_game_resolution_base.base_gpu_fps. Do not apply it a second time.
SELECT id, key, label, multiplier FROM resolutions ORDER BY id;

-- Settings and their options in canonical order. Setting key is NOT unique per game:
-- Valorant has separate detail settings at setting_order 2 and 7.
WITH parameters(game_slug) AS (VALUES ('valorant'))
SELECT s.id AS setting_id, s.setting_order, s.key, s.name, s.type,
       s.high_index, s.tech, o.option_index, o.label, o.multiplier
FROM parameters AS p
JOIN games AS g ON g.slug = p.game_slug
JOIN game_settings AS s ON s.game_id = g.id
JOIN game_setting_options AS o ON o.setting_id = s.id
ORDER BY s.setting_order, o.option_index;

-- The two independent raw factors needed by the educational baseline.
-- This JOIN returns one GPU/resolution baseline and one resolution-independent CPU
-- ceiling, avoiding a fully materialized CPU x GPU x settings table.
WITH parameters(game_slug, cpu_slug, gpu_slug, resolution_key) AS (
  VALUES ('counter-strike-2', 'amd-ryzen-5-5600x', 'nvidia-rtx-3060-12gb', '1080p')
)
SELECT g.slug AS game_slug, cpu.slug AS cpu_slug, gpu.slug AS gpu_slug,
       r.key AS resolution_key, b.base_gpu_fps, cc.cpu_ceiling_raw,
       g.fps_cap, r.multiplier AS resolution_multiplier_already_applied
FROM parameters AS p
JOIN games AS g ON g.slug = p.game_slug
JOIN cpus AS cpu ON cpu.slug = p.cpu_slug
JOIN gpus AS gpu ON gpu.slug = p.gpu_slug
JOIN resolutions AS r ON r.key = p.resolution_key
JOIN gpu_game_resolution_base AS b
  ON b.game_id = g.id AND b.gpu_id = gpu.id AND b.resolution_id = r.id
JOIN cpu_game_ceiling AS cc ON cc.game_id = g.id AND cc.cpu_id = cpu.id
LEFT JOIN fps_game_availability_exclusions AS x ON x.game_slug = g.slug
WHERE x.game_slug IS NULL;

-- Mixed-radix metadata. Order 0 has the smallest stride. Keep state IDs as decimal
-- strings in JSON and use integer arithmetic when encoding or decoding them.
WITH parameters(game_slug) AS (VALUES ('counter-strike-2'))
SELECT g.slug, s.settings_count, s.state_count,
       s.option_radices_json, s.option_strides_json, s.settings_signature_hash
FROM parameters AS p
JOIN games AS g ON g.slug = p.game_slug
JOIN game_state_spaces AS s ON s.game_id = g.id;

-- Availability exclusions and mandatory hardware-RT games are different policies.
SELECT game_slug, reason, provenance_id
FROM fps_game_availability_exclusions ORDER BY game_slug;
SELECT h.game_slug, g.name, h.provenance_id
FROM fps_game_hardware_requirements AS h
JOIN games AS g ON g.slug = h.game_slug
ORDER BY h.game_slug;

-- Optional advanced comparison: this exact scenario overrides the manual site's
-- GPU limit. The educational baseline intentionally does not read calibration tables.
WITH parameters(game_slug, gpu_slug, resolution_key) AS (
  VALUES ('007-first-light', 'nvidia-rtx-5090', '1440p')
)
SELECT c.game_slug, c.hardware_slug, c.resolution_key, c.setting_indexes,
       c.fps, c.provenance_id
FROM parameters AS p
JOIN fps_scenario_gpu_calibrations AS c
  ON c.game_slug = p.game_slug AND c.hardware_slug = p.gpu_slug
 AND c.resolution_key = p.resolution_key
ORDER BY c.setting_indexes;

-- Concise dataset provenance. The database also retains larger source snapshots.
SELECT key, value FROM meta
WHERE key IN ('source_hash', 'schema_version', 'benchmark_calibration_version',
              'benchmark_calibration_hash', 'extracted_at', 'generated_at')
ORDER BY key;

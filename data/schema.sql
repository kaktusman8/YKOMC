-- DDL exported from canonical SQLite snapshot. Data is in fps_conditions.sqlite.
PRAGMA foreign_keys = ON;

CREATE TABLE cpu_game_ceiling (
      game_id INTEGER NOT NULL,
      cpu_id INTEGER NOT NULL,
      cpu_ceiling_raw REAL NOT NULL CHECK (cpu_ceiling_raw >= 0),
      cpu_ceiling INTEGER NOT NULL CHECK (cpu_ceiling >= 0),
      PRIMARY KEY (game_id, cpu_id),
      FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE,
      FOREIGN KEY (cpu_id) REFERENCES cpus(id) ON DELETE CASCADE
    ) WITHOUT ROWID;

CREATE TABLE cpus (
      id INTEGER PRIMARY KEY,
      slug TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      score INTEGER NOT NULL,
      group_name TEXT,
      source_index INTEGER NOT NULL UNIQUE
    );

CREATE TABLE fps_game_availability_exclusions (
      game_slug TEXT PRIMARY KEY, reason TEXT NOT NULL, provenance_id TEXT NOT NULL) WITHOUT ROWID;

CREATE TABLE fps_game_hardware_requirements (
      game_slug TEXT PRIMARY KEY, provenance_id TEXT NOT NULL) WITHOUT ROWID;

CREATE TABLE fps_native_cpu_calibration_profiles (
      game_slug TEXT NOT NULL, hardware_slug TEXT NOT NULL, base_fps REAL NOT NULL CHECK(base_fps > 0),
      setting_multipliers TEXT NOT NULL, provenance_id TEXT NOT NULL,
      PRIMARY KEY(game_slug,hardware_slug)) WITHOUT ROWID;

CREATE TABLE fps_native_gpu_calibration_profiles (
      game_slug TEXT NOT NULL, resolution_key TEXT NOT NULL, hardware_slug TEXT NOT NULL,
      multiplier REAL NOT NULL CHECK(multiplier > 0), provenance_id TEXT NOT NULL,
      PRIMARY KEY(game_slug,resolution_key,hardware_slug)) WITHOUT ROWID;

CREATE TABLE fps_native_preset_cpu_limits (
        preset_id TEXT NOT NULL, game_slug TEXT NOT NULL, hardware_slug TEXT NOT NULL,
        resolution_key TEXT NOT NULL, fps REAL NOT NULL CHECK(fps > 0), provenance_id TEXT NOT NULL,
        PRIMARY KEY(preset_id, game_slug, hardware_slug, resolution_key)) WITHOUT ROWID;

CREATE TABLE fps_native_preset_gpu_limits (
        preset_id TEXT NOT NULL, game_slug TEXT NOT NULL, hardware_slug TEXT NOT NULL,
        resolution_key TEXT NOT NULL, fps REAL NOT NULL CHECK(fps > 0), provenance_id TEXT NOT NULL,
        PRIMARY KEY(preset_id, game_slug, hardware_slug, resolution_key)) WITHOUT ROWID;

CREATE TABLE "fps_native_presets" (
        preset_id TEXT PRIMARY KEY, game_slug TEXT NOT NULL, quality TEXT NOT NULL,
        label TEXT NOT NULL, controls_json TEXT NOT NULL, provenance_id TEXT NOT NULL,
        gpu_vendors_json TEXT, requires_rtx INTEGER, rendering_json TEXT, fps_cap REAL
      , gpu_slugs_json TEXT) WITHOUT ROWID;

CREATE TABLE fps_scenario_cpu_calibrations (
        game_slug TEXT NOT NULL, resolution_key TEXT NOT NULL, setting_indexes TEXT NOT NULL,
        hardware_slug TEXT NOT NULL, fps REAL NOT NULL CHECK(fps > 0), provenance_id TEXT NOT NULL,
        PRIMARY KEY(game_slug, resolution_key, setting_indexes, hardware_slug)) WITHOUT ROWID;

CREATE TABLE fps_scenario_gpu_calibrations (
        game_slug TEXT NOT NULL, resolution_key TEXT NOT NULL, setting_indexes TEXT NOT NULL,
        hardware_slug TEXT NOT NULL, fps REAL NOT NULL CHECK(fps > 0), provenance_id TEXT NOT NULL,
        PRIMARY KEY(game_slug, resolution_key, setting_indexes, hardware_slug)) WITHOUT ROWID;

CREATE TABLE game_setting_options (
      id INTEGER PRIMARY KEY,
      setting_id INTEGER NOT NULL,
      option_index INTEGER NOT NULL,
      label TEXT NOT NULL,
      multiplier REAL NOT NULL,
      FOREIGN KEY (setting_id) REFERENCES game_settings(id) ON DELETE CASCADE,
      UNIQUE(setting_id, option_index)
    );

CREATE TABLE game_settings (
      id INTEGER PRIMARY KEY,
      game_id INTEGER NOT NULL,
      key TEXT NOT NULL,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      setting_order INTEGER NOT NULL,
      impact REAL,
      visual INTEGER,
      high_index INTEGER,
      pin INTEGER NOT NULL CHECK (pin IN (0, 1)),
      tech TEXT,
      why TEXT,
      FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE,
      UNIQUE(game_id, setting_order)
    );

CREATE TABLE game_state_spaces (
      game_id INTEGER PRIMARY KEY,
      settings_count INTEGER NOT NULL CHECK (settings_count >= 1),
      state_count INTEGER NOT NULL CHECK (state_count >= 1),
      option_radices_json TEXT NOT NULL,
      option_strides_json TEXT NOT NULL,
      settings_signature_hash TEXT NOT NULL,
      has_upscale INTEGER NOT NULL CHECK (has_upscale IN (0, 1)),
      has_rt INTEGER NOT NULL CHECK (has_rt IN (0, 1)),
      uses_default_settings INTEGER NOT NULL CHECK (uses_default_settings IN (0, 1)),
      FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE
    ) WITHOUT ROWID;

CREATE TABLE games (
      id INTEGER PRIMARY KEY,
      slug TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      demand REAL NOT NULL,
      category TEXT,
      group_name TEXT,
      fps_cap INTEGER,
      cpu_heavy INTEGER NOT NULL CHECK (cpu_heavy IN (0, 1)),
      uses_default_settings INTEGER NOT NULL CHECK (uses_default_settings IN (0, 1)),
      source_index INTEGER NOT NULL UNIQUE
    );

CREATE TABLE gpu_game_resolution_base (
      game_id INTEGER NOT NULL,
      gpu_id INTEGER NOT NULL,
      resolution_id INTEGER NOT NULL,
      base_gpu_fps REAL NOT NULL CHECK (base_gpu_fps >= 0),
      base_gpu_fps_rounded INTEGER NOT NULL CHECK (base_gpu_fps_rounded >= 0),
      PRIMARY KEY (game_id, gpu_id, resolution_id),
      FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE,
      FOREIGN KEY (gpu_id) REFERENCES gpus(id) ON DELETE CASCADE,
      FOREIGN KEY (resolution_id) REFERENCES resolutions(id) ON DELETE CASCADE
    ) WITHOUT ROWID;

CREATE TABLE gpus (
      id INTEGER PRIMARY KEY,
      slug TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      vendor TEXT,
      score INTEGER NOT NULL,
      vram_gb REAL,
      is_rtx INTEGER NOT NULL CHECK (is_rtx IN (0, 1)),
      supports_rt INTEGER NOT NULL CHECK (supports_rt IN (0, 1)),
      group_name TEXT,
      source_index INTEGER NOT NULL UNIQUE
    );

CREATE TABLE manual_fps_cache (
      game_id INTEGER NOT NULL,
      gpu_id INTEGER NOT NULL,
      cpu_id INTEGER NOT NULL,
      resolution_id INTEGER NOT NULL,
      state_id INTEGER NOT NULL CHECK (state_id >= 0),
      real_fps INTEGER NOT NULL CHECK (real_fps >= 0),
      gpu_fps INTEGER NOT NULL CHECK (gpu_fps >= 0),
      cpu_ceiling INTEGER NOT NULL CHECK (cpu_ceiling >= 0),
      cpu_bound INTEGER NOT NULL CHECK (cpu_bound IN (0, 1)),
      packed_options TEXT NOT NULL,
      created_at TEXT NOT NULL,
      PRIMARY KEY (game_id, gpu_id, cpu_id, resolution_id, state_id),
      FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE,
      FOREIGN KEY (gpu_id) REFERENCES gpus(id) ON DELETE CASCADE,
      FOREIGN KEY (cpu_id) REFERENCES cpus(id) ON DELETE CASCADE,
      FOREIGN KEY (resolution_id) REFERENCES resolutions(id) ON DELETE CASCADE
    ) WITHOUT ROWID;

CREATE TABLE meta (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    );

CREATE TABLE resolutions (
      id INTEGER PRIMARY KEY,
      key TEXT NOT NULL UNIQUE,
      label TEXT NOT NULL,
      multiplier REAL NOT NULL
    );

CREATE TABLE source_snapshots (
      id INTEGER PRIMARY KEY,
      source_url TEXT NOT NULL,
      source_chunk_url TEXT NOT NULL,
      source_hash TEXT NOT NULL,
      extracted_at TEXT NOT NULL,
      generated_at TEXT NOT NULL,
      model_json TEXT NOT NULL
    );

CREATE INDEX idx_cpu_ceiling_cpu_game ON cpu_game_ceiling(cpu_id, game_id);

CREATE INDEX idx_game_setting_options_lookup ON game_setting_options(setting_id, option_index);

CREATE INDEX idx_game_settings_game ON game_settings(game_id, setting_order);

CREATE INDEX idx_game_settings_key ON game_settings(game_id, key);

CREATE INDEX idx_gpu_base_hardware ON gpu_game_resolution_base(gpu_id, game_id, resolution_id);

CREATE INDEX idx_manual_cache_hardware ON manual_fps_cache(gpu_id, cpu_id, game_id, resolution_id);

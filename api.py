import sqlite3
from fastapi import FastAPI
from contextlib import contextmanager
from math import floor
app = FastAPI()

@contextmanager
def connect_to_database():
    conn = sqlite3.connect('data/fps_conditions.sqlite')
    try:
        yield conn
    finally:
        conn.close()

@app.get("/calculate")
def get_calculate(cpu: str, gpu: str, game: str, resolution: str, preset: str):
    with connect_to_database() as conn:
        cur = conn.cursor()
        cur.execute(
            """
            SELECT base_gpu_fps, g.fps_cap FROM gpu_game_resolution_base AS b
            JOIN games AS g ON b.game_id = g.id
            JOIN gpus AS gpu ON b.gpu_id = gpu.id
            JOIN resolutions AS r ON b.resolution_id = r.id
            WHERE g.slug = ? AND gpu.slug = ? AND r.key = ?;
            """,
            (game, gpu, resolution)
        )
        gpu_base_result = cur.fetchone()
        if gpu_base_result is None:
            base_gpu_fps = 0
            fps_cap = 0
        else:
            base_gpu_fps = gpu_base_result[0]
            fps_cap = gpu_base_result[1]
            if fps_cap is None:
                fps_cap = float('inf')

        cur.execute(
            """
            SELECT cpu_ceiling_raw FROM cpu_game_ceiling AS c
            JOIN games AS g ON c.game_id = g.id
            JOIN cpus AS cp ON c.cpu_id = cp.id
            WHERE g.slug = ? AND cp.slug = ?;
            """,
            (game, cpu)
        )
        cpu_base_result = cur.fetchone()
        if cpu_base_result is None:
            cpu_ceiling_raw = 0
        else:
            cpu_ceiling_raw = cpu_base_result[0]

        cur.execute(
            """
            SELECT s.setting_order, s.type, s.high_index, o.option_index, o.multiplier FROM game_settings AS s
            JOIN games AS g ON s.game_id = g.id
            JOIN game_setting_options AS o ON o.setting_id = s.id
            WHERE g.slug = ?
            ORDER BY s.setting_order, o.option_index
            """,
            (game,)
            )
        game_base_result = cur.fetchall()
        if not game_base_result:
            m = 1
        else:
            m = 1
            settings_groups = {}
            for row in game_base_result:
                settings_order = row[0]
                if settings_order not in settings_groups:
                    settings_groups[settings_order] = []

                settings_groups[settings_order].append(row)

            for group in settings_groups.values():
                first_row = group[0]
                setting_type = first_row[1]
                high_index = first_row[2]
                if setting_type in ('rt', 'upscale'):
                    for option_row in group:
                        if option_row[3] == 0:
                            m *= option_row[4]
                else:
                    if preset == "high":
                        for option_row in group:
                            if option_row[3] == high_index:
                                m *= option_row[4]
                    elif preset == "medium":
                        if high_index > 0:
                            target_index = high_index - 1
                        else:
                            target_index = floor((len(group) - 1) / 2)
                        for option_row in group:
                            if option_row[3] == target_index:
                                m *= option_row[4]
                    elif preset == "ultra":
                        m *= group[-1][4]
            base_gpu_fps = base_gpu_fps * m

    
    final_fps = floor(min(base_gpu_fps, cpu_ceiling_raw, fps_cap) + 0.5)
    return {
        "gpu_fps": floor(base_gpu_fps + 0.5), 
        "cpu_fps": floor(cpu_ceiling_raw + 0.5), 
        "final_fps": final_fps
    }
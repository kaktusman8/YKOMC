#!/usr/bin/env python3
"""Verify the educational dataset without modifying it or calculating FPS.

Run with Python 3 from any working directory. Only the standard library is used.
The adjacent metadata file is the trusted manifest for this distributed kit.
"""

import hashlib
import json
import sqlite3
import sys
from pathlib import Path


KIT_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = KIT_ROOT / "data"
REQUIRED_FILES = ("fps_conditions.sqlite", "fps_conditions_model.json")


def file_identity(path):
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return {"bytes": path.stat().st_size, "sha256": digest.hexdigest()}


def quoted_identifier(value):
    return '"' + value.replace('"', '""') + '"'


def verify():
    metadata = json.loads((DATA_DIR / "metadata.json").read_text(encoding="utf-8"))
    manifest_files = metadata["files"]
    expected_counts = metadata["tableCounts"]
    if not isinstance(expected_counts, dict) or not expected_counts:
        raise ValueError("metadata.tableCounts must be a nonempty object")
    for name, count in expected_counts.items():
        if not isinstance(name, str) or type(count) is not int or count < 0:
            raise ValueError("metadata.tableCounts must map table names to nonnegative integers")

    verified_files = {}
    for filename in REQUIRED_FILES:
        expected = manifest_files[filename]
        actual = file_identity(DATA_DIR / filename)
        if actual["bytes"] != expected["bytes"]:
            raise ValueError("File size mismatch: " + filename)
        if actual["sha256"] != expected["sha256"]:
            raise ValueError("SHA256 mismatch: " + filename)
        verified_files[filename] = actual

    database_uri = (DATA_DIR / "fps_conditions.sqlite").resolve().as_uri() + "?mode=ro"
    connection = sqlite3.connect(database_uri, uri=True)
    try:
        quick_check = [row[0] for row in connection.execute("PRAGMA quick_check")]
        if quick_check != ["ok"]:
            raise ValueError("SQLite quick_check failed: " + json.dumps(quick_check))

        violation_count = 0
        first_violations = []
        for violation in connection.execute("PRAGMA foreign_key_check"):
            violation_count += 1
            if len(first_violations) < 10:
                first_violations.append(list(violation))
        if violation_count:
            raise ValueError(
                "SQLite foreign_key_check failed: "
                + json.dumps({"count": violation_count, "firstViolations": first_violations})
            )

        table_names = [
            row[0]
            for row in connection.execute(
                "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name"
            )
        ]
        if set(table_names) != set(expected_counts):
            raise ValueError(
                "Table set mismatch: "
                + json.dumps(
                    {
                        "missing": sorted(set(expected_counts) - set(table_names)),
                        "unexpected": sorted(set(table_names) - set(expected_counts)),
                    }
                )
            )
        actual_counts = {}
        for table_name in table_names:
            actual_count = connection.execute(
                "SELECT COUNT(*) FROM " + quoted_identifier(table_name)
            ).fetchone()[0]
            if actual_count != expected_counts[table_name]:
                raise ValueError(
                    "Row count mismatch for "
                    + table_name
                    + ": expected "
                    + str(expected_counts[table_name])
                    + ", got "
                    + str(actual_count)
                )
            actual_counts[table_name] = actual_count

        return {
            "status": "ok",
            "files": verified_files,
            "quickCheck": "ok",
            "foreignKeyViolations": 0,
            "sqliteVersion": sqlite3.sqlite_version,
            "schemaVersion": connection.execute("PRAGMA schema_version").fetchone()[0],
            "userVersion": connection.execute("PRAGMA user_version").fetchone()[0],
            "tablesVerified": len(actual_counts),
            "tableCounts": actual_counts,
        }
    finally:
        connection.close()


if __name__ == "__main__":
    try:
        print(json.dumps(verify(), ensure_ascii=False, indent=2, sort_keys=True))
    except (OSError, ValueError, KeyError, TypeError, sqlite3.Error) as error:
        print(json.dumps({"status": "error", "message": str(error)}, ensure_ascii=False), file=sys.stderr)
        sys.exit(1)

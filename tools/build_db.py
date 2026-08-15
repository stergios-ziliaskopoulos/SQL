#!/usr/bin/env python3
"""Φτιάχνει (ή ξαναφτιάχνει) τη βάση bookstore.db από τα db/schema.sql και db/seed.sql.

Χρήση:
    python3 tools/build_db.py
"""

import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DB_PATH = ROOT / "bookstore.db"


def main() -> None:
    if DB_PATH.exists():
        DB_PATH.unlink()

    con = sqlite3.connect(DB_PATH)
    con.execute("PRAGMA foreign_keys = ON")
    for name in ("schema.sql", "seed.sql"):
        con.executescript((ROOT / "db" / name).read_text(encoding="utf-8"))
    con.commit()

    tables = [
        r[0]
        for r in con.execute(
            "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
        )
    ]
    print(f"Η βάση δημιουργήθηκε: {DB_PATH}")
    for t in tables:
        n = con.execute(f"SELECT COUNT(*) FROM {t}").fetchone()[0]
        print(f"  {t:<12} {n:>4} γραμμές")
    con.close()


if __name__ == "__main__":
    main()

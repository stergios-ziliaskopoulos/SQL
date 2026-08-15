#!/usr/bin/env python3
"""Μικρό εργαλείο για να τρέχεις SQL πάνω στη βάση bookstore.db.

Τρόποι χρήσης
-------------
1) Διαδραστικά (το πιο βολικό για μάθημα):

       python3 sql.py

   Γράφεις ερώτημα και το τερματίζεις με `;`. Έξοδος με `.exit`.
   Βοηθητικές εντολές: `.tables`, `.schema <πίνακας>`, `.help`

2) Ένα ερώτημα από τη γραμμή εντολών:

       python3 sql.py "SELECT title, price FROM books LIMIT 5;"

3) Ολόκληρο αρχείο .sql:

       python3 sql.py -f exercises/solutions/lesson-01.sql
"""

from __future__ import annotations

import sqlite3
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DB_PATH = ROOT / "bookstore.db"

HELP = """\
Εντολές:
  .tables            λίστα πινάκων
  .schema [πίνακας]  ο ορισμός του πίνακα (ή όλων)
  .help              αυτό το μήνυμα
  .exit / .quit      έξοδος
Οτιδήποτε άλλο θεωρείται SQL και εκτελείται μόλις δει `;`."""


def connect() -> sqlite3.Connection:
    if not DB_PATH.exists():
        sys.exit("Δεν βρέθηκε η bookstore.db — τρέξε πρώτα: python3 tools/build_db.py")
    # isolation_level=None -> autocommit· τα BEGIN/COMMIT/ROLLBACK που γράφεις
    # εσύ στη SQL ισχύουν ακριβώς όπως τα γράφεις (Μάθημα 8).
    con = sqlite3.connect(DB_PATH, isolation_level=None)
    con.execute("PRAGMA foreign_keys = ON")
    return con


def render(cur: sqlite3.Cursor) -> None:
    """Τυπώνει το αποτέλεσμα σαν πίνακα με στοιχισμένες στήλες."""
    if cur.description is None:                       # INSERT/UPDATE/DELETE/DDL
        print(f"OK ({cur.rowcount if cur.rowcount >= 0 else 0} γραμμές επηρεάστηκαν)")
        return

    headers = [d[0] for d in cur.description]
    rows = [["NULL" if v is None else str(v) for v in row] for row in cur.fetchall()]
    widths = [
        max(len(h), *(len(r[i]) for r in rows)) if rows else len(h)
        for i, h in enumerate(headers)
    ]

    line = "  ".join(h.ljust(w) for h, w in zip(headers, widths))
    print(line)
    print("  ".join("-" * w for w in widths))
    for r in rows:
        print("  ".join(v.ljust(w) for v, w in zip(r, widths)))
    print(f"({len(rows)} γραμμές)")


def run(con: sqlite3.Connection, sql: str) -> None:
    try:
        cur = con.execute(sql)
        render(cur)
    except sqlite3.Error as exc:
        print(f"Σφάλμα SQL: {exc}", file=sys.stderr)


def run_script(con: sqlite3.Connection, text: str) -> None:
    """Εκτελεί πολλαπλά ερωτήματα και τυπώνει το αποτέλεσμα του καθενός."""
    for statement in split_statements(text):
        print(f"\n-- {strip_leading_comments(statement).splitlines()[0][:70]}")
        run(con, statement)


def strip_leading_comments(statement: str) -> str:
    """Πετά τα σχόλια και τις κενές γραμμές πριν από το ίδιο το ερώτημα."""
    lines = statement.splitlines()
    while lines and (not lines[0].strip() or lines[0].strip().startswith("--")):
        lines.pop(0)
    return "\n".join(lines).strip()


def split_statements(text: str) -> list[str]:
    out, buf = [], ""
    for line in text.splitlines():
        buf += line + "\n"
        if sqlite3.complete_statement(buf):
            if strip_leading_comments(buf):
                out.append(buf.strip())
            buf = ""
    if strip_leading_comments(buf):
        out.append(buf.strip())
    return out


def meta(con: sqlite3.Connection, cmd: str) -> bool:
    """Χειρίζεται τις εντολές που ξεκινούν με τελεία. Επιστρέφει False για έξοδο."""
    parts = cmd.split()
    head = parts[0]
    if head in (".exit", ".quit"):
        return False
    if head == ".help":
        print(HELP)
    elif head == ".tables":
        for (name,) in con.execute(
            "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
        ):
            print(name)
    elif head == ".schema":
        q = "SELECT sql FROM sqlite_master WHERE sql IS NOT NULL"
        args: tuple = ()
        if len(parts) > 1:
            q += " AND name = ?"
            args = (parts[1],)
        for (sql,) in con.execute(q, args):
            print(sql, ";\n", sep="")
    else:
        print(f"Άγνωστη εντολή: {head}  (δες .help)")
    return True


def repl(con: sqlite3.Connection) -> None:
    print("Βάση: bookstore.db   —   .help για βοήθεια, .exit για έξοδο")
    buf = ""
    while True:
        try:
            line = input("sql> " if not buf else "...> ")
        except (EOFError, KeyboardInterrupt):
            print()
            return

        if not buf and line.strip().startswith("."):
            if not meta(con, line.strip()):
                return
            continue

        buf += line + "\n"
        if sqlite3.complete_statement(buf):
            if buf.strip():
                run(con, buf)
            buf = ""


def main() -> None:
    args = sys.argv[1:]
    con = connect()
    try:
        if not args:
            repl(con)
        elif args[0] == "-f":
            run_script(con, Path(args[1]).read_text(encoding="utf-8"))
        else:
            run_script(con, " ".join(args))
    finally:
        con.close()


if __name__ == "__main__":
    main()

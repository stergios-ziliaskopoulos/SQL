# Μαθαίνω SQL — από το μηδέν μέχρι τα window functions

Ένα πλήρες μάθημα SQL στα ελληνικά, με **πραγματική βάση δεδομένων** που τρέχεις τοπικά,
10 μαθήματα και πάνω από 100 ασκήσεις με λύσεις.

Δεν χρειάζεται τίποτα να εγκαταστήσεις πέρα από **Python 3** — η SQLite έρχεται μαζί του.

---

## Ξεκίνα σε 30 δευτερόλεπτα

```bash
python3 tools/build_db.py     # φτιάχνει τη βάση bookstore.db
python3 sql.py                # ανοίγει διαδραστική κονσόλα SQL
```

```
sql> SELECT title, price FROM books LIMIT 5;
sql> .tables
sql> .schema books
sql> .exit
```

Άλλοι τρόποι εκτέλεσης:

```bash
python3 sql.py "SELECT COUNT(*) FROM orders;"        # ένα ερώτημα
python3 sql.py -f exercises/solutions/lesson-01.sql  # ολόκληρο αρχείο
python3 tools/build_db.py                            # επαναφορά της βάσης
```

> Μη φοβάσαι να χαλάσεις τα δεδομένα. Το `build_db.py` τα ξαναφτιάχνει από την αρχή ανά πάσα στιγμή.

---

## Τα μαθήματα

| # | Μάθημα | Τι μαθαίνεις |
|---|---|---|
| 1 | [Το πρώτο σου `SELECT`](lessons/01-select.md) | πίνακες, στήλες, `AS`, υπολογισμοί, σειρά εκτέλεσης |
| 2 | [Φιλτράρισμα με `WHERE`](lessons/02-where.md) | συγκρίσεις, `AND`/`OR`, `IN`, `LIKE`, `NULL` |
| 3 | [`ORDER BY`, `LIMIT`, `DISTINCT`](lessons/03-order-limit.md) | ταξινόμηση, σελιδοποίηση, `CASE`, συναρτήσεις |
| 4 | [Συγκεντρωτικά και `GROUP BY`](lessons/04-aggregations.md) | `COUNT`, `SUM`, `AVG`, ομαδοποίηση, `HAVING` |
| 5 | [`JOIN`](lessons/05-joins.md) | `INNER`/`LEFT`, anti-join, self-join, πολλά-προς-πολλά |
| 6 | [Υποερωτήματα και CTE](lessons/06-subqueries.md) | `IN`, `EXISTS`, `WITH`, αναδρομή, `UNION` |
| 7 | [Window functions](lessons/07-window-functions.md) | `OVER`, `ROW_NUMBER`, `RANK`, `LAG`, running totals |
| 8 | [`INSERT`, `UPDATE`, `DELETE`](lessons/08-insert-update-delete.md) | αλλαγή δεδομένων, συναλλαγές, ACID, upsert |
| 9 | [Σχεδιασμός και ευρετήρια](lessons/09-schema-design.md) | `CREATE TABLE`, constraints, κανονικοποίηση, indexes, views |
| 10 | [Σύνθετα ερωτήματα](lessons/10-putting-it-together.md) | μεθοδολογία, εντοπισμός λαθών, καλές πρακτικές |

Κάθε μάθημα έχει τις δικές του ασκήσεις στο [`exercises/`](exercises/) και τις λύσεις τους
στο [`exercises/solutions/`](exercises/solutions/).

**Η συμβουλή που μετράει περισσότερο από όλες:** μη διαβάζεις μόνο. Τρέξε **κάθε** ερώτημα,
χάλασέ το επίτηδες, δες τι μήνυμα λάθους παίρνεις, άλλαξε ένα φίλτρο και ξαναδοκίμασε.
Η SQL μαθαίνεται στα δάχτυλα, όχι στα μάτια.

---

## Η βάση: ένα βιβλιοπωλείο

```
authors ──< books >── categories
              │
              ˅
        order_items >── orders ──< customers
              │                        │
              └──────< reviews >───────┘

employees ──< employees        (manager_id → id, για self-join)
```

| Πίνακας | Γραμμές | Τι κρατά |
|---|---|---|
| `authors` | 12 | συγγραφείς |
| `categories` | 8 | κατηγορίες βιβλίων |
| `books` | 25 | τίτλοι, τιμή, απόθεμα |
| `customers` | 14 | πελάτες |
| `orders` | 32 | παραγγελίες (`paid`/`pending`/`cancelled`) |
| `order_items` | 59 | γραμμές παραγγελιών |
| `reviews` | 22 | κριτικές 1–5 αστέρων |
| `employees` | 8 | προσωπικό με ιεραρχία |

Τα δεδομένα περιέχουν **επίτηδες** ατέλειες — πελάτες χωρίς πόλη, βιβλία χωρίς συγγραφέα,
κατηγορία χωρίς βιβλία, πελάτες χωρίς παραγγελίες, βιβλίο που δεν πουλήθηκε ποτέ. Έτσι
μαθαίνεις να χειρίζεσαι τα `NULL` και τα `LEFT JOIN` σε συνθήκες που θυμίζουν την πραγματικότητα.

---

## Δομή του repo

```
README.md                     αυτό το αρχείο
sql.py                        η κονσόλα SQL
bookstore.db                  η βάση (παράγεται· δεν μπαίνει στο git)
db/schema.sql                 οι πίνακες
db/seed.sql                   τα δεδομένα
tools/build_db.py             χτίζει/επαναφέρει τη βάση
lessons/                      τα 10 μαθήματα
exercises/                    ασκήσεις ανά μάθημα
exercises/solutions/          λύσεις, εκτελέσιμες με sql.py -f
examples/dashboard.sql        το μεγάλο παράδειγμα του Μαθήματος 10
```

---

## Σημείωση για τη διάλεκτο

Τα παραδείγματα τρέχουν σε **SQLite**, γιατί δεν απαιτεί εγκατάσταση ή server. Το ~90% όσων
θα μάθεις ισχύει αυτούσιο σε PostgreSQL, MySQL, SQL Server και Oracle. Όπου υπάρχει
σημαντική διαφορά, το μάθημα τη σημειώνει (π.χ. `STRFTIME` έναντι `EXTRACT`, `ILIKE`,
`NULLS LAST`).

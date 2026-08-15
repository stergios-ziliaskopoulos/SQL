# Μάθημα 8 — `INSERT`, `UPDATE`, `DELETE` και συναλλαγές

## Στόχος

Να αλλάζεις δεδομένα — με ασφάλεια.

> Από εδώ και πέρα τα ερωτήματα **τροποποιούν** τη βάση. Δούλεψε ελεύθερα: ό,τι κι αν
> χαλάσεις, ένα `python3 tools/build_db.py` την ξαναφτιάχνει από την αρχή.

---

## 8.1 `INSERT`

```sql
INSERT INTO categories (name) VALUES ('Ιστορία');
```

Δεν δώσαμε `id`: είναι `INTEGER PRIMARY KEY`, οπότε η SQLite το συμπληρώνει μόνη της.

Πολλές γραμμές μαζί (πολύ γρηγορότερο από πολλά ξεχωριστά `INSERT`):

```sql
INSERT INTO authors (name, country, birth_year) VALUES
 ('Ερνέστ Χέμινγουεϊ', 'ΗΠΑ',    1899),
 ('Βιρτζίνια Γουλφ',   'Ηνωμένο Βασίλειο', 1882);
```

**Γράψε πάντα τη λίστα στηλών.** Το `INSERT INTO books VALUES (…)` χωρίς ονόματα εξαρτάται
από τη σειρά των στηλών και σπάει σιωπηλά μόλις κάποιος αλλάξει το σχήμα.

### `INSERT … SELECT`

Εισάγεις το αποτέλεσμα ενός ερωτήματος:

```sql
CREATE TABLE bestsellers (book_id INTEGER, τεμάχια INTEGER);

INSERT INTO bestsellers (book_id, τεμάχια)
SELECT i.book_id, SUM(i.quantity)
FROM order_items i
JOIN orders o ON o.id = i.order_id
WHERE o.status = 'paid'
GROUP BY i.book_id
HAVING SUM(i.quantity) >= 3;
```

---

## 8.2 `UPDATE`

```sql
UPDATE books
SET price = price * 1.10
WHERE category_id = 7;
```

> ### Ο κανόνας που θα σε σώσει
> **Πριν από κάθε `UPDATE`/`DELETE`, τρέξε το ίδιο `WHERE` σαν `SELECT`.**
>
> ```sql
> SELECT id, title, price FROM books WHERE category_id = 7;   -- 1. δες τι θα πειραχτεί
> UPDATE books SET price = price * 1.10 WHERE category_id = 7; -- 2. κάν' το
> ```
>
> Ένα `UPDATE` χωρίς `WHERE` ενημερώνει **όλες** τις γραμμές. Δεν υπάρχει «άκυρο».

Πολλές στήλες μαζί:

```sql
UPDATE customers
SET city = 'Αθήνα',
    email = 'christina.lambrou@example.com'
WHERE id = 9;
```

Ενημέρωση με τιμή από άλλον πίνακα (συσχετισμένο υποερώτημα):

```sql
-- Μείωσε το απόθεμα κατά τα πωληθέντα τεμάχια
UPDATE books
SET stock = stock - (
        SELECT COALESCE(SUM(i.quantity), 0)
        FROM order_items i
        JOIN orders o ON o.id = i.order_id
        WHERE i.book_id = books.id AND o.status = 'paid'
    )
WHERE EXISTS (SELECT 1 FROM order_items i WHERE i.book_id = books.id);
```

---

## 8.3 `DELETE`

```sql
DELETE FROM reviews WHERE rating = 1;
```

- `DELETE FROM reviews;` → σβήνει **όλες** τις γραμμές (ο πίνακας μένει)
- `DROP TABLE reviews;` → σβήνει και τον ίδιο τον πίνακα

Αν υπάρχουν ξένα κλειδιά με `PRAGMA foreign_keys = ON`, η βάση **αρνείται** να σβήσει
γραμμή στην οποία δείχνει κάποια άλλη — προστασία από «ορφανά» δεδομένα:

```sql
DELETE FROM customers WHERE id = 1;
-- Σφάλμα: FOREIGN KEY constraint failed (έχει παραγγελίες)
```

Στην πράξη πολλές εφαρμογές δεν σβήνουν καθόλου: προσθέτουν στήλη `deleted_at` και
φιλτράρουν (*soft delete*). Έτσι τα ιστορικά δεδομένα δεν εξαφανίζονται.

---

## 8.4 Συναλλαγές (transactions)

Μια **συναλλαγή** ομαδοποιεί αλλαγές ώστε να ισχύσουν **όλες μαζί ή καμία**.

```sql
BEGIN;

INSERT INTO orders (customer_id, order_date, status)
VALUES (12, '2025-08-15', 'paid');

INSERT INTO order_items (order_id, book_id, quantity, unit_price)
VALUES (last_insert_rowid(), 16, 1, 13.50);

UPDATE books SET stock = stock - 1 WHERE id = 16;

COMMIT;      -- κλείδωσε τις αλλαγές
-- ROLLBACK; -- ή: ακύρωσέ τες όλες
```

Χωρίς συναλλαγή, αν το τρίτο βήμα αποτύχει, μένεις με παραγγελία της οποίας το απόθεμα
δεν μειώθηκε. Η βάση θα ήταν σε **ασυνεπή κατάσταση**.

Οι συναλλαγές εγγυώνται τις ιδιότητες **ACID**:

| | |
|---|---|
| **A**tomicity | όλα ή τίποτα |
| **C**onsistency | οι κανόνες (constraints) δεν παραβιάζονται ποτέ |
| **I**solation | οι παράλληλες συναλλαγές δεν βλέπουν η μία τα μισοτελειωμένα της άλλης |
| **D**urability | μετά το `COMMIT`, τα δεδομένα επιβιώνουν ακόμα και από διακοπή ρεύματος |

Χρήσιμο κόλπο για δοκιμές: `BEGIN;` → τρέξε το επικίνδυνο `UPDATE` → `SELECT` για να δεις
το αποτέλεσμα → `ROLLBACK;` αν δεν σου άρεσε.

---

## 8.5 `UPSERT` — εισαγωγή ή ενημέρωση

Τι γίνεται αν η γραμμή υπάρχει ήδη;

```sql
INSERT INTO categories (id, name) VALUES (1, 'Λογοτεχνία & Ποίηση')
ON CONFLICT (id) DO UPDATE SET name = excluded.name;
```

Το `excluded` αναφέρεται στη γραμμή που *προσπάθησες* να εισαγάγεις. Υπάρχει και το
`ON CONFLICT DO NOTHING` για «αγνόησέ το αν υπάρχει».

---

## Περίληψη

| Θέλω | Γράφω |
|---|---|
| νέα γραμμή | `INSERT INTO t (στήλες) VALUES (…)` |
| από ερώτημα | `INSERT INTO t (…) SELECT …` |
| αλλαγή | `UPDATE t SET x = … WHERE …` |
| διαγραφή | `DELETE FROM t WHERE …` |
| όλα ή τίποτα | `BEGIN; … COMMIT;` / `ROLLBACK;` |

➡️ **Ασκήσεις:** [`exercises/lesson-08.md`](../exercises/lesson-08.md)
➡️ **Επόμενο:** [Μάθημα 9 — Σχεδιασμός πινάκων και ευρετήρια](09-schema-design.md)

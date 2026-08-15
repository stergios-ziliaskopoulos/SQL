# Μάθημα 9 — Σχεδιασμός πινάκων, περιορισμοί και ευρετήρια

## Στόχος

Να φτιάχνεις εσύ τους πίνακες — και να τους φτιάχνεις σωστά.

---

## 9.1 `CREATE TABLE`

```sql
CREATE TABLE publishers (
    id       INTEGER PRIMARY KEY,
    name     TEXT    NOT NULL UNIQUE,
    city     TEXT,
    founded  INTEGER CHECK (founded > 1400)
);
```

Τύποι δεδομένων στην SQLite (ελάχιστοι επίτηδες): `INTEGER`, `REAL`, `TEXT`, `BLOB`, `NUMERIC`.
Άλλες βάσεις έχουν πλουσιότερο σύνολο — `VARCHAR(50)`, `DATE`, `TIMESTAMP`, `BOOLEAN`,
`DECIMAL(10,2)`, `UUID`, `JSONB` — αλλά η λογική είναι κοινή.

> **Για χρήματα μη χρησιμοποιείς `REAL`/`FLOAT` σε παραγωγή.** Τα δεκαδικά κινητής υποδιαστολής
> δεν αναπαριστούν ακριβώς το 0.1 και τα λάθη συσσωρεύονται. Χρησιμοποίησε `DECIMAL(10,2)`
> (ή ακέραια λεπτά). Εδώ κρατάμε `REAL` για απλότητα.

---

## 9.2 Περιορισμοί (constraints) — οι κανόνες που επιβάλλει η βάση

| Constraint | Τι εγγυάται |
|---|---|
| `PRIMARY KEY` | μοναδική ταυτότητα γραμμής· μοναδικό και μη κενό |
| `NOT NULL` | η στήλη έχει πάντα τιμή |
| `UNIQUE` | καμία επανάληψη τιμής |
| `CHECK (…)` | δική σου συνθήκη (π.χ. `price >= 0`) |
| `REFERENCES άλλος(στήλη)` | η τιμή υπάρχει στον άλλο πίνακα |
| `DEFAULT τιμή` | τιμή όταν δεν δοθεί |

Δοκίμασε να τους παραβιάσεις:

```sql
INSERT INTO books (title, price) VALUES ('Δοκιμή', -5);
-- CHECK constraint failed

INSERT INTO orders (customer_id, order_date, status) VALUES (999, '2025-01-01', 'paid');
-- FOREIGN KEY constraint failed (δεν υπάρχει πελάτης 999)

INSERT INTO orders (customer_id, order_date, status) VALUES (1, '2025-01-01', 'άκυρο');
-- CHECK constraint failed (το status δεν είναι paid/pending/cancelled)
```

**Οι περιορισμοί δεν είναι γραφειοκρατία.** Είναι η μόνη άμυνα που δεν παρακάμπτεται:
ο κώδικας της εφαρμογής μπορεί να έχει bug, κάποιος μπορεί να τρέξει script με το χέρι —
ο περιορισμός ισχύει πάντα. Λάθος δεδομένα είναι πολύ πιο ακριβά από λάθος κώδικα:
τον κώδικα τον διορθώνεις, τα δεδομένα τα έχεις ήδη χάσει.

### `ON DELETE` — τι γίνεται όταν σβήνει ο «γονιός»

```sql
CREATE TABLE reviews (
    id      INTEGER PRIMARY KEY,
    book_id INTEGER NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    ...
);
```

- `ON DELETE RESTRICT` (προεπιλογή) → απαγορεύει τη διαγραφή
- `ON DELETE CASCADE` → σβήνει και τα «παιδιά» (προσοχή: είναι αλυσιδωτό και αμετάκλητο)
- `ON DELETE SET NULL` → μηδενίζει την αναφορά

---

## 9.3 Κανονικοποίηση — μία ιδέα, όχι τελετουργικό

Δες πώς θα ήταν ο κακός σχεδιασμός:

| id | customer | book1 | book2 | book3 | author |
|---|---|---|---|---|---|
| 1 | Μαρία Παπαδοπούλου | 1984 | Ζορμπάς | | Όργουελ, Καζαντζάκης |

Προβλήματα: τι γίνεται με το 4ο βιβλίο; Πώς μετράς πωλήσεις ανά τίτλο; Αν η Μαρία αλλάξει
επώνυμο, σε πόσες γραμμές πρέπει να το διορθώσεις; Και αν το διορθώσεις στις μισές;

Οι πρακτικοί κανόνες:

1. **Μία τιμή ανά κελί.** Όχι λίστες χωρισμένες με κόμμα, όχι `book1/book2/book3`.
   Επαναλαμβανόμενα → δικός τους πίνακας (`order_items`).
2. **Κάθε πίνακας περιγράφει ένα πράγμα.** Ο `books` περιγράφει βιβλία, όχι πελάτες.
3. **Κάθε γεγονός γραμμένο μία φορά.** Το όνομα του συγγραφέα ζει στον `authors`· ο `books`
   κρατά μόνο αναφορά.

Ο κανόνας του πότε **παραβιάζεις** τα παραπάνω: όταν η μέτρηση δείξει ότι πρέπει.
Η στήλη `order_items.unit_price` είναι σκόπιμη «επανάληψη» της `books.price` — γιατί η τιμή
πώλησης είναι **ιστορικό γεγονός** και δεν πρέπει να αλλάζει όταν αλλάξει ο τιμοκατάλογος.
Αυτό δεν είναι σφάλμα σχεδιασμού, είναι σωστή μοντελοποίηση.

### Σχέσεις

| Σχέση | Παράδειγμα | Υλοποίηση |
|---|---|---|
| ένα-προς-πολλά | ένας συγγραφέας → πολλά βιβλία | ξένο κλειδί στην πλευρά «πολλά» |
| πολλά-προς-πολλά | παραγγελίες ↔ βιβλία | ενδιάμεσος πίνακας (`order_items`) |
| ένα-προς-ένα | χρήστης → προφίλ | ξένο κλειδί με `UNIQUE` |

---

## 9.4 `ALTER TABLE`

```sql
ALTER TABLE customers ADD COLUMN phone TEXT;
ALTER TABLE customers RENAME COLUMN phone TO phone_number;
ALTER TABLE customers DROP COLUMN phone_number;
```

Η SQLite υποστηρίζει περιορισμένο `ALTER TABLE` (δεν αλλάζεις τύπο στήλης). Το καθιερωμένο
workaround: φτιάξε νέο πίνακα, `INSERT … SELECT`, `DROP` τον παλιό, `RENAME` τον νέο.

---

## 9.5 Ευρετήρια (indexes)

Χωρίς ευρετήριο, το `WHERE email = '…'` σαρώνει **όλες** τις γραμμές. Το ευρετήριο είναι σαν
το ευρετήριο βιβλίου: αντί να διαβάσεις 400 σελίδες, πας κατευθείαν στη σελίδα 213.

```sql
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_books_category  ON books(category_id);
CREATE UNIQUE INDEX idx_customers_email ON customers(email);

DROP INDEX idx_books_category;
```

Δες αν χρησιμοποιείται:

```sql
EXPLAIN QUERY PLAN
SELECT * FROM orders WHERE customer_id = 1;
-- SEARCH orders USING INDEX idx_orders_customer  ← καλό
-- SCAN orders                                     ← σαρώνει τα πάντα
```

**Πού μπαίνουν ευρετήρια:** στα ξένα κλειδιά, στις στήλες που εμφανίζονται συχνά σε `WHERE`
και `JOIN`, και σε στήλες ταξινόμησης.

**Γιατί όχι παντού:** κάθε ευρετήριο πιάνει χώρο και **επιβραδύνει** τα `INSERT`/`UPDATE`/`DELETE`
(πρέπει να ενημερωθεί κι αυτό). Ένα ευρετήριο σε στήλη με λίγες διακριτές τιμές (π.χ. `status`
με 3 τιμές) συχνά δεν βοηθά καθόλου.

Σε **σύνθετο** ευρετήριο η σειρά μετράει: το `(customer_id, order_date)` εξυπηρετεί ερωτήματα
με `customer_id` ή με `customer_id AND order_date` — αλλά όχι ερώτημα μόνο με `order_date`.

---

## 9.6 Όψεις (views)

Μια **όψη** είναι ένα αποθηκευμένο ερώτημα με όνομα. Δεν κρατά δεδομένα — ξανατρέχει κάθε φορά.

```sql
CREATE VIEW v_πωλήσεις_βιβλίων AS
SELECT
    b.id,
    b.title,
    COALESCE(SUM(i.quantity), 0)                 AS τεμάχια,
    ROUND(COALESCE(SUM(i.quantity * i.unit_price), 0), 2) AS έσοδα
FROM books b
LEFT JOIN order_items i ON i.book_id = b.id
LEFT JOIN orders      o ON o.id = i.order_id AND o.status = 'paid'
GROUP BY b.id, b.title;

SELECT * FROM v_πωλήσεις_βιβλίων ORDER BY έσοδα DESC LIMIT 5;
```

Χρήσιμες για να κρύψεις πολυπλοκότητα και να μη γράφεις το ίδιο 100γραμμο `JOIN` σε δέκα σημεία.

---

## Περίληψη

| Θέλω | Γράφω |
|---|---|
| νέο πίνακα | `CREATE TABLE t (…)` |
| κανόνα ακεραιότητας | `NOT NULL`, `UNIQUE`, `CHECK`, `REFERENCES` |
| αλλαγή σχήματος | `ALTER TABLE t ADD COLUMN …` |
| ταχύτητα σε `WHERE`/`JOIN` | `CREATE INDEX …` |
| έλεγχο πλάνου | `EXPLAIN QUERY PLAN …` |
| αποθηκευμένο ερώτημα | `CREATE VIEW v AS SELECT …` |

➡️ **Ασκήσεις:** [`exercises/lesson-09.md`](../exercises/lesson-09.md)
➡️ **Επόμενο:** [Μάθημα 10 — Πώς λύνεις σύνθετα ερωτήματα](10-putting-it-together.md)

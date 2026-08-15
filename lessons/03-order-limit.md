# Μάθημα 3 — `ORDER BY`, `LIMIT`, `DISTINCT`

## Στόχος

Να ελέγχεις τη σειρά και το πλήθος των αποτελεσμάτων.

---

## 3.1 Ταξινόμηση

```sql
SELECT title, price
FROM books
ORDER BY price DESC;        -- ASC = αύξουσα (προεπιλογή), DESC = φθίνουσα
```

Ταξινόμηση σε **πολλά επίπεδα** — πρώτα κατά κατηγορία, και μέσα σε κάθε κατηγορία κατά τιμή:

```sql
SELECT category_id, title, price
FROM books
ORDER BY category_id ASC, price DESC;
```

Επειδή το `ORDER BY` εκτελείται **μετά** το `SELECT`, μπορείς να ταξινομήσεις κατά ψευδώνυμο
ή κατά υπολογισμό:

```sql
SELECT title, stock * price AS αξία_αποθέματος
FROM books
ORDER BY αξία_αποθέματος DESC;
```

> **Χωρίς `ORDER BY` δεν υπάρχει εγγυημένη σειρά.** Μπορεί σήμερα τα δεδομένα να βγαίνουν
> «σωστά» και αύριο, μετά από μια ενημέρωση, όχι. Αν η σειρά σε νοιάζει, γράψ' την.

### Πού πάνε τα `NULL`;

Στην SQLite τα `NULL` θεωρούνται μικρότερα από όλα, άρα βγαίνουν **πρώτα** σε αύξουσα σειρά.
Αν θέλεις αλλιώς:

```sql
SELECT name, country FROM authors
ORDER BY country IS NULL, country;   -- τα NULL στο τέλος
```

Το κόλπο: το `country IS NULL` δίνει 0/1, και ταξινομούμε πρώτα κατά αυτό.
(Σε PostgreSQL/Oracle υπάρχει το πιο καθαρό `ORDER BY country NULLS LAST`.)

---

## 3.2 `LIMIT` και `OFFSET`

```sql
-- Τα 5 ακριβότερα βιβλία
SELECT title, price FROM books
ORDER BY price DESC
LIMIT 5;

-- Η "δεύτερη σελίδα" των 5 (παράλειψε τα πρώτα 5)
SELECT title, price FROM books
ORDER BY price DESC
LIMIT 5 OFFSET 5;
```

Το `LIMIT` χωρίς `ORDER BY` επιστρέφει «5 τυχαίες γραμμές», όχι «τις 5 πρώτες».

---

## 3.3 `DISTINCT`

Πετά τις διπλότυπες γραμμές του αποτελέσματος:

```sql
SELECT DISTINCT city FROM customers ORDER BY city;
```

Το `DISTINCT` ισχύει για **ολόκληρη τη γραμμή**, όχι για μία στήλη:

```sql
-- Μοναδικοί συνδυασμοί (κατηγορία, έτος) — όχι μοναδικές κατηγορίες
SELECT DISTINCT category_id, published_year FROM books;
```

Αν βλέπεις διπλότυπα και μπαίνεις στον πειρασμό να ρίξεις ένα `DISTINCT`, σταμάτα και
ρώτα **γιατί** υπάρχουν. Συνήθως φταίει ένα `JOIN` που πολλαπλασιάζει γραμμές (Μάθημα 5),
και το `DISTINCT` κρύβει το πρόβλημα αντί να το λύσει.

---

## 3.4 Ένα χρήσιμο μοτίβο: `CASE`

Το `CASE` είναι το «if/else» της SQL — φτιάχνει στήλη με βάση συνθήκες:

```sql
SELECT
    title,
    stock,
    CASE
        WHEN stock = 0            THEN 'εξαντλήθηκε'
        WHEN stock < 5            THEN 'χαμηλό'
        WHEN stock < 15           THEN 'επαρκές'
        ELSE                           'άφθονο'
    END AS κατάσταση_αποθέματος
FROM books
ORDER BY stock;
```

Οι συνθήκες ελέγχονται **με τη σειρά** και κερδίζει η πρώτη που ισχύει. Χωρίς `ELSE`, ό,τι
δεν ταιριάζει γίνεται `NULL`.

Το `CASE` μπαίνει και μέσα σε `ORDER BY` — π.χ. για δική σου σειρά προτεραιότητας:

```sql
SELECT id, status FROM orders
ORDER BY CASE status
             WHEN 'pending'   THEN 1
             WHEN 'paid'      THEN 2
             WHEN 'cancelled' THEN 3
         END;
```

---

## 3.5 Χρήσιμες συναρτήσεις

```sql
SELECT
    UPPER(title)                 AS κεφαλαία,
    LENGTH(title)                AS πλήθος_χαρακτήρων,
    ROUND(price * 1.24, 2)       AS τιμή_με_ΦΠΑ,
    SUBSTR(title, 1, 10)         AS πρώτοι_10,
    REPLACE(title, 'Ο ', '')     AS χωρίς_άρθρο
FROM books
LIMIT 5;
```

Για ημερομηνίες:

```sql
SELECT
    order_date,
    STRFTIME('%Y', order_date)   AS έτος,
    STRFTIME('%m', order_date)   AS μήνας,
    DATE('now')                  AS σήμερα
FROM orders
LIMIT 5;
```

---

## Περίληψη

| Θέλω | Γράφω |
|---|---|
| σειρά | `ORDER BY στήλη [ASC\|DESC]` |
| πρώτα Ν | `LIMIT 10` |
| σελιδοποίηση | `LIMIT 10 OFFSET 20` |
| μοναδικές γραμμές | `SELECT DISTINCT ...` |
| υπό συνθήκη τιμή | `CASE WHEN … THEN … ELSE … END` |

➡️ **Ασκήσεις:** [`exercises/lesson-03.md`](../exercises/lesson-03.md)
➡️ **Επόμενο:** [Μάθημα 4 — Συγκεντρωτικά και GROUP BY](04-aggregations.md)

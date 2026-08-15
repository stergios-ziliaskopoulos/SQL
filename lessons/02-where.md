# Μάθημα 2 — Φιλτράρισμα με `WHERE`

## Στόχος

Να επιστρέφεις **μόνο** τις γραμμές που σε ενδιαφέρουν.

---

## 2.1 Η βασική ιδέα

Το `WHERE` εξετάζει **κάθε γραμμή ξεχωριστά** και την κρατά αν η συνθήκη είναι αληθής.

```sql
SELECT title, price
FROM books
WHERE price < 12;
```

Τελεστές σύγκρισης: `=`, `<>` (ή `!=`), `<`, `<=`, `>`, `>=`.

> Στη SQL η ισότητα είναι **ένα** `=`, όχι `==`.

---

## 2.2 Συνδυασμοί: `AND`, `OR`, `NOT`

```sql
-- Φθηνά βιβλία επιστημονικής φαντασίας
SELECT title, price
FROM books
WHERE category_id = 4 AND price < 14;
```

Το `AND` έχει **μεγαλύτερη προτεραιότητα** από το `OR`, ακριβώς όπως ο πολλαπλασιασμός
από την πρόσθεση. Αυτό γεννά ένα κλασικό λάθος:

```sql
-- ✗ Διαβάζεται ως: (category_id = 1) OR (category_id = 4 AND price < 14)
SELECT title FROM books
WHERE category_id = 1 OR category_id = 4 AND price < 14;

-- ✓ Βάλε παρενθέσεις και πες ακριβώς τι εννοείς
SELECT title FROM books
WHERE (category_id = 1 OR category_id = 4) AND price < 14;
```

**Κανόνας:** όποτε ανακατεύεις `AND` με `OR`, βάλε παρενθέσεις. Πάντα.

---

## 2.3 `BETWEEN`, `IN`

```sql
-- Το BETWEEN είναι κλειστό διάστημα: περιλαμβάνει και τα δύο άκρα
SELECT title, published_year
FROM books
WHERE published_year BETWEEN 1940 AND 1970;

-- Το IN αντικαθιστά μια σειρά από OR
SELECT title FROM books
WHERE category_id IN (2, 3, 6);
```

Το `IN` γίνεται πραγματικά ισχυρό όταν η λίστα προκύπτει από άλλο ερώτημα (Μάθημα 6).

---

## 2.4 Αναζήτηση κειμένου με `LIKE`

Δύο μπαλαντέρ:

- `%` → οποιαδήποτε ακολουθία χαρακτήρων (και κενή)
- `_` → **ακριβώς έναν** χαρακτήρα

```sql
SELECT title FROM books WHERE title LIKE 'Ο %';      -- ξεκινά με "Ο "
SELECT title FROM books WHERE title LIKE '%Κόσμου%'; -- περιέχει
SELECT email FROM customers WHERE email LIKE '%@example.com';
```

Στην SQLite το `LIKE` αγνοεί κεφαλαία/μικρά **μόνο για λατινικούς** χαρακτήρες — στα
ελληνικά το `'ο %'` δεν θα βρει το `'Ο Καπετάν Μιχάλης'`. Είναι γνωστός περιορισμός της
SQLite· η PostgreSQL έχει `ILIKE` που το λύνει.

---

## 2.5 Το `NULL` και γιατί σε προδίδει

`NULL` **δεν** σημαίνει μηδέν ή κενό κείμενο. Σημαίνει **«άγνωστη τιμή»**.

Και εδώ είναι η παγίδα: κάθε σύγκριση με `NULL` δίνει `NULL` — ούτε αληθές ούτε ψευδές —
οπότε η γραμμή **δεν** περνά το φίλτρο.

```sql
-- ✗ Δεν επιστρέφει ΤΙΠΟΤΑ, ακόμα κι αν υπάρχουν πελάτες χωρίς πόλη
SELECT * FROM customers WHERE city = NULL;

-- ✓ Ο σωστός τρόπος
SELECT first_name, last_name FROM customers WHERE city IS NULL;
SELECT first_name, last_name FROM customers WHERE city IS NOT NULL;
```

Ακόμα πιο ύπουλο — αυτό το ερώτημα χάνει γραμμές:

```sql
-- Τα βιβλία χωρίς συγγραφέα (author_id IS NULL) ΔΕΝ εμφανίζονται,
-- παρότι "δεν είναι του συγγραφέα 1"
SELECT title FROM books WHERE author_id <> 1;

-- Αν τα θέλεις κι αυτά, πες το ρητά:
SELECT title FROM books WHERE author_id <> 1 OR author_id IS NULL;
```

Χρήσιμη συνάρτηση: το `COALESCE` επιστρέφει την πρώτη μη-`NULL` τιμή.

```sql
SELECT first_name, COALESCE(city, 'άγνωστη') AS πόλη
FROM customers;
```

---

## 2.6 Ημερομηνίες

Η SQLite δεν έχει ξεχωριστό τύπο ημερομηνίας· τις κρατάμε ως κείμενο `'YYYY-MM-DD'`.
Η μορφή αυτή έχει το ωραίο χαρακτηριστικό ότι **η αλφαβητική σειρά συμπίπτει με τη χρονολογική**:

```sql
SELECT id, order_date FROM orders
WHERE order_date >= '2025-01-01' AND order_date < '2025-07-01';
```

---

## Περίληψη

| Θέλω | Γράφω |
|---|---|
| ίσο / διάφορο | `= 5` / `<> 5` |
| διάστημα | `BETWEEN 10 AND 20` |
| λίστα τιμών | `IN ('paid','pending')` |
| μοτίβο κειμένου | `LIKE '%SQL%'` |
| κενή τιμή | `IS NULL` / `IS NOT NULL` |
| άρνηση | `NOT ...` |

➡️ **Ασκήσεις:** [`exercises/lesson-02.md`](../exercises/lesson-02.md)
➡️ **Επόμενο:** [Μάθημα 3 — Ταξινόμηση και όρια](03-order-limit.md)

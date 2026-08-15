# Ασκήσεις — Μάθημα 12 (Oracle)

Λύσεις: [`solutions/lesson-12.md`](solutions/lesson-12.md)

> Αυτές οι ασκήσεις είναι **μεταφράσεις**, όχι εκτελέσεις — η βάση του project είναι SQLite.
> Γράψε τις απαντήσεις σε χαρτί ή σε αρχείο. Αν θέλεις να τις τρέξεις, φτιάξε δωρεάν
> λογαριασμό στο **Oracle Live SQL** (livesql.oracle.com) — δουλεύει και από κινητό.

## Μεταφράσεις

Μετάφρασε σε Oracle:

1. ```sql
   SELECT DATE('now');
   ```

2. ```sql
   SELECT title, COALESCE(author_id, 0) AS συγγραφέας FROM books;
   ```

3. ```sql
   SELECT title, price FROM books ORDER BY price DESC LIMIT 5;
   ```

4. ```sql
   SELECT title, price FROM books ORDER BY price DESC LIMIT 10 OFFSET 20;
   ```

5. ```sql
   SELECT STRFTIME('%Y-%m', order_date) AS μήνας, SUM(id) AS x
   FROM orders
   GROUP BY μήνας;
   ```
   *(δύο παγίδες εδώ — και η συνάρτηση και το `GROUP BY`)*

6. ```sql
   SELECT id, order_date FROM orders
   WHERE order_date >= '2025-01-01' AND order_date < '2025-02-01';
   ```

7. ```sql
   SELECT category_id, GROUP_CONCAT(title, ', ') AS τίτλοι
   FROM books GROUP BY category_id;
   ```

8. Το αναδρομικό CTE του Μαθήματος 6 (ιεραρχία υπαλλήλων) — γράψ' το με `CONNECT BY`.

9. ```sql
   INSERT INTO categories (id, name) VALUES (1, 'Λογοτεχνία & Ποίηση')
   ON CONFLICT (id) DO UPDATE SET name = excluded.name;
   ```

10. Τα βιβλία που **δεν** έχουν πουληθεί, με τελεστή συνόλων (όχι με `NOT EXISTS`):
    ```sql
    SELECT id FROM books EXCEPT SELECT book_id FROM order_items;
    ```

## Ερωτήσεις κατανόησης

11. Γιατί το παρακάτω είναι επικίνδυνο σε Oracle, ενώ φαίνεται σωστό;
    ```sql
    WHERE order_date BETWEEN TO_DATE('2025-01-01','YYYY-MM-DD')
                         AND TO_DATE('2025-01-31','YYYY-MM-DD')
    ```

12. Σε Oracle, τι επιστρέφει το `SELECT COUNT(*) FROM customers WHERE city = '';`
    και γιατί;

13. Ένα report ταξινομεί `ORDER BY country`. Μετά από μετάπτωση από SQLite σε Oracle, οι
    γραμμές με κενή χώρα άλλαξαν θέση. Τι συνέβη και πώς το κλειδώνεις;

14. Γιατί το `WHERE ROWNUM <= 5 ORDER BY price DESC` δίνει λάθος αποτέλεσμα;

15. Τι είναι το bind variable (`:email`) και ποια **δύο** προβλήματα λύνει;

16. Στο ερώτημα
    ```sql
    SUM(ποσό) OVER (ORDER BY ημερομηνία)
    ```
    ποια είναι η προεπιλεγμένη «κορνίζα» του παραθύρου και πότε σε προδίδει;

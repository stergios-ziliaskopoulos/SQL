-- ============================================================
--  Σχήμα της βάσης "Βιβλιοπωλείο"
--  Το αρχείο αυτό δημιουργεί τους πίνακες (DDL = Data Definition Language).
--  Το διαβάζουμε αναλυτικά στο Μάθημα 9.
-- ============================================================

DROP TABLE IF EXISTS reviews;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS books;
DROP TABLE IF EXISTS authors;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS employees;

-- Συγγραφείς
CREATE TABLE authors (
    id         INTEGER PRIMARY KEY,
    name       TEXT    NOT NULL,
    country    TEXT,
    birth_year INTEGER
);

-- Κατηγορίες βιβλίων
CREATE TABLE categories (
    id   INTEGER PRIMARY KEY,
    name TEXT    NOT NULL UNIQUE
);

-- Βιβλία
CREATE TABLE books (
    id             INTEGER PRIMARY KEY,
    title          TEXT    NOT NULL,
    author_id      INTEGER REFERENCES authors(id),
    category_id    INTEGER REFERENCES categories(id),
    price          REAL    NOT NULL CHECK (price >= 0),
    stock          INTEGER NOT NULL DEFAULT 0,
    published_year INTEGER
);

-- Πελάτες
CREATE TABLE customers (
    id          INTEGER PRIMARY KEY,
    first_name  TEXT NOT NULL,
    last_name   TEXT NOT NULL,
    email       TEXT UNIQUE,
    city        TEXT,
    signup_date TEXT NOT NULL          -- ημερομηνίες ως 'YYYY-MM-DD'
);

-- Παραγγελίες
CREATE TABLE orders (
    id          INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(id),
    order_date  TEXT    NOT NULL,
    status      TEXT    NOT NULL CHECK (status IN ('paid', 'pending', 'cancelled'))
);

-- Γραμμές παραγγελίας (τι ακριβώς περιέχει κάθε παραγγελία)
CREATE TABLE order_items (
    order_id   INTEGER NOT NULL REFERENCES orders(id),
    book_id    INTEGER NOT NULL REFERENCES books(id),
    quantity   INTEGER NOT NULL CHECK (quantity > 0),
    unit_price REAL    NOT NULL,
    PRIMARY KEY (order_id, book_id)
);

-- Κριτικές
CREATE TABLE reviews (
    id          INTEGER PRIMARY KEY,
    book_id     INTEGER NOT NULL REFERENCES books(id),
    customer_id INTEGER NOT NULL REFERENCES customers(id),
    rating      INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment     TEXT,
    review_date TEXT NOT NULL
);

-- Υπάλληλοι (τους χρησιμοποιούμε για self-join στο Μάθημα 5)
CREATE TABLE employees (
    id         INTEGER PRIMARY KEY,
    name       TEXT    NOT NULL,
    role       TEXT,
    manager_id INTEGER REFERENCES employees(id),
    salary     REAL,
    hired_date TEXT
);

CREATE DATABASE IF NOT EXISTS BSM;

USE BSM;

-- Cleanup exising tables

DROP TABLE IF EXISTS membership;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS fiction;
DROP TABLE IF EXISTS nonfiction;
DROP TABLE IF EXISTS books;
DROP TABLE IF EXISTS customer;
DROP FUNCTION IF EXISTS GetMembershipID;
DROP FUNCTION IF EXISTS AddMembershipIfNoneExists;
DROP PROCEDURE IF EXISTS AddMembershipIfNoneExists;
DROP TRIGGER IF EXISTS StockCheck;
DROP TRIGGER IF EXISTS PointsEarned;
DROP TRIGGER IF EXISTS OrderValidity;
DROP PROCEDURE IF EXISTS CreateOrder;
DROP PROCEDURE IF EXISTS PointsEarned;

-- INITIAL SET-UP
-- Creating tables
CREATE TABLE customer (
  c_id INTEGER NOT NULL AUTO_INCREMENT,
  first_name VARCHAR(50),
  last_name VARCHAR(50),
  email VARCHAR(50) NOT NULL,
  PRIMARY KEY (c_id)
);

ALTER TABLE customer AUTO_INCREMENT=200;

CREATE INDEX idx_email
ON customer(email);

CREATE TABLE membership (
  m_id INTEGER NOT NULL AUTO_INCREMENT,
  c_id INTEGER NOT NULL,
  points INT DEFAULT 0,
  rewards_available BOOL,
  PRIMARY KEY (m_id),
  FOREIGN KEY (c_id) REFERENCES customer(c_id)
);

ALTER TABLE membership AUTO_INCREMENT=100;

CREATE TABLE books (
  book_id INTEGER NOT NULL AUTO_INCREMENT,
  rating FLOAT,
  stock INTEGER,
  title VARCHAR(50) NOT NULL,
  author VARCHAR(50) NOT NULL,
  price FLOAT NOT NULL,
  publicationYear YEAR,
  PRIMARY KEY (book_id)
);

CREATE TABLE fiction (
	book_id INT NOT NULL PRIMARY KEY,
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE
);

CREATE TABLE nonfiction (
	book_id INT NOT NULL PRIMARY KEY,
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE
);

CREATE TABLE orders (
  o_id INTEGER NOT NULL AUTO_INCREMENT,
  c_id INTEGER NOT NULL,
  book_id INTEGER NOT NULL,
  PRIMARY KEY (o_id),
  FOREIGN KEY (c_id) REFERENCES customer(c_id),
  FOREIGN KEY (book_id) REFERENCES books(book_id)
);

ALTER TABLE orders AUTO_INCREMENT=300;

-- ADD VALUES

INSERT INTO books
	(title, author, price, publicationYear, rating, stock)
VALUES
	('Five', 'Lucas Byrne', 14.00, 2022, 3.5, 5),
	('Intro to Gardening', 'Julie Adams', 12.50, 2010, 4.2, 3),
	('Advanced Guide to Coding in HTML', 'Mina Lee', 9.99, 2018, 4.6, 8),
    ('Python Projects', 'Doug G', 10.50, 2003, 3.8, 1),
    ('The Lord of the Rings', 'JRR Tolkien', 11.50, 1954, 4.9, 10),
    ('Dune', 'Frank Herbert', 9.99, 1965, 4.2, 7),
    ('Piranesi', 'Susanna Clarke', 4.50, 2020, 3.9, 5),
    ('The Stranger', 'Albert Camus', 5.00, 1942, 4.1, 2);

INSERT INTO fiction (book_id) 
VALUES
 (5),
 (6),
 (7),
 (8);
   
INSERT INTO nonfiction (book_id)
 VALUES
 (1),
 (2),
 (3),
 (4);
 
INSERT INTO customer
	(first_name, last_name, email)
VALUES
	('Emma', 'Hamilton', 'ehamilton@hotmail.com'),
    ('Stuart', 'Patton', 'stu.pat@gmail.com'),
    ('Addie', 'Herrera', 'addieherrera@gmail.com'),
    ('Erik', 'Sykes', 'esykes@yahoo.com'),
    ('Chanel', 'Bird', 'bird2001@gmail.com');


--  INSERT INTO books (p_id, title, author, price, publicationYear, rating, stock)
--  VALUES
--  (5 ,'The Lord of the Rings', 'JRR Tolkien', 11.50, 1954, 4.9, 10);

-- INSERT INTO fiction (book_id)
-- VALUE (5);
 
 -- SELECT * FROM fiction INNER JOIN books ON fiction.book_id = books.book_id;
 -- SELECT * FROM books;
 
 
 -- SELECT * FROM nonfiction INNER JOIN books ON nonfiction.book_id = books.book_id;
 
 -- SELECT * FROM books WHERE rating > 4.0;
 
-- DELETE FROM fiction WHERE book_id = 5;
-- DELETE FROM books WHERE book_id = 5;


-- | Create Stored Functions |

-- Stored function for adding membership accounts to customers if it doesn't exist
DELIMITER $$
CREATE FUNCTION AddMembershipIfNoneExists(
	cus_id INT
) 
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE membership_id INT;
    SET membership_id = (SELECT m_id FROM membership WHERE c_id = cus_id);
    
    IF membership_id IS NULL THEN
		INSERT INTO membership (c_id) VALUES (cus_id);
		SET membership_id = (SELECT m_id FROM membership WHERE c_id = cus_id);
	END IF;

	RETURN (membership_id);
END$$
DELIMITER ;

-- Function to search whether customer has membership ID (lookup)

DELIMITER $$
CREATE FUNCTION GetMembershipID(
	cus_id INT
) 
RETURNS INT
DETERMINISTIC
BEGIN
	RETURN (SELECT m_id FROM membership WHERE c_id = cus_id);
END$$
DELIMITER ;
-- SELECT first_name, GetMembershipID(c_id) FROM customer LIMIT 3;


-- This we will replace with a procedure so it looks nicer :)
-- SELECT AddMembershipIfNoneExists(c_id) FROM customer WHERE first_name = 'Emma' LIMIT 1;

-- SELECT * FROM customer; 
-- SELECT * FROM customer LEFT JOIN membership ON customer.c_id = membership.c_id;

-- CALL AddMembershipIfNoneExists('bird2001@gmail.com');

-- | Stored Procedure |

DELIMITER $$
CREATE PROCEDURE AddMembershipIfNoneExists(IN email VARCHAR(50))
BEGIN 
SELECT AddMembershipIfNoneExists(c_id) FROM customer WHERE customer.email = email;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER StockCheck BEFORE UPDATE ON books FOR EACH ROW BEGIN
IF NEW.stock < 0 THEN
	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You cannot buy an item that does not have stock.';	
END IF;
END $$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER OrderValidity BEFORE INSERT ON orders FOR EACH ROW BEGIN
UPDATE books SET stock = (stock - 1) WHERE books.book_id = NEW.book_id;
UPDATE membership SET points = (points + 1) WHERE membership.c_id = NEW.c_id; 
END $$
DELIMITER ;

-- DELIMITER $$
-- CREATE TRIGGER PointsEarned AFTER UPDATE ON membership FOR EACH ROW BEGIN
-- DECLARE customer_name VARCHAR(50);
-- SET customer_name = (SELECT first_name FROM customer WHERE customer.c_id = NEW.c_id);
-- CALL PointsEarned(customer_name, NEW.points);
-- END $$
-- DELIMITER;

-- DELIMITER $$
-- CREATE PROCEDURE PointsEarned(IN first_name VARCHAR(50), IN points INT)
-- BEGIN
-- 	SELECT CONCAT('** ', customer_name.first_name, ' now has ', NEW.points, ' points.') AS '** DEBUG:';
-- END $$
-- DELIMITER ;

DELIMITER $$
CREATE PROCEDURE CreateOrder(IN email VARCHAR(50), IN book_title VARCHAR(50), IN publication_year INT)
BEGIN
	DECLARE book_identifier INT;
    DECLARE customer_id INT;
    SET book_identifier = (SELECT book_id FROM books WHERE books.title = book_title AND books.publicationYear = publication_year LIMIT 1);
    SET customer_id = (SELECT c_id FROM customer WHERE customer.email = email);

    IF customer_id IS NULL THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'We cannot find a customer with the given email :( .';	
    END IF;
    
    IF book_identifier IS NOT NULL THEN
		INSERT INTO orders (c_id, book_id) VALUES (customer_id, book_identifier);
	ELSE
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'We cannot find the book you are looking for :( .';	
    END IF;
END $$
DELIMITER ;
-- END OF SET-UP


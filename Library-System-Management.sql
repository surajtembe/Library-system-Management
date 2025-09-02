-- The Library Management System Project

-- 1.  Database Setup
-- Databse creation 
CREATE DATABASE library_management_p2;

USE library_management_p2;

-- Table creation
CREATE TABLE branch 
(
	branch_id VARCHAR(10) PRIMARY KEY,
	manager_id VARCHAR(10),
    branch_address VARCHAR(30),	
    contact_no INT
);

CREATE TABLE employees 
(
	emp_id	VARCHAR(10) PRIMARY KEY,
    emp_name VARCHAR(30),	
    position VARCHAR(30),	
    salary DECIMAL(10,2),	
    branch_id VARCHAR(10),
    FOREIGN KEY(branch_id) REFERENCES branch(branch_id)
);

CREATE TABLE members
(
	member_id 	VARCHAR(10) PRIMARY KEY,	
    member_name	VARCHAR(30),
    member_address VARCHAR(30),	
    reg_date DATE
);

CREATE TABLE books
(
	isbn VARCHAR(50) PRIMARY KEY,	
    book_title VARCHAR(100),	
    category VARCHAR(30),	
    rental_price DECIMAL(10,2),
    status	VARCHAR(10),
    author VARCHAR(30),		
    publisher VARCHAR(100)
);

CREATE TABLE issued_status
(
	issued_id VARCHAR(10) PRIMARY KEY,	
    issued_member_id VARCHAR(30),	
    issued_book_name VARCHAR(100),	
    issued_date	DATE,
    issued_book_isbn VARCHAR(50),	
    issued_emp_id VARCHAR(10),
    FOREIGN KEY (issued_member_id) REFERENCES members(member_id),
    FOREIGN KEY (issued_book_isbn) REFERENCES books(isbn),
    FOREIGN KEY (issued_emp_id) REFERENCES employees(emp_id)
);

CREATE TABLE return_status
(
	return_id VARCHAR(10) PRIMARY KEY,	
    issued_id VARCHAR(30),	
    return_book_name VARCHAR(100),	
    return_date	DATE,
    return_book_isbn VARCHAR(50),
    FOREIGN KEY(return_book_isbn) REFERENCES books(isbn)
);

-- 2. CRUD Operations
-- Create: Inserted sample records into the books table.
-- Read: Retrieved and displayed data from various tables.
-- Update: Updated records in the employees table.
-- Delete: Removed records from the members table as needed.

-- Task 1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"
INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
SELECT * FROM books;

-- Task 2: Update an Existing Member's Address
UPDATE members 
SET member_address = '777 Oak St' 
WHERE member_id = 'c105';
SELECT * FROM members;

-- Task 3: Delete a Record from the Issued Status Table -- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.
DELETE FROM issued_status
WHERE issued_id = 'IS121';
SELECT * FROM issued_status;

-- Task 4: Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.
SELECT * FROM issued_status 
WHERE issued_emp_id = 'E101';

-- Task 5: List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.

SELECT issued_emp_id,
COUNT(*)
FROM issued_status
GROUP BY issued_emp_id
HAVING COUNT(*) > 1;


-- 3. CTAS (Create Table As Select)

-- Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**
CREATE TABLE  book_issued_cnt AS
SELECT books.book_title, books.isbn, count(issued_status.issued_id) AS issue_count
FROM issued_status 
INNER JOIN books
ON issued_status.issued_book_isbn = books.isbn
GROUP BY books.book_title, books.isbn;
SELECT * FROM book_issued_cnt;


-- Data Analysis & Findings

-- The following SQL queries were used to address specific questions:

-- Task 7. Retrieve All Books in a Specific Category:
SELECT 
	book_title
FROM books
WHERE category = 'classic';

-- Task 8: Find Total Rental Income by Category:
SELECT 
books.category,
SUM(books.rental_price) AS rental_income
FROM books
INNER JOIN issued_status
ON books.isbn = issued_status.issued_book_isbn
GROUP BY category;


-- 9.List Members Who Registered in YEAR 2021:
SELECT 
*
FROM members
WHERE EXTRACT(YEAR FROM reg_date) = '2021';


-- 10.List Employees with Their Branch Manager's Name and their branch details:
SELECT 
	e1.emp_id,
    e1.emp_name,
    e1.position,
    e1.salary,
    b.*,
    e2.emp_name AS manager
FROM employees AS e1
JOIN branch b
ON e1.branch_id = b.branch_id
JOIN employees e2
ON e2.emp_id = b.manager_id;


-- Task 11. Create a Table of Books with Rental Price Above a Certain Threshold:
CREATE TABLE expensive_books AS
SELECT * FROM books
WHERE rental_price > 7;
SELECT * FROM expensive_books;


-- Task 12: Retrieve the List of Books Not Yet Returned
SELECT 
	*
FROM issued_status AS ist
LEFT JOIN return_status as rst
ON ist.issued_id = rst.issued_id
WHERE rst.return_id IS NULL;


-- Advanced SQL Operations

-- Task 13: Identify Members with Overdue Books
-- Write a query to identify members who have overdue books (assume a 30-day return period). 
-- Display the member's_id, member's name, book title, issue date, and days overdue.

SELECT 
	m.member_id,
    m.member_name,
    ist.issued_book_name,
    ist.issued_date,
    datediff(current_date, ist.issued_date) AS overdue_days
FROM issued_status AS ist
JOIN members m
	ON m.member_id = ist.issued_member_id
-- JOIN books AS bk
-- 	ON bk.isbn = ist.issued_book_isbn
LEFT JOIN return_status rs
	ON rs.issued_id = ist.issued_id
WHERE return_id IS NULL
	AND
datediff(current_date, ist.issued_date) > 30;


-- Task 14: Update Book Status on Return
-- Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).

DELIMITER $$
CREATE PROCEDURE return_status_update(
p_return_id VARCHAR(10), 
p_issued_id VARCHAR(30)
)
BEGIN
	DECLARE 
		v_isbn VARCHAR(50);
        
	INSERT INTO return_status(return_id, issued_id, return_date )
			VALUES(p_return_id, p_issued_id, CURRENT_DATE());
   
	SELECT
		issued_book_isbn
    INTO v_isbn
    FROM issued_status
    WHERE issued_id = p_issued_id;
    
	UPDATE books
    SET status = 'yes'
    WHERE isbn = v_isbn;
END $$
DELIMITER ;

CALL return_status_update('RS120', 'IS136');


-- Task 15: Branch Performance Report
-- Create a query that generates a performance report for each branch, 
-- showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.

CREATE TABLE branch_performance_report 
AS
SELECT 
	br.branch_id,
    br.manager_id,
	COUNT(ist.issued_id) AS no_of_books_issued,
	COUNT(rs.return_id) AS no_of_books_return,
	SUM(bk.rental_price) AS total_revenue_generated
FROM issued_status ist
JOIN employees e
ON e.emp_id  = ist.issued_emp_id
JOIN branch br
ON e.branch_id = br.branch_id
LEFT JOIN
return_status as rs
ON rs.issued_id = ist.issued_id
JOIN 
books as bk
ON ist.issued_book_isbn = bk.isbn
GROUP BY 1, 2;

SELECT * FROM branch_performance_report;


-- Task 16: CTAS: Create a Table of Active Members
-- Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 2 months.

CREATE TABLE active_members AS 
SELECT * FROM members 
WHERE member_id IN(
	SELECT 
	issued_member_id
FROM issued_status
WHERE issued_date >= CURRENT_DATE - INTERVAL  2 MONTH
);

SELECT * FROM active_members;



-- Task 17: Find Employees with the Most Book Issues Processed
-- Write a query to find the top 3 employees who have processed the most book issues. 
-- Display the employee ID, employee name, number of books processed, and their branch.

SELECT 
	emp_id,
    emp_name,
    COUNT(issued_id) AS number_of_books_processed,
    branch_id
 FROM employees e
 JOIN issued_status ist
 WHERE e.emp_id = ist.issued_emp_id
 GROUP BY 1, 2
 ORDER BY number_of_books_processed DESC
 LIMIT 3;




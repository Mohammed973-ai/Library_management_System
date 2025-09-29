------------------------------------------------------------------
/**********************TablesCreation*****************************/
------------------------------------------------------------------
CREATE TABLE books (
    isbn VARCHAR(17) PRIMARY KEY ,
    book_title VARCHAR(80),
    category VARCHAR(20),
    rental_price DEC(6,2),
    [status] VARCHAR(3) check ([status] in ('yes','no')),
    author VARCHAR(50),
    publisher VARCHAR(50)
);


CREATE TABLE employees (
    emp_id VARCHAR(4) PRIMARY KEY 
        CHECK (emp_id LIKE 'E[0-9][0-9][0-9]'),
    emp_name VARCHAR(50),
    position VARCHAR(20),
    salary DECIMAL(8,2),
    branch_id VARCHAR(4) CHECK (branch_id LIKE 'B[0-9][0-9][0-9]')
    
);

CREATE TABLE Branch (
    branch_id VARCHAR(4) PRIMARY KEY 
        CHECK (branch_id LIKE 'B[0-9][0-9][0-9]'),
    manager_id VARCHAR(4) CHECK (manager_id LIKE 'E[0-9][0-9][0-9]'),
    branch_address VARCHAR(100),
    contact_no VARCHAR(10)
);

CREATE TABLE members (
    member_id VARCHAR(4) PRIMARY KEY 
        CHECK (member_id LIKE 'C[0-9][0-9][0-9]'),
    member_name VARCHAR(50),
    member_address VARCHAR(100),
    reg_date DATE
);

CREATE TABLE issued_status (
    issued_id VARCHAR(5) PRIMARY KEY 
        CHECK (issued_id LIKE 'IS[0-9][0-9][0-9]'),
    issued_member_id VARCHAR(4)  
        CHECK (issued_member_id LIKE 'C[0-9][0-9][0-9]'),
    issued_date DATE,
    issued_book_isbn VARCHAR(17)  ,
    issued_emp_id VARCHAR(4) 
        CHECK (issued_emp_id LIKE 'E[0-9][0-9][0-9]'),
);

CREATE TABLE return_status (
    return_id VARCHAR(5) PRIMARY KEY 
        CHECK (return_id LIKE 'RS[0-9][0-9][0-9]'),
    issued_id VARCHAR(5) 
        CHECK (issued_id LIKE 'IS[0-9][0-9][0-9]'),
    return_date DATE,
    return_book_isbn VARCHAR(17),
);
-------------------------------------------------------
DROP TABLE issued_status
DROP TABLE return_status
DROP TABLE members
DROP TABLE books
ALTER TABLE BRANCH DROP CONSTRAINT  FK_Branch_Manager
DROP TABLE employees
DROP TABLE Branch
--------------------------------------------------------
-- FOREIGN KEY constaint for tables
--issued status
ALTER TABLE issued_status
ADD CONSTRAINT FK_Issued_Member
FOREIGN KEY (issued_member_id)
REFERENCES members(member_id)
ON DELETE SET NULL
ON UPDATE CASCADE;
ALTER TABLE issued_status
ADD CONSTRAINT FK_Issued_Book
FOREIGN KEY (issued_book_isbn)
REFERENCES books(isbn)
ON DELETE SET NULL
ON UPDATE CASCADE;
ALTER TABLE issued_status
ADD CONSTRAINT FK_Issued_Employee
FOREIGN KEY (issued_emp_id)
REFERENCES employees(emp_id)
ON DELETE SET NULL
ON UPDATE CASCADE;
---return status fk constraints
alter TABLE return_status ADD CONSTRAINT FK_Return_Book 
    FOREIGN KEY (return_book_isbn) 
    REFERENCES books(isbn)
    ON DELETE SET NULL
    ON UPDATE CASCADE;
alter TABLE return_status ADD CONSTRAINT FK_issued_id 
    FOREIGN KEY (issued_id) 
    REFERENCES issued_status(issued_id)
-- Branch fk constraints
ALTER TABLE Branch
ADD CONSTRAINT FK_Branch_Manager
FOREIGN KEY (manager_id)
REFERENCES employees(emp_id)
ON DELETE SET NULL
ON UPDATE CASCADE;
-- Employee fk constraints
ALTER TABLE employees
ADD CONSTRAINT FK_Employees_Branch
FOREIGN KEY (branch_id)
REFERENCES Branch(branch_id);
----creating trigger so when emp_id is deleted or updates cascades heppens on branch..
DROP TRIGGER t_emp_id_branch_delete,t_emp_id_branch_update
GO
CREATE TRIGGER t_emp_id_branch_delete
on employees
AFTER DELETE
AS
BEGIN
  UPDATE Branch
  SET manager_id = NULL
  WHERE manager_id IN (SELECT emp_id FROM deleted)
END
GO
Create TRIGGER t_emp_id_branch_update
on employees
AFTER Update
AS
BEGIN
   IF UPDATE(emp_id)
   BEGIN
    UPDATE b
    SET b.manager_id = i.emp_id
    FROM Branch b
    INNER JOIN deleted d ON b.manager_id = d.emp_id
    INNER JOIN inserted i ON d.emp_id <> i.emp_id;
   END
END
--- Test the deletion trigger
BEGIN TRANSACTION
SELECT * FROM Branch
WHERE manager_id = 'E109'
DELETE FROM employees
WHERE emp_id = 'E109'
SELECT * FROM Branch
WHERE manager_id = 'E109'
ROLLBACK;
---- test update trigger
BEGIN TRANSACTION
SELECT * FROM Branch
UPDATE  employees
SET emp_id = 'E200'
WHERE emp_id = 'E109'
SELECT * FROM Branch
ROLLBACK;
---------------------------------------------------------
-- Data Insertion
-- emp data
bulk insert  employees
FROM 'D:\Life_factory\Career\SQL\Projects\Library_Management_System\employees.csv'
WITH(FIELDTERMINATOR = ',',firstrow = 2);
--branch data
bulk insert  branch
FROM 'D:\Life_factory\Career\SQL\Projects\Library_Management_System\branch.csv'
WITH(FIELDTERMINATOR = ',',firstrow = 2);
-- book data
bulk insert  books
FROM 'D:\Life_factory\Career\SQL\Projects\Library_Management_System\books.csv'
WITH(FIELDTERMINATOR = ',',firstrow = 2);
-- members data
bulk insert members
FROM 'D:\Life_factory\Career\SQL\Projects\Library_Management_System\members.csv'
WITH(FIELDTERMINATOR = ',',FIRSTROW = 2);
-- issued_status data
bulk insert issued_status
FROM 'D:\Life_factory\Career\SQL\Projects\Library_Management_System\issued_status.csv'
WITH(FIELDTERMINATOR = ',',FIRSTROW = 2);
-- return_status data
bulk insert return_status
FROM 'D:\Life_factory\Career\SQL\Projects\Library_Management_System\return_status.csv'
WITH(FIELDTERMINATOR = ',',FIRSTROW = 2);
-- solving the textqualifier problem
SELECT * FROM books
WHERE book_title LIKE '%;%'
UPDATE books 
SET book_title =  REPLACE(book_title, ';', ',')
WHERE book_title LIKE '%;%'
/* to ensure refrential integrity we want to use triggers
on table issued status so when a new insert is done on the table
it has to check the status value of the book table and if it is no the insertion is rejected and if it is yes the insertion is accepted and thestatis is changed to no */
GO

/*also we want to use it on return_status_table so when insertion is done and status is no insertion is accepted and status is change to yes and if status is yes reject the insertion and say the book hasn't been borrowed*/
CREATE  TRIGGER t_issue_status_insertion
ON issued_status
INSTEAD OF INSERT 
AS
BEGIN
   IF EXISTS (SELECT b.[status] 
                from inserted i
                JOIN books b
                ON  b.isbn = i.issued_book_isbn
                where b.[status] = 'no' )
    BEGIN
        SELECT 'Cannot insert book ' + issued_book_isbn
        FROM inserted i
        JOIN books b
        ON  b.isbn = i.issued_book_isbn
        where b.[status] ='no'
    END
    INSERT INTO issued_status 
    SELECT i.* 
    FROM inserted i
    JOIN books b
    ON  b.isbn = i.issued_book_isbn
    where b.[status] = 'yes' 
    UPDATE  books
    SET [status] ='no'
    FROM inserted i
    JOIN books b
    ON b.isbn = i.issued_book_isbn
    WHERE b.[status] = 'yes' 
        
END
--test 
select * from books
select * from issued_status
begin transaction
select * from books
INSERT INTO issued_status VALUES('IS143','C108','2024-04-07','978-0-06-025492-6','E106')
INSERT INTO issued_status VALUES('IS144','C108','2024-04-07'
,'978-0-06-112008-4','E106')
INSERT INTO issued_status VALUES('IS145','C108','2024-04-07'
,'978-0-06-112241-5','E106')
select * from books
rollback
-- it is working horaaaay!!
-- same for return_status
GO
CREATE  TRIGGER t_return_status_insertion
ON return_status
INSTEAD OF INSERT 
AS
BEGIN
   IF EXISTS (SELECT b.[status] 
                from inserted i
                JOIN books b
                ON  b.isbn = i.return_book_isbn
                where b.[status] = 'yes' )
    BEGIN
        SELECT 'Cannot insert book ' + return_book_isbn + ', it hasn''t been borrowed'
        FROM inserted i
        JOIN books b
        ON  b.isbn = i.return_book_isbn
        where b.[status] ='yes'
    END
    INSERT INTO return_status
    SELECT i.* 
    FROM inserted i
    JOIN books b
    ON  b.isbn = i.return_book_isbn
    where b.[status] = 'no' 
    UPDATE  books
    SET [status] ='yes'
    FROM inserted i
    JOIN books b
    ON b.isbn = i.return_book_isbn
    WHERE b.[status] = 'no'        
END
-- test 
SELECT * FROM issued_status
SELECT * FROM books
SELECT * FROM return_status
begin transaction
SELECT [status] FROM books
where isbn = '978-0-06-112008-4'
INSERT INTO issued_status VALUES('IS143','C108','2024-04-07','978-0-06-112008-4','E106')
SELECT [status] FROM books
where isbn = '978-0-06-112008-4'
INSERT INTO return_status VALUES('RS121','IS143','2024-04-07','978-0-06-112008-4')
SELECT [status] FROM books
where isbn = '978-0-06-112008-4'
rollback;
/* the trigger wont be applied on previous data so to enusre integrity let's say :*/
/* any book that is borrowed and not yet retuned it status shoud
be 'no' , and any book that was borrowed and returned it status should be 'yes'
*/
go
UPDATE b
SET b.[status] = 'no'
FROM issued_status iss
LEFT JOIN return_status rs
ON iss.issued_book_isbn = rs.return_book_isbn
JOIN books b
ON b.isbn = iss.issued_book_isbn
WHERE rs.issued_id IS NULL
SELECT *
FROM issued_status iss
LEFT JOIN return_status rs
ON iss.issued_book_isbn = rs.return_book_isbn
JOIN books b
ON b.isbn = iss.issued_book_isbn
WHERE rs.issued_id IS NULL
GO
UPDATE b
SET b.[status] = 'yes'
FROM return_status rs
JOIN issued_status iss
ON iss.issued_id = rs.issued_id
JOIN books b
ON b.isbn = rs.return_book_isbn


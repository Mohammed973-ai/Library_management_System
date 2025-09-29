# Library_management_System
A comprehensive SQL-based library management system demonstrating end-to-end database development, from conceptual design to advanced analytics.

## Project Overview
This project showcases the complete implementation of a Library Management System using SQL, covering database design, data modeling,
ETL processes, and business intelligence reporting for library operations.





<img width="1048" height="716" alt="image" src="https://github.com/user-attachments/assets/5d935007-0b9f-438b-b3cc-69efd63d93cf" />




## Key Implementation Phases
__1. Data Modeling & Normalization__
* Performed database normalization to eliminate redundancy and ensure data integrity
* Designed a fully normalized relational schema across six interconnected tables
* Applied normalization principles (1NF, 2NF, 3NF) to optimize data structure

__2. Database Design & Implementation__

* Created comprehensive table structures with appropriate data types
* Implemented data integrity using db constraints (Primary Keys, Foreign Keys, Check Constraints)
* Developed database objects including stored procedures for automated operations to enhance integrity
* used Triggers to overcome the multipath cascade problem in sql server and enforce better constraints
* used Triggers to resolve non-foreign key dependncies
* Designed an Entity-Relationship Diagram (ERD) to visualize table relationships and dependencies

__3. ETL Process__

* Extracted data from source files
* Transformed and cleaned data to meet database requirements
* Loaded processed data into the database ready for analysis

__4. Database Schema__
The system manages six core entities:

* employees - Staff information and branch assignments
* members - Library member profiles and registration data
* books - Book inventory with categories, pricing, and availability status
* Branch - Branch locations with manager assignments and contact details
* issued_status - Book issue transaction records
* return_status - Book return records and tracking


__5.Analytics & Reporting Capabilities__

 __Employee Analytics__
 
*  Employee distribution across positions and branches
* Salary analysis and compensation metrics
* Performance tracking based on book issues processed
* Employee-manager hierarchical reporting

 __Member Analytics__

* Total member count and registration trends
* Member activity patterns and engagement levels
* Long-term member identification
* Active member segmentation (last 2 months activity)

__Book Inventory Analysis__

* Total book count and category distribution
* Rental price analysis (average, median, outlier detection)
* High-value book identification
* Category performance by rental revenue

__Operational Analytics__

* Books currently issued vs returned
* Overdue book tracking (30-day return period)
* Member overdue analysis with detailed reporting
* Revenue analysis by category and branch

__Branch Performance__

* Comprehensive branch performance reports
* Books issued and returned per branch
* Revenue generation by branch location
* Employee efficiency metrics

## 1. Data Modeling & Normalization

* There were 6 excel files 1 for each entity so I drew these entities and checked their normal form degree  



<img width="1029" height="562" alt="image" src="https://github.com/user-attachments/assets/daf9ec38-4c8f-4ced-a0c8-f5a375bcce43" />



<img width="1102" height="586" alt="image" src="https://github.com/user-attachments/assets/234f8363-0e39-4e2e-b1d6-0fbec478145b" />



<img width="1118" height="630" alt="image" src="https://github.com/user-attachments/assets/912c4aba-fad7-4c2a-8c37-548d1818017e" />


## 2. Database Design & Implementation

- ###  ERD


<img width="1395" height="723" alt="image" src="https://github.com/user-attachments/assets/f96d2035-b07b-40ff-a254-f9baba3833b5" />


- ### Table Creation and domain , Entity and Refrential Constraints

```tsql
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
-- issued status fk constraints
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
```
- ### Handling Circular References with Triggers
Since the `employees` and `Branch` tables have a circular relationship (employees reference branches, branches reference managers who are employees), SQL Server prevents using `ON DELETE SET NULL` and `ON UPDATE CASCADE` on both foreign keys due to multiple cascade path conflicts. To resolve this, I applied cascade constraints to one foreign key and implemented 2 trigger deletion and update triggers to handle the cascading logic for the other, ensuring referential integrity without conflicts.

```tsql
--creating trigger so when emp_id is deleted or updates cascades heppens on branch..
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

```

- ### Managing Non-Foreign Key Dependencies
Implemented business logic to handle interdependent columns across tables that aren't linked by foreign keys. The `status` column in the `books` table relates to records in `issued_status` and `return_status` tables: when `status = 'yes'`, the book is available for issuing; when `status = 'no'`, it's currently borrowed. To avoid insertion conflicts during the initial data load, I deferred this logic enforcement until after data insertion, then manually updated the book status values to reflect the correct availability based on issue and return records.   
```TSQL
-- adding trigger for any insertion in the return_status table
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


```
```tsql
-- adding trigger for any insertion in the return_status table

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
```
## 3. ETL Process

- ### Extraction
    - Downloaded source data files in Excel/CSV format

- ### Transformation
    - **Text Qualifier Issue**: Removed text qualifiers (`""`) from CSV files that were causing all values to be interpreted as strings during import
    - **Data Type Conversion**: Reformatted columns to appropriate data types, particularly converting date columns to `'YYYY-MM-DD'` format for SQL compatibility
    - **NULL Value Handling**: Replaced string literals "NULL" with actual empty values to ensure proper NULL representation in the database
    - **Delimiter Management**: Temporarily replaced commas within data values with semicolons (`;`) to prevent column misalignment during import, then restored original values post-loading

- ### Loading
    - Utilized SQL `BULK INSERT` statement for efficient data import into database tables
  ```tsql
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
  ```
  ```tsql
    -- updating the status values to align with what in return_status and issued_status     
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
  ```

* __Testing the 2 triggers that was made for cicular refrence between `employees` and `branch`__
```tsql
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
```

* __Testing the trigger for non foreign key dependancies__

```tsql
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
```










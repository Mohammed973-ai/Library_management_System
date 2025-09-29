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


__4. Analytics & Reporting Capabilities__

  -  __Employee Analytics__
 
     -  Employee distribution across positions and branches
     - Salary analysis and compensation metrics
     - Performance tracking based on book issues processed
     - Employee-manager hierarchical reporting

  -  __Member Analytics__

     * Total member count and registration trends
     * Member activity patterns and engagement levels
     * Long-term member identification
     * Active member segmentation (last 2 months activity)

 -  __Book Inventory Analysis__

     * Total book count and category distribution
     * Rental price analysis (average, median, outlier detection)
     * High-value book identification
     * Category performance by rental revenue

 -  __Operational Analytics__

     * Books currently issued vs returned
     * Overdue book tracking (30-day return period)
     * Member overdue analysis with detailed reporting
     * Revenue analysis by category and branch

  - __Branch Performance__

     * Comprehensive branch performance reports
     * Books issued and returned per branch
     * Revenue generation by branch location
     * Employee efficiency metrics

__5. Database Schema__
The system manages six core entities:

* employees - Staff information and branch assignments
* members - Library member profiles and registration data
* books - Book inventory with categories, pricing, and availability status
* Branch - Branch locations with manager assignments and contact details
* issued_status - Book issue transaction records
* return_status - Book return records and tracking



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
    FROM 'my_datapath.csv'
    WITH(FIELDTERMINATOR = ',',firstrow = 2);
    --branch data
    bulk insert  branch
    FROM 'my_datapath.csv'
    WITH(FIELDTERMINATOR = ',',firstrow = 2);
    -- book data
    bulk insert  books
    FROM 'my_datapath.csv'
    WITH(FIELDTERMINATOR = ',',firstrow = 2);
    -- members data
    bulk insert members
    FROM 'my_datapath.csv'
    WITH(FIELDTERMINATOR = ',',FIRSTROW = 2);
    -- issued_status data
    bulk insert issued_status
    FROM 'my_datapath.csv'
    WITH(FIELDTERMINATOR = ',',FIRSTROW = 2);
    -- return_status data
    bulk insert return_status
    FROM 'my_datapath.csv'
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


## 4. Analytics & Reporting Capabilities


- ### CRAUD Operation
    - __insert that record  '978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.' in books__
 

      ```tsql
      INSERT INTO books VALUES ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')
      ```
    - __Update an Existing Member's Address__
 

      ```tsql  
          UPDATE members
          SET member_address = '125 Oak St'
          WHERE member_id = 'C103';
      ```


    - __Delete a Record from the Issued Status Table -- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.__


       ```tsql
        BEGIN TRANSACTION
        DELETE FROM issued_status
        WHERE issued_id = 'IS121'
        ROLLBACK;
       ```

    - __Retrieve All Books Issued by a Specific Employee.__

       ```tsql
            SELECT b.book_title
            FROM issued_status i 
            JOIN books b
            ON b.isbn = i.issued_book_isbn
            AND issued_emp_id ='E101'
        ```
- ### Data cleaning
  - __check null values for any column in any table__

      ```tsql
        DECLARE @table_name VARCHAR(50) = 'return_status',
        @sql NVARCHAR(MAX) = ''
        SELECT @sql = STRING_AGG(' SELECT ''' + c.name+''' AS [column name] ,COUNT(*) AS [NULL COUNT] FROM ' +@table_name+' WHERE '+c.name+' IS NULL ',' UNION ALL')
        FROM sys.columns c
        WHERE c.object_id =OBJECT_ID(@table_name)
      ```
  * __we found a whole column in return_status which is return_bookisbn with null values and we recovered it using issued_status__
 

    ```tsql
          UPDATE rs
          SET rs.return_book_isbn = iss.issued_book_isbn
          FROM return_status rs
          JOIN issued_status iss
          ON iss.issued_id = rs.issued_id
    ```
  - __check outlier values for any column in any table__
       - __we checked for salary and rental price attributes__
```tsql
DECLARE @table_name VARCHAR(50) = 'books',
@desired_col VARCHAR(50) = 'rental_price'
,@sql nvarchar(max)
SELECT @sql  = 'WITH quartiles
AS(
	SELECT TOP(1) PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY '+@desired_col+' ) OVER() AS Q2, 
	PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY '+@desired_col +' )
	OVER() AS Q3
	FROM '+ @table_name +'
),
iqr_fences AS(
	SELECT Q2 - 1.5*(Q3-Q2) AS [lower_fence],
		   Q3 + 1.5*(Q3-Q2) AS [upper_fence] 
	FROM quartiles
)
SELECT * 
FROM '+@table_name+' , iqr_fences
WHERE '+@desired_col + '  < [lower_fence] 
OR ' +@desired_col +' > [upper_fence]'
EXEC sp_executesql @sql
```
- __No outlier for employees but there is one  for books__
			<table border="1" cellpadding="8" cellspacing="0" style="margin-left: 40px;">
			  <thead>
			    <tr>
			      <th>ISBN</th>
			      <th>Rental Price</th>
			      <th>Lower Fence</th>
			      <th>Upper Fence</th>
			    </tr>
			  </thead>
			  <tbody>
			    <tr>
			      <td>978-0-307-37840-1</td>
			      <td>2.50</td>
			      <td>3.25</td>
			      <td>9.25</td>
			    </tr>
			  </tbody>
		</table>  



- __we may keep it since we cant remove the book from the library and 
 we cant change its price as we are't people who put prices 
 but when doing agg on rental we won't take it in consideration__

- ## Data cleaning
   - How many employees do we have ?
  ```tsql
  SELECT COUNT(*) AS [# of emp]
  FROM employees

  
  ```

	- What postions do we have ?
     ```tsql
     SELECT DISTINCT position 
	 FROM employees
  
  ```
	
	- how many employees does each postion have?
     ```tsql
     SELECT isnull(position,'total employees') , count(*)AS [# of emp]
	FROM employees
	GROUP BY rollup(position) 
  
  ```
	
	- What is the averag salary of the employee ?
     ```tsql
 	 SELECT ROUND(AVG(Salary),2) as [avg salary]
	 FROM employees
  ```
	
	- in what branch does an employee work and what is their postion ?
     ```tsql
     	SELECT branch_id ,emp_name ,position  
		FROM employees
		order by branch_id
		  
  ```
	
	- Find Employees with the Most Book Issues Processed
	Write a query to find the top 3 employees who have processed the
	most book issues. Display the employee name, number of 
	processed, and their branch.
  ```tsql
  	SELECT top(3)e.emp_id,e.emp_name , COUNT(*) AS [#issues] ,e.branch_id
	FROM employees e
	JOIN issued_status iss
	on e.emp_id = iss.issued_emp_id
	GROUP BY e.emp_id, e.emp_name,branch_id
	ORDER BY [#issues] DESC 
  ```
	
	- How many members do we have ?
     ```tsql
     SELECT COUNT(*) AS [# of members] FROM members

  
  ```
	
	- what is the range of reg date for OUR members ?
     ```tsql
     	SELECT MIN(reg_date) as [first date]
		,MAX(reg_date) as [last_date] 
		FROM members
  
  ```
	
	- List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.
     ```tsql
     SELECT  issued_member_id ,COUNT(*) AS [number of issues]
	FROM issued_status
	GROUP BY issued_member_id
	having COUNT(*)>1
	ORDER BY [number of issues]
  
  ```
	
	- List Members Who Registered since a year or more(longterm)
     ```tsql
  	SELECT * FROM members
	WHERE reg_date <= DATEADD(YEAR,-1,getdate())
  ```

	- OR
     ```tsql
     SELECT * FROM members
	 WHERE DATEDIFF(YEAR,reg_date,getdate()) >=1
  
  ```
	
	- Identify Members with Overdue Books (assume a 30-day return period) Display the member's_id, member's name, book title, issue date, and days overdue.
     ```tsql
     	SELECT iss.issued_member_id , m.member_name 
		, b.book_title,iss.issued_date ,DATEDIFF(DAY ,iss.issued_date ,ISNULL(rs.return_date,getdate())) AS [overdue period]
		FROM issued_status iss
		LEFT JOIN return_status rs
		ON rs.issued_id = iss.issued_id
		join members m
		ON iss.issued_member_id = m.member_id
		join books b
		ON iss.issued_book_isbn= b.isbn
		WHERE DATEDIFF(DAY ,iss.issued_date ,ISNULL(rs.return_date,getdate()))>30
  
  ```
	
	- Create a Table of Active Members
	Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 2 months.
  ```tsql
  	SELECT issued_member_id, COUNT(*) AS [#issues] into active_members
	FROM issued_status
	WHERE DATEDIFF(month ,issued_date , getdate()) <= 2
	GROUP BY issued_member_id
	HAVING COUNT(*) >=1
  ```
	
	- How many books do we have?
     ```tsql
     SELECT COUNT(*) AS [#books ] FROM books
  
  ```
	
	- What is the average rental price excluding outliers?
     ```tsql
  	SELECT AVG(rental_price)
	FROM books
	WHERE isbn <> '978-0-307-37840-1'
  ```
	
	- What is the average rental price including outliers?
     ```tsql
     	SELECT AVG(rental_price)
		FROM books
  
  ```
	
	- the outlier doesnt seem to affect our average that much
     ```tsql
  
  ```
	
	- we may use median
     ```tsql
     SELECT top(1) PERCENTILE_CONT(0.5) WITHIN GROUP(order by rental_price ) over() as [median value]
	FROM books
  
  ```
	
	- What categories of books do we have ?
     ```tsql
     SELECT DISTINCT category
	 FROM books
  
  ```
	
	- how many category of books do we have ?
     ```tsql
     	SELECT count(DISTINCT category) AS [#categories]
		FROM books
  
  ```
	
	- how many books do we have for each category?
     ```tsql
  			SELECT category,count(*) AS [#books/category]
			FROM books
			GROUP BY category
			ORDER BY [#books/category]
  ```
	
	- Find Total Rental Income by Category
     ```tsql
     	SELECT category , sum(rental_price) as [total rental income]
		FROM books
		GROUP BY category
		ORDER BY [total rental income] DESC
  
  ```
	
	
	- Create a Table of Books with Rental Price Above a Certain Threshold let's say average
     ```tsql
     SELECT *  into high_rental_books
	FROM books
	WHERE rental_price >(select avg(rental_price)
	FROM books)
  ```
	
	- what is top 3 category with highest rental price?
     ```tsql
  		SELECT top(3)category,ROUND(AVG(rental_price),2) AS [rental price]
		FROM books
		GROUP BY category 
		ORDER BY [rental price] DESC
  ```
	
	- Retrieve the List of Books Not Yet Returned
     ```tsql
     	SELECT iss.issued_id , book_title
		FROM issued_status iss
		JOIN books b
		ON b.isbn = iss.issued_book_isbn
		LEFT JOIN return_status rs
		ON iss.issued_id = rs.issued_id
		WHERE rs.issued_id is null
  
  ```
	
	- Create Summary Tables: Use CTAS to generate new tables based on query results - each book and total book_issued
     ```tsql
     SELECT issued_book_isbn ,book_title,
	count(*) AS [number of issues ] INTO book_issues_summary
	FROM issued_status iss
	JOIN books b
	ON b.isbn = iss.issued_book_isbn
	GROUP BY issued_book_isbn,book_title
  
  ```
	
	- Update Book Status on Return
	Write a query to return the books and update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).
  ```tsql
  SELECT * FROM return_status
	GO
	CREATE PROC sp_return_update_status @return_id VARCHAR(5),
	@issued_id VARCHAR(5), @return_date DATE,
	@return_book_isbn VARCHAR(17)
	AS
	begin
		BEGIN TRANSACTION
		BEGIN TRY
		INSERT INTO return_status VALUES(@return_id,@issued_id
		,@return_date,@return_book_isbn)
		UPDATE books
		SET status = 'yes'
		WHERE isbn = @return_book_isbn
		PRINT 'thank you for returning the book'
		commit;
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT >0
				ROLLBACK;
			PRINT 'error returning books..';
			PRINT ERROR_MESSAGE();
			throw ;
		END CATCH
	end

  
  ```
	
	- testing
     ```tsql
     /* -- let's borrow  the game of throne book*/
		SELECT * FROM issued_status
		SELECT * FROM return_status
		SELECT * FROM books
		SELECT * FROM members
		INSERT INTO issued_status
		VALUES('IS141','C110',getdate(),'978-0-09-957807-9','E104')
		/*let's return it */
		GO
		DECLARE @date DATE = getdate()
		EXECUTE sp_return_update_status 'RS120',
		'IS141',@date,'978-0-09-957807-9';
  
  ```
	
	- Branch Performance Report
	Create a query that generates a performance report for each
	branch, showing the number of books issued, the number of books
	returned, and the total revenue generated from book rentals.
  ```tsql
    	SELECT br.branch_id,em.emp_name, COUNT(iss.issued_id)AS[#books issued] ,
	COUNT(return_id) AS[#books returned],
	SUM(b.rental_price)AS[total revenue]
	FROM employees e
	JOIN Branch br
	ON e.branch_id= br.branch_id
	JOIN issued_status iss
	ON e.emp_id = iss.issued_emp_id
	LEFT JOIN return_status rs
	ON iss.issued_id = rs.issued_id
	JOIN books b
	ON iss.issued_book_isbn = b.isbn
	LEFT JOIN employees em
	ON em.emp_id = br.manager_id
	GROUP BY br.branch_id , em.emp_name
  
  ```



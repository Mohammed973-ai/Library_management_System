-- CRAUD Operation
/*insert that record  '978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.' in books*/
INSERT INTO books VALUES ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')
/*Update an Existing Member's Address*/
EXEC sp_executesql @sql
UPDATE members
SET member_address = '125 Oak St'
WHERE member_id = 'C103';
/*Delete a Record from the Issued Status Table -- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.*/
BEGIN TRANSACTION
DELETE FROM issued_status
WHERE issued_id = 'IS121'
ROLLBACK;
/*Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.*/
SELECT b.book_title
FROM issued_status i 
JOIN books b
ON b.isbn = i.issued_book_isbn
AND issued_emp_id ='E101'


/*Data cleaning*/
-- check null values
DECLARE @table_name VARCHAR(50) = 'return_status',
@sql NVARCHAR(MAX) = ''
SELECT @sql = STRING_AGG(' SELECT ''' + c.name+''' AS [column name] ,COUNT(*) AS [NULL COUNT] FROM ' +@table_name+' WHERE '+c.name+' IS NULL ',' UNION ALL')
FROM sys.columns c
WHERE c.object_id =OBJECT_ID(@table_name)
-- we found a whole column in return status replace them with the right values
UPDATE rs
SET rs.return_book_isbn = iss.issued_book_isbn
FROM return_status rs
JOIN issued_status iss
ON iss.issued_id = rs.issued_id
---------------------------------------
-- check outliers for salary in employees and rental_price in books 
GO
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
/*No outlier for employees and thre are for books
	ISBN			rental_price lower_fence    upper fence
978-0-307-37840-1		2.50		3.25			9.25   
we may keep it since we cant remove the book from the library and 
 we cant change its price as we are't people who put prices 
 but when doing agg on rental we won't take it in consideration*/
------------------------------------------------------------------
--************************Data Analysis**************************
------------------------------------------------------------------
-- 1. Employee Analysis
-- How many employees do we have ?
SELECT COUNT(*) AS [# of emp]
FROM employees
-- What postions do we have ?
SELECT DISTINCT position 
FROM employees
-- how many employees does each postion have? 
SELECT isnull(position,'total employees') , count(*)AS [# of emp]
FROM employees
GROUP BY rollup(position) 
-- What is the averag salary of the employee ?
SELECT ROUND(AVG(Salary),2) as [avg salary]
FROM employees
-- in what branch does an employee work and what is their postion ?
SELECT branch_id ,emp_name ,position  
FROM employees
order by branch_id
/*Find Employees with the Most Book Issues Processed
Write a query to find the top 3 employees who have processed the
most book issues. Display the employee name, number of 
processed, and their branch.*/
SELECT top(3)e.emp_id,e.emp_name , COUNT(*) AS [#issues] ,e.branch_id
FROM employees e
JOIN issued_status iss
on e.emp_id = iss.issued_emp_id
GROUP BY e.emp_id, e.emp_name,branch_id
ORDER BY [#issues] DESC 

-- How many members do we have ? 
SELECT COUNT(*) AS [# of members] FROM members
-- what is the range of reg date for OUR members ? 
SELECT MIN(reg_date) as [first date]
,MAX(reg_date) as [last_date] 
FROM members
/*List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.*/
SELECT  issued_member_id ,COUNT(*) AS [number of issues]
FROM issued_status
GROUP BY issued_member_id
having COUNT(*)>1
ORDER BY [number of issues]
--List Members Who Registered since a year or more(longterm)
SELECT * FROM members
WHERE reg_date <= DATEADD(YEAR,-1,getdate())
--OR
SELECT * FROM members
WHERE DATEDIFF(YEAR,reg_date,getdate()) >=1
/*Identify Members with Overdue Books (assume a 30-day return period) Display the member's_id, member's name, book title, issue date, and days overdue.*/
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
/*Create a Table of Active Members
Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 2 months.*/
SELECT issued_member_id, COUNT(*) AS [#issues] into active_members
FROM issued_status
WHERE DATEDIFF(month ,issued_date , getdate()) <= 2
GROUP BY issued_member_id
HAVING COUNT(*) >=1
-- How many books do we have? 
SELECT COUNT(*) AS [#books ] FROM books
--What is the average rental price excluding outliers?
SELECT AVG(rental_price)
FROM books
WHERE isbn <> '978-0-307-37840-1'
--What is the average rental price including outliers?
SELECT AVG(rental_price)
FROM books
-- the outlier doesnt seem to affect our average that much
-- we may use median 
SELECT top(1) PERCENTILE_CONT(0.5) WITHIN GROUP(order by rental_price ) over() as [median value]
FROM books
-- What categories of books do we have ?
SELECT DISTINCT category
FROM books
-- how many category of books do we have ?
SELECT count(DISTINCT category) AS [#categories]
FROM books
-- how many books do we have for each category?
SELECT category,count(*) AS [#books/category]
FROM books
GROUP BY category
ORDER BY [#books/category]
---Find Total Rental Income by Category
SELECT category , sum(rental_price) as [total rental income]
FROM books
GROUP BY category
ORDER BY [total rental income] DESC

--List Employees with Their Branch Manager's Name and their branch details
--Create a Table of Books with Rental Price Above a Certain Threshold let's say average
SELECT *  into high_rental_books
FROM books
WHERE rental_price >(select avg(rental_price)
FROM books)
SELECT * FROM high_rental_books
-- what is top 3 category with highest rental price?
SELECT top(3)category,ROUND(AVG(rental_price),2) AS [rental price]
FROM books
GROUP BY category 
ORDER BY [rental price] DESC
--Retrieve the List of Books Not Yet Returned
SELECT iss.issued_id , book_title
FROM issued_status iss
JOIN books b
ON b.isbn = iss.issued_book_isbn
LEFT JOIN return_status rs
ON iss.issued_id = rs.issued_id
WHERE rs.issued_id is null
/*Create Summary Tables: Use CTAS to generate new tables based on query results - each book and total book_issued*/
SELECT issued_book_isbn ,book_title,
count(*) AS [number of issues ] INTO book_issues_summary
FROM issued_status iss
JOIN books b
ON b.isbn = iss.issued_book_isbn
GROUP BY issued_book_isbn,book_title
/*Update Book Status on Return
Write a query to return the books and update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).*/
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
-- testing
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
/*Branch Performance Report
Create a query that generates a performance report for each
branch, showing the number of books issued, the number of books
returned, and the total revenue generated from book rentals.*/

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

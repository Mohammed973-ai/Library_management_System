# Library_management_System
A comprehensive SQL-based library management system demonstrating end-to-end database development, from conceptual design to advanced analytics.

## Project Overview
This project showcases the complete implementation of a Library Management System using SQL, covering database design, data modeling,
ETL processes, and business intelligence reporting for library operations.



<img width="1500" height="1000" alt="image" src="https://github.com/user-attachments/assets/e1b3f5d9-dfe4-457c-a151-c5176b892ef3" />




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
* Designed an Entity-Relationship Diagram (ERD) to visualize table relationships and dependencies

__3. ETL Process__

* Extracted data from source files
* Transformed and cleaned data to meet database requirements
* Loaded processed data into the database ready for analysis

__4. Database Schema__
The system manages six core entities:

employees - Staff information and branch assignments
members - Library member profiles and registration data
books - Book inventory with categories, pricing, and availability status
Branch - Branch locations with manager assignments and contact details
issued_status - Book issue transaction records
return_status - Book return records and tracking


## 1. Data Modeling & Normalization

* There were 6 excel files 1 for each entity so I drew these entities and checked their normal form degree  



<img width="1029" height="562" alt="image" src="https://github.com/user-attachments/assets/daf9ec38-4c8f-4ced-a0c8-f5a375bcce43" />



<img width="1102" height="586" alt="image" src="https://github.com/user-attachments/assets/234f8363-0e39-4e2e-b1d6-0fbec478145b" />



<img width="1118" height="630" alt="image" src="https://github.com/user-attachments/assets/912c4aba-fad7-4c2a-8c37-548d1818017e" />


## 2. Database Design & Implementation

### ERD


<img width="1395" height="723" alt="image" src="https://github.com/user-attachments/assets/f96d2035-b07b-40ff-a254-f9baba3833b5" />




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












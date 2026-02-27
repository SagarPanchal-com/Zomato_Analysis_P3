# SQL Project: Data Analysis for Zomato – A Food Delivery Company

## Project Overview

This project demonstrates advanced SQL problem-solving skills through the analysis of data for a simulated food delivery company inspired by Zomato. The project includes database setup, data import, data cleaning, handling null values, and solving multiple business problems using optimized SQL queries. The primary objective is to extract actionable business insights related to customer behavior, restaurant performance, rider efficiency, and revenue trends.

![Library_project](https://github.com/SagarPanchal-com/Zomato_Analysis_P3/blob/main/Zomato-Logo.jpg)

## Project Structure
**Database Setup**: Creation of the zomato_db database and required tables.
**Data Import**: Inserting structured sample data into tables.
**Data Cleaning**: Handling null values and ensuring data integrity.
**Business Problems**: Solving 20 real-world business cases using SQL queries.

## Database Setup
![ERD](https://github.com/SagarPanchal-com/Zomato_Analysis_P3/blob/main/Zomato_ERD.png)

- **Database Creation**:
Created a database named `Zomato_db`.

```sql
Create Database Zomato_db;
Use Zomato_db;
```
- **1. Dropping Existing Tables**

```sql
DROP TABLE IF EXISTS Orders;
DROP TABLE IF EXISTS Customers;
DROP TABLE IF EXISTS Restaurants;
DROP TABLE IF EXISTS Riders;
DROP TABLE IF EXISTS Deliveries;
```
- **2. Creating Tables**

```sql
-- Creating Customers Table
Create Table Customers
	(
		customer_id INT PRIMARY KEY,
        customer_name VARCHAR(25),
        reg_date Date
	);

-- Creating Restaurants Table
Create Table Restaurants
	(
		restaurant_id INT PRIMARY KEY,
        restaurant_name VARCHAR(55),
        city VARCHAR(15),
        opening_hours VARCHAR(55)
	);

-- Creating Orders Table
Create Table Orders
	(
		order_id INT PRIMARY KEY,
		customer_id INT,
		restaurant_id INT,
		order_item VARCHAR(55), -- this is comingfrom cx table
		order_date DATE, -- this is coming from restaurant Table
		order_time TIME,
		order_status VARCHAR(55),
		total_amount FLOAT
    );

-- Adding FK Constraint
Alter table Orders
add constraint fk_customers
foreign key (customer_id)
references Customers(customer_id);

-- Adding FK Constraint
Alter table Orders
add constraint fk_restaurants
foreign key (restaurant_id)
references Restaurants(restaurant_id);

-- Creating Riders Table
Create Table Riders
	(
		rider_id INT PRIMARY KEY,
        rider_name VARCHAR(55),
        sign_up_date DATE
	);

-- Creating Deliveries
Create Table Deliveries
	(
		delivery_id INT PRIMARY KEY,
        order_id INT, -- this coming from order table
        delivery_status VARCHAR(35),
        delivery_time TIME,
        rider_id INT -- this coming from riders table
	);

-- Adding FK Constraint
Alter table Deliveries
add constraint fk_orders
foreign key (order_id)
references Orders(order_id);

-- Adding FK Constraint
Alter table Deliveries
add constraint fk_riders
foreign key (rider_id)
references Riders(rider_id);
```

### Data Import

### Data Cleaning and Handling Null Values
Before performing analysis, I ensured that the data was clean and free from null values where necessary. For instance:
```sql
UPDATE orders
SET total_amount = COALESCE(total_amount, 0);
```
### Business Problems Solved

**Task 1: Write a query to find the top 5 most frequently ordered dishes by customer called "Arjun Mehta" in the last 2.5 year.**

```sql
Select * from
(Select b.order_item, Count(*) as CNT,
dense_rank() over(order by Count(*) desc) as Most_Ordered
from Customers a
join Orders b On a.Customer_id = b.Customer_id
Where Order_date >= Curdate() - Interval 30 Month
And Customer_name = "Arjun Mehta"
Group by b.order_item) as X
where Most_Ordered <= 5;
```

**Task 2: Popular Time Slots**: Identify the time slots during which the most orders are placed. based on 2-hour intervals.

***Approach 1***:
```sql
SELECT
    CASE
        WHEN HOUR(order_time) >= 0  AND HOUR(order_time) < 2  THEN '00:00 - 02:00'
        WHEN HOUR(order_time) < 4  THEN '02:00 - 04:00'
        WHEN HOUR(order_time) < 6  THEN '04:00 - 06:00'
        WHEN HOUR(order_time) < 8  THEN '06:00 - 08:00'
        WHEN HOUR(order_time) < 10 THEN '08:00 - 10:00'
        WHEN HOUR(order_time) < 12 THEN '10:00 - 12:00'
        WHEN HOUR(order_time) < 14 THEN '12:00 - 14:00'
        WHEN HOUR(order_time) < 16 THEN '14:00 - 16:00'
        WHEN HOUR(order_time) < 18 THEN '16:00 - 18:00'
        WHEN HOUR(order_time) < 20 THEN '18:00 - 20:00'
        WHEN HOUR(order_time) < 22 THEN '20:00 - 22:00'
        ELSE '22:00 - 00:00'
    END AS time_slot,
    COUNT(order_id) AS order_count
FROM orders
GROUP BY time_slot
ORDER BY order_count DESC;
```
***Approach 2***:
```sql
Select
	Floor(Hour(order_time)/2)*2 as Start_time,
    Floor(Hour(order_time)/2)*2 + 2 as End_time,
    count(*) as Orders_Count
from Orders
group by 1,2
order by 3 desc;
```

**Task 3: Order Value Analysis**
-- Question: Find the average order value per customer who has placed more than 300 orders.
-- Return customer_name, and aov (average order value)

```sql
Select 
	a.Customer_id,
    b.Customer_name,
	Count(a.order_id) as Total_Orders,
    Avg(a.Total_amount) as Average_Sum
from orders a
join 
Customers b
On a.Customer_id = b.Customer_id
Group by 1
having Total_Orders >= 300;

```

**Task 4: High-Value Customers**
-- Question: List the customers who have spent more than 140K in total on food orders.
-- return customer_name, and customer_id.

```sql
Select 
	a.Customer_id,
    b.Customer_name,
    Sum(a.Total_amount) as Total_Sum
from orders a
join 
Customers b
On a.Customer_id = b.Customer_id
Group by 1
having Total_Sum >= 140000;
```


**Task 5: Orders Without Delivery**
-- Question: Write a query to find orders that were Completed but not delivered.
-- Return each restuarant name, city and number of not delivered orders.

```sql
Select
	b.Restaurant_name,
    b.city,
    Count(c.order_id) as Total_Not_Del
from Orders a
join
Restaurants b 
	On a.restaurant_id = b.restaurant_id
join
Deliveries c
	On a.order_id = c.order_id
Where a.order_status = "Completed"
AND (c.Delivery_status = "Not Delivered" OR c.Delivery_status  Is null)
Group by 1,2;
```

**Task 6: Restaurant Revenue Ranking**:
-- Rank restaurants by their total revenue in last 30 Months, including their name, total revenue, and rank within their city.

```sql
With ranking_table
As
(
	Select 
		a.city,
		a.restaurant_name,
		Sum(b.total_amount) as Total_Revenue,
		Rank() over(Partition by a.city order by Sum(b.total_amount) desc) as Rnk
	from Restaurants a
	join
	Orders b
		On a.restaurant_id = b.restaurant_id
	Where b.order_date >= Curdate() - interval 30 Month
	Group by 1,2
)
Select
	*
from ranking_table
where rnk = 1;
```

**Task 7: Most Popular Dishy by City**:
-- Identify the most popular dish in each city based on the number of orders.

```sql
Select * from 
(
Select
	b.City,
    a.order_item,
    count(a.order_id) as Cnt,
    Rank() over(partition by b.city order by count(a.order_id) desc) as Rnk
from Orders a
join
Restaurants b
	On a.restaurant_id = b.restaurant_id
group by 1,2
) as X
where rnk = 1;
```

**Task 8: Customer Churn**:
-- Question: Find Total No. Of Orders Done by Customers in 2023 And 2024.

```sql
SELECT 
    customer_id,
    SUM(CASE WHEN YEAR(order_date) = 2023 THEN 1 ELSE 0 END) AS orders_2023,
    SUM(CASE WHEN YEAR(order_date) = 2024 THEN 1 ELSE 0 END) AS orders_2024
FROM Orders
GROUP BY customer_id;
```

**Task 9: Find customers who haven't placed an order in 2024 but did in 2023**:
```sql
Select Distinct Customer_id
from orders
	where Year(order_date) = 2023
	AND
	Customer_id Not in
    (Select customer_id from Orders where Year(order_date) = 2024);
```

**Task 10: Cancellation Rate Comparison**:
-- Calculate and compare the order cancellation rate (where delivery ID is NULL) for each restaurant between the current year and the previous year.

```sql
SELECT
    a.restaurant_id,

    ROUND(
        SUM(CASE WHEN YEAR(a.order_date) = 2023 AND b.delivery_id IS NULL THEN 1 ELSE 0 END)
        /
        NULLIF(SUM(CASE WHEN YEAR(a.order_date) = 2023 THEN 1 ELSE 0 END), 0)
        * 100
    , 2) AS cancel_rate_2023,

    ROUND(
        SUM(CASE WHEN YEAR(a.order_date) = 2024 AND b.delivery_id IS NULL THEN 1 ELSE 0 END)
        /
        NULLIF(SUM(CASE WHEN YEAR(a.order_date) = 2024 THEN 1 ELSE 0 END), 0)
        * 100
    , 2) AS cancel_rate_2024

FROM Orders a
LEFT JOIN Deliveries b 
    ON a.order_id = b.order_id
GROUP BY a.restaurant_id;
```

**Task 11: Create a Table of Books with Rental Price Above a Certain Threshold 7USD**:
```sql
Create Table High_Rent_Books as
select * from (Select * from Books where Rental_price > 7) as a;

Select * from High_Rent_Books;
```

**Task 12: Retrieve the List of Books Not Yet Returned**
```sql
Select DISTINCT Issued_book_name from Issued_Status where issued_id not in (Select issued_id from Return_status);
```

## Advanced SQL Operations

**Inserting Some New Values**
```sql
INSERT INTO issued_status(issued_id, issued_member_id, issued_book_name, issued_date, issued_book_isbn, issued_emp_id)
VALUES ('IS151', 'C118', 'The Catcher in the Rye', CURRENT_DATE - INTERVAL 24 day,  '978-0-553-29698-2', 'E108'),
('IS152', 'C119', 'The Catcher in the Rye', CURRENT_DATE - INTERVAL 13 day,  '978-0-553-29698-2', 'E109'),
('IS153', 'C106', 'Pride and Prejudice', CURRENT_DATE - INTERVAL 7 day,  '978-0-14-143951-8', 'E107'),
('IS154', 'C105', 'The Road', CURRENT_DATE - INTERVAL 32 day,  '978-0-375-50167-0', 'E101');
```

**Adding new column in return_status**
```sql
ALTER TABLE return_status
ADD Column book_quality VARCHAR(15) DEFAULT('Good');

UPDATE return_status
SET book_quality = 'Damaged'
WHERE issued_id 
    IN ('IS112', 'IS117', 'IS118');
SELECT * FROM return_status;
```

**Task 13: Identify Members with Overdue Books**  
Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's_id, member's name, book title, issue date, and days overdue.

```sql
SELECT 
    a.issued_member_id,
    b.member_name,
    c.book_title,
    a.issued_date,
    DATEDIFF(CURDATE(), a.issued_date) AS over_dues_days
FROM issued_status AS a
JOIN members AS b
    ON b.member_id = a.issued_member_id
JOIN books AS c
    ON c.isbn = a.issued_book_isbn
LEFT JOIN return_status AS d
    ON d.issued_id = a.issued_id
WHERE 
    d.return_date IS NULL
    AND DATEDIFF(CURDATE(), a.issued_date) > 30
ORDER BY over_dues_days DESC;
```

**Task 14: Branch Performance Report**  
Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.

```sql
Create Table Branch_Performance_Report As
Select
	a.Branch_id,
    a.Manager_id,
    Count(c.issued_id) as No_of_books_Issued,
    Count(d.Return_id) as No_of_books_Retrned,
    Sum(e.Rental_Price) as Total_Revenus_Generated
from
	Branch as a
join
	Employees as b
		On a.Branch_id = b.Branch_id
join
	Issued_status as c
		On b.emp_id = c.Issued_emp_id
Left join
	Return_status as d
		On c.issued_id = d.Issued_id
Join
	Books as e
		On c.Issued_book_isbn = e.isbn
Group by 1,2;

Select * from Branch_Performance_Report;
```

**Task 15: CTAS: Create a Table of Active Members**  
Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 2 months.

```sql

Create Table Active_Members as
Select * from Members
Where Member_id in
	(Select Distinct issued_member_id as Members from Issued_status where Datediff(CurDate(),Issued_date) <= 60);

Select * from Active_Members;

```


**Task 16: Find Employees with the Most Book Issues Processed**  
Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.

```sql
Select
            a.emp_name,
            c.*,
            Count(b.issued_id) as No_of_Books_Processed
From
	Employees as a
Join
	Issued_status as b
		On a.emp_id = b.issued_emp_id
Join
	Branch as c
		On a.Branch_id = c.Branch_id
Group by 1,2;
```

## Reports

- **Database Schema**: Detailed table structures and relationships.
- **Data Analysis**: Insights into book categories, employee salaries, member registration trends, and issued books.
- **Summary Reports**: Aggregated data on high-demand books and employee performance.

## Conclusion

This project demonstrates the application of SQL skills in creating and managing a library management system. It includes database setup, data manipulation, and advanced querying, providing a solid foundation for data management and analysis.

## Author - SAGAR PANCHAL

This project showcases SQL skills essential for database management and analysis.

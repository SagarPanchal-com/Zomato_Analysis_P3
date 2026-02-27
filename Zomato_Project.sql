-- ********************
-- ZOMATO DATA ANALYSES
-- ********************

Create Database Zomato_db;
Use Zomato_db;

DROP TABLE IF EXISTS Orders;
DROP TABLE IF EXISTS Customers;
DROP TABLE IF EXISTS Restaurants;
DROP TABLE IF EXISTS Riders;
DROP TABLE IF EXISTS Deliveries;

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

-- **************
-- END of Schemas
-- **************

-- IMPORTING DATA
Select * from Customers;
Select * from Restaurants;
Select * from Orders;
Select * from Riders;
Select * from Deliveries;

-- *****************
-- Analysis & Report
-- *****************

-- Q.1 Write a query to find the top 5 most frequently ordered dishes by customer called "Arjun Mehta" in the last 2.5 year.

Select * from
(Select b.order_item, Count(*) as CNT,
dense_rank() over(order by Count(*) desc) as Most_Ordered
from Customers a
join Orders b On a.Customer_id = b.Customer_id
Where Order_date >= Curdate() - Interval 30 Month
And Customer_name = "Arjun Mehta"
Group by b.order_item) as X
where Most_Ordered <= 5;

-- 2. Popular Time Slots
-- Question: Identify the time slots during which the most orders are placed. based on 2-hour intervals.

-- Approach 1
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

-- Approach 2
Select
	Floor(Hour(order_time)/2)*2 as Start_time,
    Floor(Hour(order_time)/2)*2 + 2 as End_time,
    count(*) as Orders_Count
from Orders
group by 1,2
order by 3 desc;

-- 3. Order Value Analysis
-- Question: Find the average order value per customer who has placed more than 300 orders.
-- Return customer_name, and aov (average order value)

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

-- 4. High-Value Customers
-- Question: List the customers who have spent more than 140K in total on food orders.
-- return customer_name, and customer_id!

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

-- 5. Orders Without Delivery
-- Question: Write a query to find orders that were Completed but not delivered.
-- Return each restuarant name, city and number of not delivered orders

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

-- Q.6
-- Restaurant Revenue Ranking:
-- Rank restaurants by their total revenue in last 30 Months, including their name,
-- total revenue, and rank within their city.

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

-- Q. 7
-- Most Popular Dishy by City:|
-- Identify the most popular dish in each city based on the number of orders.

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

-- Q.8 Customer Churn:
-- Find Total No. Of Orders Done by Customers in 2023 And 2024.

SELECT 
    customer_id,
    SUM(CASE WHEN YEAR(order_date) = 2023 THEN 1 ELSE 0 END) AS orders_2023,
    SUM(CASE WHEN YEAR(order_date) = 2024 THEN 1 ELSE 0 END) AS orders_2024
FROM Orders
GROUP BY customer_id;

-- Q.9 Find customers who haven't placed an order in 2024 but did in 2023.

Select Distinct Customer_id
from orders
	where Year(order_date) = 2023
	AND
	Customer_id Not in
    (Select customer_id from Orders where Year(order_date) = 2024);
    
-- Q.10 Cancellation Rate Comparison:
-- Calculate and compare the order cancellation rate (where delivery ID is NULL) for each restaurant between the
-- current year and the previous year.

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

-- Q.11 Rider Average Delivery Time:
-- Determine each rider's average delivery time.

SELECT 
    b.rider_id,
    SEC_TO_TIME(
        ROUND(AVG(
            CASE 
                WHEN b.delivery_time >= c.order_time THEN
                    TIME_TO_SEC(b.delivery_time) - TIME_TO_SEC(c.order_time)
                ELSE
                    TIME_TO_SEC(b.delivery_time) - TIME_TO_SEC(c.order_time) + 86400
            END
        ))
    ) AS avg_delivery_time
FROM Deliveries b
JOIN Orders c 
    ON b.order_id = c.order_id
WHERE b.delivery_status = 'Delivered'
GROUP BY b.rider_id;

-- Q.12 Monthly Restaurant Growth Ratio:
-- Calculate each restaurant's growth ratio based on the total number of delivered orders since its joining

Select 
	*,
    Round((((Cnt-Last_month)/Last_Month) * 100),2) as Growth_Rate
From
(Select
	a.Restaurant_id,
    date_format(a.order_date,'%y-%m') as Order_Month,
    Count(a.Order_id) as Cnt,
    Lag(Count(a.Order_id)) over(partition by Restaurant_id order by date_format(a.order_date,'%y-%m')) as Last_Month
From Orders as a
Join
Deliveries as b
	On a.order_id = b.Order_id
		Where Delivery_status = "Delivered"
Group by 1,2) as X;

-- Q.13 Customer Segmentation:
-- Customer Segmentation: Segment customers into 'Gold' or 'Silver' groups based on their total spending
-- compared to the Overall average order value (AOV). If a customer's total spending exceeds the AOV,
-- label them as 'Gold'; otherwise, label them as 'Silver'. Write an SQL query to determine each segment's
-- total number of orders and total revenue

Select
	*,
    CASE
		WHEN Total_revenue >= AOV THEN "Gold"
        ELSE "Silver"
	END as Segment
from
(Select
	Customer_id,
    Count(order_id) as No_Of_Orders,
    Sum(total_amount) as Total_revenue,
    (Select Sum(total_amount)/Count(Distinct Customer_id) from Orders) as AOV
from Orders
Group by 1) as X;

-- Q.14 Rider Monthly Earnings:
-- Calculate each rider's total monthly earnings, assuming they earn 8% of the order amount.

Select
	c.Rider_id,
    date_format(a.order_date,'%y-%m') as Sales_Month,
    (Sum(a.Total_amount)*0.08) as Earning
From Orders a
Join
Deliveries b
	On a.order_id = b.order_id
Join
Riders c
	On b.Rider_id = c.Rider_id
		Where b.Delivery_status = "Delivered"
Group by 1,2
Order by 1,2;

-- Q.15 Rider Ratings Analysis:
-- Find the number of 5-star, 4-star, and 3-star ratings each rider has.
-- riders receive this rating based on delivery time.
-- If orders are delivered less than 120 minutes of order received time the rider get 5 star rating,
-- if they deliver 120 and 300 minute they get 4 star rating
-- if they deliver after 300 minute they get 3 star rating.

Select
	*,
    Case
		When Total_time < 120 then "5 Star"
        When Total_time between 120 and 300 then "4 Star"
        Else "3 Star"
	End as Ratings
from
(Select
	c.Rider_id,
    a.order_id,
    a.Order_time,
    b.Delivery_time,
    (
		CASE
			When b.Delivery_time >= a.Order_time
				Then time_to_sec(b.Delivery_time) - time_to_sec(a.Order_time)
			Else
				time_to_sec(b.Delivery_time) - time_to_sec(a.Order_time) + 86400
		End
	) / 60 as Total_Time
from Orders a
Join
Deliveries b
	On a.order_id = b.Order_id
Join
Riders c
	On b.Rider_id = c.Rider_id) as X;

-- Q.16 Order Frequency by Day:
-- Analyze order frequency per day of the week and identify the peak day for each restaurant.

Select * from
(Select
	b.Restaurant_id,
    dayname(a.order_date) as Week_Day,
	Count(a.order_id) as CNT,
    Rank() over(Partition by b.Restaurant_id order by Count(a.order_id) desc) as Rnk
from Orders a
Join
Restaurants b
	ON a.Restaurant_id = b.Restaurant_id
Group by 1,2) as X
Where Rnk = 1;

-- Q.17 Customer Lifetime Value (CLV):
-- Calculate the total revenue generated by each customer over all their orders.

Select
	a.Customer_id,
    b.Customer_name,
    sum(a.total_amount) as Total_Revenue
from Orders a
join
Customers b
	On a.Customer_id =b.Customer_id
Group by 1,2
Order by 1,2;

-- Q.18 Monthly Sales Trends:
-- Identify sales trends by comparing each month's total sales to the previous month.

Select
	Year(order_date) as Sales_Year,
    Month(order_date) as Sales_Month,
    Sum(total_amount) as Total_Sales,
    Lag(Sum(total_amount)) over(order by Year(order_date),Month(order_date)) as Last_Month_Sales
From Orders
Group by 1,2;

-- Q.19 Order Item Popularity:
-- Track the popularity of specific order items over time and identify seasonal demand spikes.

Select
	Order_item,
    Seasons,
    Sum(Total_amount) as Sales
From
(Select
	*,
    CASE
		WHEN Month(Order_date) Between 4 and 6 then "Spring"
        WHEN Month(Order_date) > 6 AND Month(Order_date) < 9 then "Summer"
        ELSE "Winter"
	END as Seasons
from Orders) as X
Group by 1,2
order by 1, 3 Desc;

-- Q.20 Rank each city based on the total revenue for last year 2023

Select
	b.city,
    Sum(a.total_amount) as Total_Revenue,
    Rank() over(order by Sum(a.total_amount) desc) as Rnk
from Orders a
join
Restaurants b
	On a.restaurant_id = b.restaurant_id
Group by 1;

-- **************
-- END OF PROJECT
-- **************

create database zepto_delivery;
use zepto_delivery;
-- customers table 
CREATE TABLE customers (
    customer_id VARCHAR(10) PRIMARY KEY,
    location VARCHAR(20),
    loyalty_score INT,
    signup_date DATE
);
-- agents table
CREATE TABLE agents (
    agent_id VARCHAR(10) PRIMARY KEY,
    assigned_zone VARCHAR(20),
    on_time_pct DECIMAL(5,2),
    rating DECIMAL(3,2)
);
-- products table
CREATE TABLE products (
    product_id VARCHAR(10) PRIMARY KEY,
    name VARCHAR(50),
    category VARCHAR(30),
    price DECIMAL(6,2)
);
-- orders table
CREATE TABLE orders (
    order_id VARCHAR(10) PRIMARY KEY,
    customer_id VARCHAR(10),
    delivery_agent_id VARCHAR(10),
    order_time DATETIME,
    delivery_time DATETIME,
    delay_minutes DECIMAL(5,2),
    zone VARCHAR(20),
    weather_condition VARCHAR(20),
    status VARCHAR(20),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (delivery_agent_id) REFERENCES agents(agent_id)
);
-- deliveries
CREATE TABLE deliveries (
    order_id VARCHAR(10) PRIMARY KEY,
    pickup_time DATETIME,
    drop_time DATETIME,
    actual_duration_minutes DECIMAL(5,2),
    is_late BOOLEAN,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);
-- order_items
CREATE TABLE order_items (
    order_id VARCHAR(10),
    product_id VARCHAR(10),
    quantity INT,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

select count(*) from orders;
select count(*) from agents;
select count(*) from products;
select count(*) from customers;
select count(*) from deliveries;
select count(*) from order_items;

# SQL Analysis for Zepto Project

-- 1. Order and Delivery Overview

-- 1.1 How many total orders were placed?
select count(*) as total_orders
from orders;

# insights
-- This gives us the total orders- 20389


-- 1.2 How many orders were delivered late vs. on time?
select sum(is_late=0)as on_time, sum(is_late=1)as late
from deliveries;

# insights
-- only 5.2%(1016) of total deliveries are delivered late


-- 1.3 What is the average actual delivery duration across all deliveries?
select round(avg(actual_duration_minutes),2) as 'average actual delivery duration'
from deliveries;

# insights
--  The average actual delivery duration is 13.08 min


--  2. Agent Performance

-- 2.1 What is the average rating of agents, grouped by their assigned zone?
select assigned_zone, round(avg(rating),2)as avg_rating
from agents
group by assigned_zone;

# insights
-- WEST zone has the highest average rating of agents (4.06)
-- SOUTH zone has the lowest average rating of agents (3.88)
-- however there is only minimal  difference across the zone 

-- 2.2 Which agent has the highest number of on-time deliveries?
with highest_on_time_deliveries as (select o.delivery_agent_id as agent_id,count(d.is_late)as on_time_delivery
from deliveries d
join orders o 
on d.order_id=o.order_id
where d.is_late=0
group by o.delivery_agent_id
)
select agent_id,on_time_delivery
from highest_on_time_deliveries
order by on_time_delivery desc
limit 1;

# insights
-- agent with id 'AGNT0488' has the most on_time delivery (59)
-- and we have 3 agents who hold the second highest on_time deliveries (54)


-- 2.3 List the top 5 agents based on total deliveries handled.
select distinct o.delivery_agent_id as agent_id,
       count(*) over (partition by o.delivery_agent_id) as total_deliveries_handled
from deliveries d 
join orders o 
on d.order_id=o.order_id
order by total_deliveries_handled desc
limit 5;

# insights
-- we have agent with id 'AGNT0488' who handled 62 total_deliveries 


--  3. Zone-wise Patterns

-- 3.1 What is the total number of deliveries in each delivery zone?
select o.zone, count(*) as total_deliveries
from deliveries d 
join orders o
on d.order_id=o.order_id
group by o.zone
order by total_deliveries desc;

# insights
-- WEST zone holds the highest deliveries
-- EAST zone holds the least deliveries 


-- 3.2 Which zone has the highest late delivery percentage?
select c.location, round(sum(d.is_late=1)*100 / count(*), 2) as ldp
from deliveries d
join orders o
on d.order_id=o.order_id
join customers c
on o.customer_id=c.customer_id
group by c.location
order by ldp desc
limit 1; 

# insights
-- NORTH zone with 5.27% holds the highest % of late deliveries


-- 4. Customer Insights

-- 4.1 Which customer placed the most orders?
select customer_id,count(*) as total_orders
from orders 
group by customer_id
order by total_orders desc
limit 2;

# insights
-- Both customers with id 'CUST3876' and 'CUST4376' have ordered 13 times 


-- 4.2 Find customers with more than 10 orders and their average delivery delay.
select c.customer_id, count(*) as no_of_orders ,round(avg(delay_minutes),2)as avg_delivery_delay
from customers c 
join orders o
on c.customer_id=o.customer_id
group by c.customer_id
having no_of_orders >10
order by no_of_orders,avg_delivery_delay desc;

# insights
-- these are our regular customers who have ordered more and 10times.
-- we can try to deliver as early as possible to keep them engaged
 
  
-- 4.3 Which zone has the highest number of customers?
select location, count(*) as no_of_customers
from customers
group by location
order by no_of_customers desc;

# insights
-- CENTRAL zone holds the most number of customers.
-- we can try to increase the no of delivery agents in this zone for smooth delivery without delays 


-- 5. Product Analysis

-- 5.1 What are the top 5 most ordered product categories?
select p.category as product_categories,count(o.order_id)as no_of_orders
from products p
join order_items i
on p.product_id=i.product_id
join orders o
on i.order_id=o.order_id
group by p.category
order by no_of_orders desc
limit 5;

# insights 
-- FRUITS are the most ordered product category.Then comes beverages
-- we can increase stocks of these product categories to increase sales


-- 5.2 Which product has generated the highest total quantity ordered?
select p.name as product_name, sum(i.quantity) as total_quantity_ordered
from products p
join order_items i
on p.product_id=i.product_id
group by p.name
order by total_quantity_ordered desc;

# insights
-- 'product_28' has  generated the highest total quantity ordered (629 quantities) 
 

-- 5.3 What is the average quantity ordered per product?
select p.name as product_name, round(avg(i.quantity),2)as avg_quantity_ordered
from products p
join order_items i
on p.product_id=i.product_id
group by p.name
order by avg_quantity_ordered desc;

# insights
-- the average quantity ordered per product falls between 3.23-2.67 
-- 3 products are ordered on average 


 --  6. Time-Based Trends

-- 6.1 What is the average delivery duration by day of the week?
select dayname(pickup_time) as day_of_the_week,
       round(avg(actual_duration_minutes),2) as avg_delivery_duration
from deliveries
group by day_of_the_week ;

# insights
-- 13 min in the average delivery duration across all days of the week


-- 6.2 How many orders were placed in each month?
select monthname(order_time)as months,count(*) as no_of_orders
from orders
group by months
order by no_of_orders desc;

# insights
-- MAY month has the most no of orders
-- FEBRUARY month has the least orders 
 
-- 6.3 What is the hourly trend of pickups?
select hour(pickup_time)as hours, count(*) as no_of_pickups
from deliveries
group by hours
order by hours ;

# insights 
-- we can observe that in the evening around 6pm there are more no of pickups. 
-- we can make sure there are enough products and delivery agents available
-- and in the afternoon 12pm we have the least pickups


--  7. Multi-Table Joins (Intermediate)

-- 7.1 For each agent, what is their total number of orders and average delivery time?
select a.agent_id ,
	   count(*) as total_orders,
	   round(avg(d.actual_duration_minutes),2) as avg_delivery_time
from orders o
join agents a
on o.delivery_agent_id=a.agent_id
join deliveries d
on o.order_id=d.order_id
group by a.agent_id
order by total_orders desc;

-- 7.2 Which product categories are associated with the most late deliveries?
select p.category as product_category, sum(d.is_late=1) as late_deliveries
from deliveries d
join order_items oi
on d.order_id=oi.order_id
join products p
on oi.product_id=p.product_id
group by product_category
order by late_deliveries desc;

# insights 
-- mostly fruits and beverages are delivered late 

-- 7.3 List all orders with customer id, agent id, pickup and drop times, and delivery status.
select o.customer_id,a.agent_id,d.pickup_time,d.drop_time,status
from orders o
join agents a
on o.delivery_agent_id=a.agent_id
join deliveries d
on o.order_id=d.order_id




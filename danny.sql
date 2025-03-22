CREATE database dannys_diner;
use dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');


  ----------------------------------
-- CASE STUDY #1: DANNY'S DINER --
----------------------------------

-- Author: Vishwas M S
-- Date: 
-- Tool used: MySQL Server

/* --------------------
   Case Study Questions
   --------------------*/
  
-- 1. What is the total amount each customer spent at the restaurant?

select s.customer_id, CONCAT('$',' ',sum(m.price)) as total_sales
from sales s 
join menu m on s.product_id = m.product_id
group by s.customer_id
order by s.customer_id;
   
-- 2. How many days has each customer visited the restaurant?

 select customer_id,COUNT(distinct order_date) as days_visited 
 from sales
 group by customer_id
 order by customer_id;
 
-- 3. What was the first item from the menu purchased by each customer?
-- order_date column is a date column does not include the purchase time details. 
-- Asssumption: Since the timestamp is missing, all items bought on the first day is considered as the first item(provided multiple items were purchased on the first day)
-- dense_rank() is used to rank all orders purchased on the same day 

with order_info_cte as (select s.customer_id,s.order_date,s.product_id,m.product_name,m.price,
	DENSE_RANK() over(partition by s.customer_id order by s.order_date) as item_rank
from sales s
join menu m on s.product_id = m.product_id )
select customer_id,product_name
from order_info_cte
where item_rank = 1
group by customer_id,product_name;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select top 1 m.product_name,count(s.product_id) as order_count
from sales s
join menu m on s.product_id = m.product_id
group by m.product_name
order by order_count desc;

-- 5. Which item was the most popular for each customer?
-- Asssumption: Products with the highest purchase counts are all considered to be popular for each customer

with order_info as (select s.customer_id,m.product_name, COUNT(m.product_name) as order_count,
	DENSE_RANK() over(partition by s.customer_id order by COUNT(m.product_name) desc) as rank_num
from sales s
join menu m  on s.product_id = m.product_id
group by s.customer_id,m.product_name)
select customer_id,product_name
from order_info
where rank_num = 1
order by customer_id;

-- 6. Which item was purchased first by the customer after they became a member?

with order_info as (select s.customer_id,s.order_date,mb.join_date,m.product_name, 
	ROW_NUMBER() over(partition by s.customer_id order by s.customer_id,s.order_date ) as rnum
from sales s
inner join menu m on s.product_id = m.product_id
inner join members mb on s.customer_id = mb.customer_id
where s.order_date > mb.join_date)
select customer_id,product_name
from order_info
where rnum = 1;

-- 7. Which item was purchased just before the customer became a member?

with order_info as (select s.customer_id,s.order_date,mb.join_date,m.product_name,
		dense_rank() over(partition by s.customer_id order by s.order_date desc) as drank
from sales s
inner join menu m on s.product_id = m.product_id
inner join members mb on s.customer_id = mb.customer_id
where s.order_date < mb.join_date)
select customer_id, product_name
from order_info
where drank = 1;

-- 8. What is the total items and amount spent for each member before they became a member?

select s.customer_id,count(*) as total_items,sum(m.price) as amount_spent
from sales s
inner join menu m on s.product_id = m.product_id
inner join members mb on s.customer_id = mb.customer_id
where s.order_date < mb.join_date
group by s.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

with points_info as (select s.customer_id,m.product_id,m.product_name,m.price,
	case 
		when m.product_id = 1 then m.price*20
		else m.price*10
	end as points
from sales s
inner join menu m on s.product_id = m.product_id)
select customer_id,sum(points) as points
from points_info
group by customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi 
-- how many points do customer A and B have at the end of January?

with point_info as (
	select s.customer_id,s.order_date,mb.join_date,m.product_name,m.price,
		case 
			when s.order_date between mb.join_date and DATEADD(day,6,mb.join_date) then m.price*10*2
			when m.product_name = 'sushi' then m.price*10*2
			else m.price*10
		end as points
	from sales s
	inner join menu m on s.product_id = m.product_id
	inner join members mb on s.customer_id = mb.customer_id
)
select customer_id,sum(points) as total_points
from point_info
where order_date <= '2021-01-31' and order_date >= join_date
group by customer_id;

/*
BONUS QUESTIONS - Rank All The Things
Danny also requires further information about the ranking of customer products, 
but he purposely does not need the ranking for non-member purchases 
so he expects null ranking values for the records when customers are not yet part of the loyalty program.
*/

with rank_info as (
	select s.customer_id,s.order_date,mb.join_date,m.product_name,m.price,
		case 
			when order_date >= join_date then 'Y'
			else 'N'
		end as member
	from sales s 
	inner join menu m on s.product_id = m.product_id
	left join members mb on s.customer_id = mb.customer_id
)
select *,
	case 
		when member = 'N' then null
		else DENSE_RANK() over(partition by customer_id,member order by order_date) 
	end as ranking
from rank_info

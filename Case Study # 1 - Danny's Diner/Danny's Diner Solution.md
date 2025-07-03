# :ramen: :curry: :sushi: Case Study #1: Danny's Diner

 
### 1. What is the total amount each customer spent at the restaurant?
```sql
select s.customer_id, CONCAT('$',' ',sum(m.price)) as total_sales
from sales s 
join menu m on s.product_id = m.product_id
group by s.customer_id
order by s.customer_id;
```
| customer_id | total_sales |
|-------------|-------------|
| A           | $ 76        |
| B           | $ 74        |
| C           | $ 36        |
---
### 2. How many days has each customer visited the restaurant?
```sql
 select customer_id,COUNT(distinct order_date) as days_visited 
 from sales
 group by customer_id
 order by customer_id;
```
| customer_id | days_visited |
|-------------|--------------|
| A           | 4            |
| B           | 6            |
| C           | 2            |
---
### 3. What was the first item from the menu purchased by each customer?
```sql
with order_info_cte as (select s.customer_id,s.order_date,s.product_id,m.product_name,m.price,
	DENSE_RANK() over(partition by s.customer_id order by s.order_date) as item_rank
from sales s
join menu m on s.product_id = m.product_id )
select customer_id,product_name
from order_info_cte
where item_rank = 1
group by customer_id,product_name;
```
| customer_id | product_name |
|-------------|--------------|
| A           | curry        |
| A           | sushi        |
| B           | curry        |
| C           | ramen        |
---
### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
```sql
select top 1 m.product_name,count(s.product_id) as order_count
from sales s
join menu m on s.product_id = m.product_id
group by m.product_name
order by order_count desc;
```
| product_name | order_count |
|--------------|-------------|
| ramen        | 8           |
---
### 5. Which item was the most popular for each customer?
```sql
with order_info as (select s.customer_id,m.product_name, COUNT(m.product_name) as order_count,
	DENSE_RANK() over(partition by s.customer_id order by COUNT(m.product_name) desc) as rank_num
from sales s
join menu m  on s.product_id = m.product_id
group by s.customer_id,m.product_name)
select customer_id,product_name
from order_info
where rank_num = 1
order by customer_id;
```
| customer_id | product_name |
|-------------|--------------|
| A           | ramen        |
| B           | sushi        |
| B           | curry        |
| B           | ramen        |
| C           | ramen        |
---
### 6. Which item was purchased first by the customer after they became a member?
```sql
with order_info as (select s.customer_id,s.order_date,mb.join_date,m.product_name, 
	ROW_NUMBER() over(partition by s.customer_id order by s.customer_id,s.order_date ) as rnum
from sales s
inner join menu m on s.product_id = m.product_id
inner join members mb on s.customer_id = mb.customer_id
where s.order_date > mb.join_date)
select customer_id,product_name
from order_info
where rnum = 1;
```
| customer_id | product_name |
|-------------|--------------|
| A           | ramen        |
| B           | sushi        |
---
### 7. Which item was purchased just before the customer became a member?
```sql
with order_info as (select s.customer_id,s.order_date,mb.join_date,m.product_name,
		dense_rank() over(partition by s.customer_id order by s.order_date desc) as drank
from sales s
inner join menu m on s.product_id = m.product_id
inner join members mb on s.customer_id = mb.customer_id
where s.order_date < mb.join_date)
select customer_id, product_name
from order_info
where drank = 1;
```
| customer_id | product_name |
|-------------|--------------|
| A           | sushi        |
| A           | curry        |
| B           | sushi        |
---
### 8. What is the total items and amount spent for each member before they became a member?
```sql
select s.customer_id,count(*) as total_items,sum(m.price) as amount_spent
from sales s
inner join menu m on s.product_id = m.product_id
inner join members mb on s.customer_id = mb.customer_id
where s.order_date < mb.join_date
group by s.customer_id;
```
| customer_id | total_items | amount_spent |
|-------------|-------------|--------------|
| A           | 2           | 25           |
| B           | 3           | 40           |
---
### 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
```sql
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
```
| customer_id | points |
|-------------|--------|
| A           | 860    |
| B           | 940    |
| C           | 360    |
---
### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi how many points do customer A and B have at the end of January?
```sql
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
```
| customer_id | total_points |
|-------------|--------------|
| A           | 1020         |
| B           | 320          |
---

### BONUS QUESTIONS - Rank All The Things
- Danny also requires further information about the ranking of customer products but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.
  
```sql
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
from rank_info;
```
| customer_id | order_date | join_date | product_name | price | member | ranking |
|-------------|------------|-----------|--------------|-------|--------|---------|
| A           | 2021-01-01 | 2021-01-07| sushi        | 10    | N      | NULL    |
| A           | 2021-01-01 | 2021-01-07| curry        | 15    | N      | NULL    |
| A           | 2021-01-07 | 2021-01-07| curry        | 15    | Y      | 1       |
| A           | 2021-01-10 | 2021-01-07| ramen        | 12    | Y      | 2       |
| A           | 2021-01-11 | 2021-01-07| ramen        | 12    | Y      | 3       |
| A           | 2021-01-11 | 2021-01-07| ramen        | 12    | Y      | 3       |
| B           | 2021-01-01 | 2021-01-09| curry        | 15    | N      | NULL    |
| B           | 2021-01-02 | 2021-01-09| curry        | 15    | N      | NULL    |
| B           | 2021-01-04 | 2021-01-09| sushi        | 10    | N      | NULL    |
| B           | 2021-01-11 | 2021-01-09| sushi        | 10    | Y      | 1       |
| B           | 2021-01-16 | 2021-01-09| ramen        | 12    | Y      | 2       |
| B           | 2021-02-01 | 2021-01-09| ramen        | 12    | Y      | 3       |
| C           | 2021-01-01 | NULL      | ramen        | 12    | N      | NULL    |
| C           | 2021-01-01 | NULL      | ramen        | 12    | N      | NULL    |
| C           | 2021-01-07 | NULL      | ramen        | 12    | N      | NULL    |
---

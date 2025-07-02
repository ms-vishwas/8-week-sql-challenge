# 🍕 Case Study #2 - Pizza Runner

## 🍝 Solution - A. Pizza Metrics


### 1.How many pizzas were ordered?

```sql
select count(*) as total_pizzas_ordered 
from customer_orders;
```
### 2.How many unique customer orders were made?
```sql
select COUNT( distinct order_id) as unique_orders 
from customer_orders;
```
### 3.How many successful orders were delivered by each runner?
```sql
select runner_id, count(*) as orders_delivered
from runner_orders
where cancellation is null 
group by runner_id;
```
### 4.How many of each type of pizza was delivered?
```sql
select p.pizza_name, count(c.order_id) as pizzas_delivered
from customer_orders c
join runner_orders r on c.order_id = r.order_id
join pizza_names p on c.pizza_id = p.pizza_id
where r.cancellation is null
group by p.pizza_name;
```
### 5.How many Vegetarian and Meatlovers were ordered by each customer?
```sql
select c.customer_id,p.pizza_name,COUNT(*) as order_count
from customer_orders c
join pizza_names p on c.pizza_id = p.pizza_id
group by c.customer_id,p.pizza_name
order by c.customer_id,p.pizza_name;
```
### 6.What was the maximum number of pizzas delivered in a single order?
```sql
select top 1 customer_id,order_id,count(pizza_id) pizza_count
from customer_orders
group by customer_id,order_id 
order by pizza_count desc;
```
### 7.For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
```sql
select c.customer_id,
	sum(case
		when (exclusions is not null or extras is not null) then 1 else 0
	end) as change_in_pizza,
	sum(case
		when (exclusions is null and extras is null) then 1 else 0
	end) as no_change_in_pizza
from customer_orders c
join runner_orders r on c.order_id=r.order_id
where r.cancellation is null
group by c.customer_id
order by c.customer_id;
```
### 8.How many pizzas were delivered that had both exclusions and extras?
```sql
select count(*) as pizza_count_w_exclusions_extras
from customer_orders c
join runner_orders r on c.order_id=r.order_id
where r.cancellation is null and c.exclusions is not null and extras is not null;
```
### 9.What was the total volume of pizzas ordered for each hour of the day?
```sql
select DATEPART(hour,order_time) as hour_of_day ,count(order_id) as pizza_count
from customer_orders
group by DATEPART(hour,order_time);
```
### 10.What was the volume of orders for each day of the week?
```sql
select format(order_time,'dddd') as week_day, count(order_id) as pizza_count
from customer_orders
group by format(order_time,'dddd')
order by 2 desc
```

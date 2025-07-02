# 🍕 Case Study #2 Pizza Runner

## Solution - B. Runner and Customer Experience


### 1.How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
```sql
select DATEPART(week,registration_date) as registration_week,count(*) as number_of_registration
from runners
group by DATEPART(week,registration_date);
```
### 2.What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
```sql
select r.runner_id,round(avg(cast(DATEDIFF(minute,c.order_time,r.pickup_time)as float)),2) as avg_pickup_time
from customer_orders c
join runner_orders r on c.order_id = r.order_id
where r.cancellation is null
group by r.runner_id;
```
### 3.Is there any relationship between the number of pizzas and how long the order takes to prepare?
```sql
with prepare as (
	select c.order_id,count(c.order_id) as pizza_order,c.order_time,r.pickup_time,
		cast(DATEDIFF(minute,c.order_time,r.pickup_time) as float) as prep_time
	from customer_orders c
	join runner_orders r on c.order_id = r.order_id
	where r.cancellation is null
	group by c.order_id,c.order_time,r.pickup_time
)
select pizza_order , concat(avg(cast(prep_time as float)),' min') as avg_prep_time
from prepare
group by pizza_order;
```
### 4.What was the average distance travelled for each customer?
```sql
select c.customer_id, concat(round(AVG(cast(r.distance as float)),2),' KM') as avg_distance
from customer_orders c
join runner_orders r on c.order_id = r.order_id
group by c.customer_id;
```
### 5.What was the difference between the longest and shortest delivery times for all orders?
```sql
select min(r.duration) as shortest_delivery,
		max(r.duration) as longest_delivery,
		max(r.duration)-min(r.duration) as difference_in_delivery
from customer_orders c
join runner_orders r on c.order_id = r.order_id;
```
### 6.What was the average speed for each runner for each delivery and do you notice any trend for these values?
```sql
select runner_id,order_id,round((cast(distance as float)/cast(duration as float))*60,2) as avg_speed,
		round(round((cast(distance as float)/cast(duration as float))*60,2)-(lag(round((cast(distance as float)/cast(duration as float))*60,2),1) over(partition by runner_id order by runner_id)),2) as trend_in_speed
from runner_orders
where cancellation is null
order by runner_id,order_id;
```

### 7.What is the successful delivery percentage for each runner?
```sql
select runner_id, count(pickup_time) as delivered_orders,
		count(*) as total_orders,
		concat(cast(count(pickup_time) as float)/cast(count(*) as float)*100,'%') as successful_delivery 
from runner_orders
group by runner_id;
```

# 🍕 Case Study #2 Pizza Runner

## Solution - D. Pricing and Ratings.md


### 1.If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes how much money has Pizza Runner made so far if there are no delivery fees?
```sql
with revenue_cte as (
	select pn.pizza_name, count(c.pizza_id) as no_of_pizzas, 
			sum(case 
				when c.pizza_id = 1 then 12
				when c.pizza_id = 2 then 10
			end) as revenue 
	from customer_orders c
	join pizza_names pn on c.pizza_id = pn.pizza_id
	join runner_orders r on c.order_id = r.order_id
	where r.cancellation is null
	group by pn.pizza_name
)
select concat('$ ',sum(revenue)) as total_revnue
from revenue_cte;
```

### 2.What if there was an additional $1 charge for any pizza extras? Add cheese is $1 extra
```sql
--creating a view to split exclusions and extras
create view customer_order_view as
	select c.order_id,c.customer_id,c.pizza_id,c.exclusions,c.extras,
		case 
			when exclusions is not null and len(exclusions)>1 then left(exclusions,1)
			else exclusions 
		end as exclusions_1,
		case 
			when exclusions is not null and len(exclusions)>1 then right(exclusions,1)
			else null  
		end as exclusions_2,
		case
			when extras is not null and len(extras)>1 then left(extras,1)
			else extras 
		end as extras_1,
		case
			when extras is not null and len(extras)>1 then right(extras,1)
			else null 
		end as extras_2
	from customer_orders c
	where c.order_id is not null;
 
 with revenue_cte as (
 select cv.pizza_id,
	sum(case
		when cv.pizza_id = 1 then 12
		when cv.pizza_id = 2 then 10
	end) as pizza_price,
	sum(case
		when cv.extras_1 is not null and cv.extras_2 is not null then 2
		when cv.extras_1 is not null then 1
		else null 
	end) as extras_price 
 from customer_order_view  cv
 join runner_orders r on r.order_id=cv.order_id
 where r.cancellation is null
 group by cv.pizza_id
 )
 select (SUM(pizza_price)+sum(extras_price)) as total_revenue
 from revenue_cte
```
### 3.The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
```sql
DROP TABLE IF EXISTS runner_rating;

CREATE TABLE runner_rating (order_id int, rating int, review VARCHAR(100)) ;

-- Order 6 and 9 were cancelled
INSERT INTO runner_rating
VALUES ('1', '1', 'Really bad service'),
       ('2', '1', NULL),
       ('3', '4', 'Took too long...'),
       ('4', '1','Runner was lost, delivered it AFTER an hour. Pizza arrived cold' ),
       ('5', '2', 'Good service'),
       ('7', '5', 'It was great, good service and fast'),
       ('8', '2', 'He tossed it on the doorstep, poor service'),
       ('10', '5', 'Delicious!, he delivered it sooner than expected too!');


SELECT *
FROM runner_rating;
```
### 4.Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
- customer_id
- order_id
- runner_id
- rating
- order_time
- pickup_time
- Time between order and pickup
- Delivery duration
- Average speed
- Total number of pizzas
```sql
with aggregateorder as  (
	select  order_id,min(customer_id) as customer_id,min(order_time) as order_time,count(*) as tottal_pizzas
	from customer_orders
	group by order_id
),
ValidDeliveries as (
	select order_id,runner_id,pickup_time,distance,duration
	from runner_orders
	where cancellation is null
)
select ag.customer_id,ag.order_id,vd.runner_id,rr.rating,ag.order_time,vd.pickup_time,
		DATEDIFF(MINUTE,ag.order_time,vd.pickup_time) as pick_time,vd.duration,
		round(((vd.distance*60)/vd.duration),2) as avg_speed,ag.tottal_pizzas
from aggregateorder ag 
join ValidDeliveries vd on ag.order_id = vd.order_id
left join runner_rating rr on vd.order_id = rr.order_id
order by ag.order_id;
```
### 5.If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled how much money does Pizza Runner have left over after these deliveries? Aggregate customer_orders per order_id
```sql
with revenue_cte as (
	select c.order_id,c.customer_id,c.pizza_id,r.runner_id,
		case 
			when c.pizza_id = 1 then 12
			when c.pizza_id = 2 then 10
			else null 
		end as pizza_price,
		r.distance,r.distance*0.30 as runner_cost
	from customer_orders c
	join runner_orders r on c.order_id = r.order_id
	where r.cancellation is null
)
select sum(pizza_price) as gross_profit, sum(runner_cost) as runner_cost,sum(pizza_price)-sum(runner_cost) as net_profit
from revenue_cte;
```

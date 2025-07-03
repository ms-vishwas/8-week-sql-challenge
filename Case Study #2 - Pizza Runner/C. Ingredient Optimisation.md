# 🍕 Case Study #2 Pizza Runner

## Solution - C. Ingredient Optimisation

### 1.What are the standard ingredients for each pizza?

```sql
select pn.pizza_name,STRING_AGG(pt.topping_name,',') as standard_ingredients
from pizza_names pn
join pizza_recipes_2 pr on pn.pizza_id = pr.pizza_id
join pizza_toppings pt on pr.toppings = pt.topping_id
group by pn.pizza_name;
```
| pizza_name | standard_ingredients |
|------------|----------------------|
| Meatlovers | Bacon,BBQ Sauce,Beef,Cheese,Chicken,Mushrooms,Pepperoni,Salami |
| Vegetarian | Cheese,Mushrooms,Onions,Peppers,Tomatoes,Tomato Sauce |
---
### 2.What was the most commonly added extra?
```sql
with extras_cte as(
	select pizza_id, cast(value as int) as extras
	from customer_orders c
	outer apply string_split(extras,',')
)
select top 1 pt.topping_name, count(extras) extras_count
from extras_cte e
join pizza_toppings pt on e.extras = pt.topping_id
group by pt.topping_name
order by extras_count desc;
```
| topping_name | extras_count |
|--------------|--------------|
| Bacon        | 4            |
---
### 3.What was the most common exclusion?
```sql
with exclusion_cte as(
	select pizza_id, cast(value as int) as exclusions
	from customer_orders
	outer apply string_split(exclusions,',')
)
select top 1 pt.topping_name, count(e.exclusions) as exclusion_count
from exclusion_cte e
join pizza_toppings pt on e.exclusions = pt.topping_id
group by pt.topping_name
order by exclusion_count desc;
```
|topping_name|exclusion_count|
|--------|-----------------|
|Cheese|4|
---
### 4.Generate an order item for each record in the customers_orders table in the format of one of the following:
- Meat Lovers
- Meat Lovers - Exclude Beef
- Meat Lovers - Extra Bacon
- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
```sql
with order_details_cte as (
	select c.order_id,p.pizza_name,c.exclusions,c.extras,c.customer_id
	from customer_orders c
	join pizza_names p on c.pizza_id = p.pizza_id
)
select order_id,customer_id,pizza_name+
	case 
		when od.exclusions is not null and od.exclusions <> '' and od.exclusions not in ('null','NULL') then
		' - exclude '+( select STRING_AGG(pt.topping_name,',') from string_split(od.exclusions,',') s 
					join pizza_toppings pt on cast( s.value as int) =pt.topping_id)
		else ''
	end+
	case
		when od.extras is not null and od.extras <> '' and od.extras not in ('null','NULL') then 
		' - include '+(select STRING_AGG(pt.topping_name,',') from string_split(od.extras,',') s
						join pizza_toppings pt on cast(s.value as int) = pt.topping_id)
		else ''
	end as order_item
from order_details_cte od 
order by order_id;
```
| order_id | customer_id | order_item                                      |
|----------|-------------|-------------------------------------------------|
| 1        | 101         | Meatlovers                                      |
| 2        | 101         | Meatlovers                                      |
| 3        | 102         | Meatlovers                                      |
| 3        | 102         | Vegetarian                                      |
| 4        | 103         | Meatlovers - exclude Cheese                     |
| 4        | 103         | Meatlovers - exclude Cheese                     |
| 4        | 103         | Vegetarian - exclude Cheese                     |
| 5        | 104         | Meatlovers - include Bacon                      |
| 6        | 101         | Vegetarian                                      |
| 7        | 105         | Vegetarian - include Bacon                      |
| 8        | 102         | Meatlovers                                      |
| 9        | 103         | Meatlovers - exclude Cheese - include Bacon,Chicken |
| 10       | 104         | Meatlovers                                      |
| 10       | 104         | Meatlovers - exclude BBQ Sauce,Mushrooms - include Bacon,Cheese |
---
### 5.Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
```sql
WITH OrderCTE AS (
    SELECT 
        co.order_id,
        pn.pizza_name,
        pr.toppings AS base_toppings,
        co.exclusions,
        co.extras
    FROM customer_orders co
    JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
    JOIN pizza_recipes pr ON co.pizza_id = pr.pizza_id
)
SELECT 
    oc.order_id,
    oc.pizza_name + ': ' + Ingredients.ingredient_list AS ingredient_list
FROM OrderCTE oc
CROSS APPLY (
    SELECT STRING_AGG(
             CASE 
               WHEN ExtraT.topping_id IS NOT NULL THEN '2x' + pt.topping_name 
               ELSE pt.topping_name 
             END, ', '
           ) WITHIN GROUP (ORDER BY pt.topping_name) AS ingredient_list
    FROM (
          -- Get base ingredients that are not excluded.
          SELECT CAST(LTRIM(RTRIM(s.value)) AS INT) AS topping_id
          FROM STRING_SPLIT(oc.base_toppings, ',') s
          WHERE (oc.exclusions IS NULL 
                 OR oc.exclusions IN ('null','NULL')
                 OR LTRIM(RTRIM(s.value)) NOT IN (
                     SELECT LTRIM(RTRIM(value)) 
                     FROM STRING_SPLIT(oc.exclusions, ',')
                 )
          )
          UNION
          -- Get any extra ingredients.
          SELECT CAST(LTRIM(RTRIM(s2.value)) AS INT) AS topping_id
          FROM STRING_SPLIT(oc.extras, ',') s2
          WHERE oc.extras IS NOT NULL 
                AND oc.extras NOT IN ('null','NULL')
    ) AS AllToppings
    JOIN pizza_toppings pt ON AllToppings.topping_id = pt.topping_id
    LEFT JOIN (
          -- Identify which toppings are marked as extras.
          SELECT DISTINCT CAST(LTRIM(RTRIM(s3.value)) AS INT) AS topping_id
          FROM STRING_SPLIT(oc.extras, ',') s3
          WHERE oc.extras IS NOT NULL 
                AND oc.extras NOT IN ('null','NULL')
    ) AS ExtraT ON ExtraT.topping_id = AllToppings.topping_id
) Ingredients
ORDER BY oc.order_id;
```
| order_id | ingredient_list                                                  |
|----------|------------------------------------------------------------------|
| 1        | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 2        | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 3        | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 3        | Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes |
| 4        | Meatlovers: Bacon, BBQ Sauce, Beef, Chicken, Mushrooms, Pepperoni, Salami |
| 4        | Meatlovers: Bacon, BBQ Sauce, Beef, Chicken, Mushrooms, Pepperoni, Salami |
| 4        | Vegetarian: Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes |
| 5        | Meatlovers: 2xBacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 6        | Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes |
| 7        | Vegetarian: 2xBacon, Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes |
| 8        | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 9        | Meatlovers: 2xBacon, BBQ Sauce, Beef, 2xChicken, Mushrooms, Pepperoni, Salami |
| 10       | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 10       | Meatlovers: 2xBacon, Beef, 2xCheese, Chicken, Pepperoni, Salami |
---
### 6.What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
```sql
WITH DeliveredOrders AS (
    SELECT 
        co.order_id,
        pr.toppings AS base_toppings,
        co.exclusions,
        co.extras
    FROM customer_orders co
    JOIN runner_orders ro ON co.order_id = ro.order_id
    JOIN pizza_recipes pr ON co.pizza_id = pr.pizza_id
    WHERE (ro.cancellation IS NULL 
           OR LTRIM(RTRIM(ro.cancellation)) IN ('', 'null', 'NULL'))
),
BaseToppings AS (
    -- Base ingredients not excluded count as 1 each.
    SELECT 
        order_id, 
        CAST(LTRIM(RTRIM(s.value)) AS INT) AS topping_id,
        1 AS qty
    FROM DeliveredOrders
    CROSS APPLY STRING_SPLIT(base_toppings, ',') s
    WHERE (exclusions IS NULL 
           OR exclusions IN ('null','NULL')
           OR LTRIM(RTRIM(s.value)) NOT IN (
                  SELECT LTRIM(RTRIM(value))
                  FROM STRING_SPLIT(exclusions, ',')
              )
    )
),
ExtraToppings AS (
    -- Extra ingredients count as 2 each.
    SELECT 
        order_id, 
        CAST(LTRIM(RTRIM(s.value)) AS INT) AS topping_id,
        2 AS qty
    FROM DeliveredOrders
    CROSS APPLY STRING_SPLIT(extras, ',') s
    WHERE extras IS NOT NULL 
          AND extras NOT IN ('null','NULL')
),
AllToppings AS (
    SELECT * FROM BaseToppings
    UNION ALL
    SELECT * FROM ExtraToppings
)
SELECT 
    pt.topping_name,
    SUM(qty) AS total_quantity
FROM AllToppings at
JOIN pizza_toppings pt ON at.topping_id = pt.topping_id
GROUP BY pt.topping_name
ORDER BY total_quantity DESC;
```
| topping_name | total_quantity |
|--------------|----------------|
| Bacon        | 15             |
| Cheese       | 11             |
| Mushrooms    | 11             |
| Pepperoni    | 9              |
| Chicken      | 9              |
| Salami       | 9              |
| Beef         | 9              |
| BBQ Sauce    | 8              |
| Peppers      | 3              |
| Onions       | 3              |
| Tomato Sauce | 3              |
| Tomatoes     | 3              |
---

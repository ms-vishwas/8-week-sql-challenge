# 🍕 Case Study #2 - Pizza Runner

## 🧼 Data Cleaning & Transformation

 
## customer orders table
 - The exclusions and extras columns in customer_orders table will need to be cleaned up before using them in the queries  
- In the exclusions and extras columns, there are blank spaces and null values.

### updating null values in exclusions
```sql
update customer_orders
set exclusions = null
where exclusions in ('null',' ');
```

### updating null values in extras
```sql
update customer_orders
set extras = null
where extras in ('null',' ');
```

## ruuner_orders
- The pickup_time, distance, duration and cancellation columns in runner_orders table will need to be cleaned up before using them in the queries  
- In the pickup_time column, there are null values.
- In the distance column, there are null values. It contains unit - km. The 'km' must also be stripped 
- In the duration column, there are null values. The 'minutes', 'mins' 'minute' must be stripped
- In the cancellation column, there are blank spaces and null values.
### updating null values
```sql
update runner_orders
set distance = null
where distance = 'null';
```
```sql
update runner_orders
set duration = null
where duration = 'null';
```
```sql
update runner_orders
set pickup_time = null
where pickup_time like '%null%';
```
```sql
update runner_orders
set cancellation = null 
where cancellation in ('null',' ')
```

### triming km from distance column
```sql
update runner_orders
set distance = trim(REPLACE(distance,'km',''))
where distance like '%km'
```
### triming text from duration
```sql
update runner_orders
set duration =
	trim(case
		when duration like '%mins' then TRIM('mins' from duration)
		when duration like '%minute' then TRIM('minute' from duration)
		when duration like '%minutes' then TRIM('minutes' from duration)
		else duration
	end)
where duration is not null;
```

### changing datatype varchar to float
```sql
alter table runner_orders
alter column distance float;
```
```sql
alter table runner_orders
alter column duration float;
```
### pizza_recipies
 ```sql
DROP TABLE IF EXISTS pizza_recipes_2;
CREATE TABLE pizza_recipes_2 (
  "pizza_id" INT,
  "toppings" int
);

insert into pizza_recipes_2 (pizza_id,toppings)
select pizza_id, cast(value as int)
from pizza_recipes
cross apply string_split(toppings,',');
```

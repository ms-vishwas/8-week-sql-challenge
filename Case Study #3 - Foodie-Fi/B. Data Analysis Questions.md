# :avocado: Case Study #3: Foodie-Fi - Data Analysis Questions

### 1. How many customers has Foodie-Fi ever had?
```sql
select count(distinct customer_id) as no_of_customers 
from subscriptions;
```
#### Output:
|no_of_customers|
|---------------|
|1000|
***
### 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
```sql
select month(start_date) as month_num, FORMAT(start_date,'MMMM') as month_name,count(*) as count
from subscriptions
where plan_id = 0
group by month(start_date),FORMAT(start_date,'MMMM')
order by month(start_date);
```
#### Output:
| month_num | month_name | count |
|-----------|------------|-------|
| 1         | January    | 88    |
| 2         | February   | 68    |
| 3         | March      | 94    |
| 4         | April      | 81    |
| 5         | May        | 88    |
| 6         | June       | 79    |
| 7         | July       | 89    |
| 8         | August     | 88    |
| 9         | September  | 87    |
| 10        | October    | 79    |
| 11        | November   | 75    |
| 12        | December   | 84    |
***
### 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
```sql
select s.plan_id,p.plan_name,count(*) as num_of_events
from subscriptions s
join plans p on s.plan_id = p.plan_id
where s.start_date > '2020-12-31'
group by s.plan_id,p.plan_name
order by s.plan_id;
```
#### Output:
| plan_id | plan_name     | num_of_events |
|---------|---------------|---------------|
| 1       | basic monthly | 8             |
| 2       | pro monthly   | 60            |
| 3       | pro annual    | 63            |
| 4       | churn         | 71            |
***
### 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
```sql
with churn_cte as ( 
	select 
		count(case
			when plan_id = 4 then 1 
			else null 
		end) as c1,
		count(distinct customer_id) as c2
	from subscriptions
)
select c1 as churn_count,
		concat(round((cast(c1 as float)/c2)*100,1),' %') as churn_percentage
from churn_cte;
```
#### Output:
|churn_count| churn_percentage|
|----------- |-------------------------|
|307         |30.7 %|
***
### 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

```sql
with count_cte as (
select *,ROW_NUMBER() over(partition by customer_id order by start_date) as r_num
from subscriptions
)
select count(customer_id) as churned_customers,
		concat((cast(count(customer_id) as float)/(select count(distinct customer_id) from subscriptions))*100,' %') as percentage_churned_customers
from count_cte
where r_num = 2 and plan_id = 4;
```
#### Output:
|churned_customers| percentage_churned_customers|
|----------------- |----------------------------|
|92                |9.2 %|
***
### 6.What is the number and percentage of customer plans after their initial free trial?
```sql
with count_cte as (
select *,ROW_NUMBER() over(partition by customer_id order by start_date) as r_num
from subscriptions
)
select count(customer_id) as upgraded_customers,
		concat((cast(count(customer_id) as float)/(select count(distinct customer_id) from subscriptions))*100,' %') as percentage_upgraded_customers
from count_cte
where r_num = 2 and plan_id <> 4;
```
### Output:
|upgraded_customers| percentage_upgraded_customers|
|------------------ |-----------------------------|
|908                |90.8 %|
***
### 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
```sql
with latest_sub as (
	select * , ROW_NUMBER() over(partition by customer_id order by start_date desc) as rn
	from subscriptions 
	where start_date <= '2020-12-31'
),
active_plans as (
	select *
	from latest_sub
	where rn = 1
)
select p.plan_name,COUNT(DISTINCT customer_id) as customer_count,
		concat((cast(COUNT(DISTINCT customer_id) as float)/(select count(distinct customer_id) from subscriptions))*100,' %')  as percentage_breakdown
from active_plans ap
join plans p on ap.plan_id = p.plan_id
group by p.plan_name,p.plan_id
order by p.plan_id;
```
#### Output:
| plan_name     | customer_count | percentage_breakdown |
|---------------|----------------|----------------------|
| trial         | 19             | 1.9 %                |
| basic monthly | 224            | 22.4 %               |
| pro monthly   | 326            | 32.6 %               |
| pro annual    | 195            | 19.5 %               |
| churn         | 236            | 23.6 %               |
***
### 8. How many customers have upgraded to an annual plan in 2020?
```sql
select count(distinct customer_id) as customers_count
from subscriptions
where start_date <= '2020-12-31' and plan_id = 3;
```
#### Output:
|customers_count|
|---------------|
|195|
***
### 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
```sql
with trial_plan as (
	select customer_id,min(start_date) as trial_start_date 
	from subscriptions
	where plan_id = 0
	group by customer_id
),annual_plan as (
	select customer_id,min(start_date) as annual_start_date 
	from subscriptions
	where plan_id = 3 
	group by customer_id
)
select avg(DATEdiff(day,t.trial_start_date,a.annual_start_date)) as avg_days_to_upgrade
from trial_plan t
join annual_plan a on t.customer_id = a.customer_id;
```
#### Output:
|avg_days_to_upgrade|
|-------------------|
|104|
***
### 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
```sql
with trial_plan as (
	select customer_id,min(start_date) as trial_start_date 
	from subscriptions
	where plan_id = 0
	group by customer_id
),annual_plan as (
	select customer_id,min(start_date) as annual_start_date 
	from subscriptions
	where plan_id = 3 
	group by customer_id
),days_upgraded as (
	select t.customer_id,DATEdiff(day,t.trial_start_date,a.annual_start_date) as avg_days_to_upgrade
	from trial_plan t
	join annual_plan a on t.customer_id = a.customer_id
)
select 
	case 
		when avg_days_to_upgrade between 0 and 30 then 1
		when avg_days_to_upgrade between 31 and 60 then 2
		when avg_days_to_upgrade between 61 and 90 then 3
		when avg_days_to_upgrade between 91 and 120 then 4
		when avg_days_to_upgrade between 121 and 150 then 5
		when avg_days_to_upgrade between 151 and 180 then 6
		when avg_days_to_upgrade between 181 and 210 then 7
		when avg_days_to_upgrade between 211 and 240 then 8
		when avg_days_to_upgrade between 241 and 270 then 9
		when avg_days_to_upgrade between 271 and 300 then 10
		when avg_days_to_upgrade between 311 and 330 then 11
		when avg_days_to_upgrade between 331 and 365 then 12
	end as sort_order,
	case 
		when avg_days_to_upgrade between 0 and 30 then '0-30 days'
		when avg_days_to_upgrade between 31 and 60 then '31-60 days'
		when avg_days_to_upgrade between 61 and 90 then '61-90 days'
		when avg_days_to_upgrade between 91 and 120 then '91-120 days'
		when avg_days_to_upgrade between 121 and 150 then '121-150 days'
		when avg_days_to_upgrade between 151 and 180 then '151-180 days'
		when avg_days_to_upgrade between 181 and 210 then '181-210 days'
		when avg_days_to_upgrade between 211 and 240 then '211-240 days'
		when avg_days_to_upgrade between 241 and 270 then '241-270 days'
		when avg_days_to_upgrade between 271 and 300 then '271-300 days'
		when avg_days_to_upgrade between 311 and 330 then '311-330 days'
		when avg_days_to_upgrade between 331 and 365 then '331-365 days'
	end as days_range,
	count(*) as customer_count
from days_upgraded
group by 
	case 
		when avg_days_to_upgrade between 0 and 30 then '0-30 days'
		when avg_days_to_upgrade between 31 and 60 then '31-60 days'
		when avg_days_to_upgrade between 61 and 90 then '61-90 days'
		when avg_days_to_upgrade between 91 and 120 then '91-120 days'
		when avg_days_to_upgrade between 121 and 150 then '121-150 days'
		when avg_days_to_upgrade between 151 and 180 then '151-180 days'
		when avg_days_to_upgrade between 181 and 210 then '181-210 days'
		when avg_days_to_upgrade between 211 and 240 then '211-240 days'
		when avg_days_to_upgrade between 241 and 270 then '241-270 days'
		when avg_days_to_upgrade between 271 and 300 then '271-300 days'
		when avg_days_to_upgrade between 311 and 330 then '311-330 days'
		when avg_days_to_upgrade between 331 and 365 then '331-365 days'
	end,
	case 
		when avg_days_to_upgrade between 0 and 30 then 1
		when avg_days_to_upgrade between 31 and 60 then 2
		when avg_days_to_upgrade between 61 and 90 then 3
		when avg_days_to_upgrade between 91 and 120 then 4
		when avg_days_to_upgrade between 121 and 150 then 5
		when avg_days_to_upgrade between 151 and 180 then 6
		when avg_days_to_upgrade between 181 and 210 then 7
		when avg_days_to_upgrade between 211 and 240 then 8
		when avg_days_to_upgrade between 241 and 270 then 9
		when avg_days_to_upgrade between 271 and 300 then 10
		when avg_days_to_upgrade between 311 and 330 then 11
		when avg_days_to_upgrade between 331 and 365 then 12
	end 
order by sort_order;
```
#### Output:
| sort_order | days_range   | customer_count |
|------------|--------------|----------------|
| 1          | 0-30 days    | 49             |
| 2          | 31-60 days   | 24             |
| 3          | 61-90 days   | 34             |
| 4          | 91-120 days  | 35             |
| 5          | 121-150 days | 42             |
| 6          | 151-180 days | 36             |
| 7          | 181-210 days | 26             |
| 8          | 211-240 days | 4              |
| 9          | 241-270 days | 5              |
| 10         | 271-300 days | 1              |
| 11         | 311-330 days | 1              |
| 12         | 331-365 days | 1              |
***
### 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
```sql
with cte as (
	select *,LEAD(plan_id) over(partition by customer_id order by start_date) as next_plan
	from subscriptions
)
select count(*) as customer_count
from cte
where plan_id = 2 and next_plan = 1
```
#### Output:
|customer_count|
|--------------|
|0|
***

--Case Study #5 - Data Mart

/*
		
	Introduction

Data Mart is Danny’s latest venture and after running international operations for his online supermarket that specialises in fresh produce - Danny is asking for your support to analyse his sales performance.

In June 2020 - large scale supply changes were made at Data Mart. All Data Mart products now use sustainable packaging methods in every single step from the farm all the way to the customer.

Danny needs your help to quantify the impact of this change on the sales performance for Data Mart and it’s separate business areas.

	Available Data

For this case study there is only a single table: data_mart.weekly_sales
*/

-- CREATE SCHEMA data_mart;
CREATE DATABASE data_mart;
USE data_mart;

DROP TABLE IF EXISTS weekly_sales;
CREATE TABLE weekly_sales (
  week_date VARCHAR(10),
  region VARCHAR(20),
  platform VARCHAR(10),
  segment NVARCHAR(10),
  customer_type VARCHAR(15),
  transactions INT,
  sales INT
);

BULK INSERT weekly_sales
FROM 'C:\Users\vishw\Desktop\data_mart.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 1  -- If there's a header row
);

/*
1. Data Cleansing Steps
In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:

*Convert the week_date to a DATE format
*Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
*Add a month_number with the calendar month for each week_date value as the 3rd column
*Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
*Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value
			segment	age_band
			1	Young Adults
			2	Middle Aged
			3 or 4	Retirees
*Add a new demographic column using the following mapping for the first letter in the segment values:
			segment	demographic
			C	Couples
			F	Families
*Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
*Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record
*/

select 
	CONVERT(DATE, week_date, 3) AS week_date,
	DATEPART(WEEK,CONVERT(DATE, week_date, 3)) as week_number,
	DATEPART(MONTH,CONVERT(date,week_date,3)) as month_number,
	DATEPART(YEAR,CONVERT(date,week_date,3)) as calendar_year,
	region,
	platform,
	case
		when segment <> 'null' then segment
		else 'Unknown'
	end as segment,
	case
		when RIGHT(segment,1) = '1' then 'Young Adults'
		when RIGHT(segment,1) = '2' then 'Middle Aged'
		when RIGHT(segment,1) = '3' or RIGHT(segment,1) = '4' then 'Retirees'
		else 'Unknown'
	end as age_band,
	case 
		when LEFT(segment,1) = 'C' then 'Couples'
		when LEFT(segment,1) = 'F' then 'Families'
		else 'Unknown'
	end as demographic,
	customer_type,
	transactions,
	sales,
	round(cast(sales as float)/transactions,2) as avg_transaction 
into clean_weekly_sales
from weekly_sales;

select * from clean_weekly_sales;

--2. Data Exploration
--1. What day of the week is used for each week_date value?

select distinct DATENAME(WEEKDAY,week_date) as day
from clean_weekly_sales;

--2.What range of week numbers are missing from the dataset?

with cte as (
select top 52 ROW_NUMBER() over(order by (select null)) as number 
from sys.all_objects
 )
 select *
 from cte 
 where number not in (select distinct week_number from clean_weekly_sales);

 --3. How many total transactions were there for each year in the dataset?

 select calendar_year,sum(transactions) as total_txn
 from clean_weekly_sales
 group by calendar_year
 order by calendar_year;

 --4. What is the total sales for each region for each month?

 select calendar_year,format(week_date,'MMMM') as month,region,sum(transactions) as total_txn
 from clean_weekly_sales
 group by calendar_year,format(week_date,'MMMM'),month_number,region
 order by calendar_year,month_number,region;

 --5. What is the total count of transactions for each platform?

 select platform,sum(transactions) as total_txn
 from clean_weekly_sales
 group by platform;

 --6. What is the percentage of sales for Retail vs Shopify for each month?

 with monthly_sales as (
	 select calendar_year,format(week_date,'MMMM') as month,month_number,platform,sum(cast(sales as bigint)) as total_sales_platform
	 from clean_weekly_sales
	 group by calendar_year,format(week_date,'MMMM'),month_number,platform
 ),monthly_total as (
	 select calendar_year,month,SUM(total_sales_platform) as total_sales_monthly
	 from monthly_sales
	 group by calendar_year,month
)
select ms.calendar_year,ms.month,ms.platform,ms.total_sales_platform,
		round((cast(ms.total_sales_platform as float)/mt.total_sales_monthly)*100,2) as percentage_of_sales
from monthly_sales ms
join monthly_total mt 
on ms.calendar_year = mt.calendar_year and ms.month = mt.month
order by ms.calendar_year,ms.month_number,ms.platform;

--7. What is the percentage of sales by demographic for each year in the dataset?

select calendar_year,
	round(((cast(sum(case
		when demographic = 'Couples' then cast(sales as bigint) else 0 
	end) as float))/sum(cast(sales as bigint)))*100,2) as Couples,
	round(((cast(sum(case
		when demographic = 'Families' then cast(sales as bigint) else 0 
	end) as float))/sum(cast(sales as bigint)))*100,2) as Families,
	round(((cast(sum(case
		when demographic = 'Unknown' then cast(sales as bigint) else 0 
	end) as float))/sum(cast(sales as bigint)))*100,2) as Unknown
from clean_weekly_sales
group by calendar_year
order by calendar_year;

--8. Which age_band and demographic values contribute the most to Retail sales?

with cte as (
	select age_band,demographic,sum(cast(sales as bigint)) as total_sales 
	from clean_weekly_sales
	where platform = 'Retail'
	group by age_band,demographic
)
select *,
	round((cast(total_sales as float)/(select sum(cast(sales as bigint)) from clean_weekly_sales where platform = 'Retail'))*100,2) as percentage_of_sales
from cte
order by 4 desc;

--9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? 
--If not - how would you calculate it instead?


/*
3. Before & After Analysis
This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.

Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.

We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before

Using this analysis approach - answer the following questions:
*/
--1.What is the total sales for the 4 weeks before and after 2020-06-15? 
--What is the growth or reduction rate in actual values and percentage of sales?

with before_after as (
	select
		(select sum(cast(sales as bigint)) 
		from clean_weekly_sales
		where week_date between DATEADD(day,-28,'2020-06-15') and DATEADD(day,-1,'2020-06-15')) as before_sales,
		(select sum(cast(sales as bigint)) 
		from clean_weekly_sales
		where week_date between '2020-06-15' and DATEADD(DAY,27,'2020-06-15')) as after_sales
)
select *, after_sales-before_sales as variance,
	round(100.0*(after_sales-before_sales)/cast(before_sales as float),2) as variance_percentage
from before_after;

--2.What about the entire 12 weeks before and after?

with before_after as (
	select
		(select sum(cast(sales as bigint)) 
		from clean_weekly_sales
		where week_date between DATEADD(day,-84,'2020-06-15') and DATEADD(day,-1,'2020-06-15')) as before_sales,
		(select sum(cast(sales as bigint)) 
		from clean_weekly_sales
		where week_date between '2020-06-15' and DATEADD(DAY,83,'2020-06-15')) as after_sales
)
select *, after_sales-before_sales as variance,
	round(100.0*(after_sales-before_sales)/cast(before_sales as float),2) as variance_percentage
from before_after;

--3.How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?



/*
4. Bonus Question
Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?

region
platform
age_band
demographic
customer_type
Do you have any further recommendations for Danny’s team at Data Mart or any interesting insights based off this analysis?
*/



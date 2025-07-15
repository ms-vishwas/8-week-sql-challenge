## :avocado: Case Study #3: Foodie-Fi - Customer Journey

Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.

Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!

I have selected three customers to focus on and will now share their onboarding journey.

***
#### Customer 1:
```sql
select s.customer_id,p.plan_name,s.start_date
from subscriptions s
join plans p on s.plan_id = p.plan_id
where s.customer_id = 1;
```
#### Output :
| customer_id | plan_name     | start_date |
|-------------|---------------|------------|
| 1           | trial         | 2020-08-01 |
| 1           | basic monthly | 2020-08-08 |
- This customer initiated their journey by starting the free trial on 1 Aug 2020.
- After the trial period ended, on 8 Aug 2020, they subscribed to the basic monthly plan.
***
#### Customer 13:
```sql
select s.customer_id,p.plan_name,s.start_date
from subscriptions s
join plans p on s.plan_id = p.plan_id
where s.customer_id = 13;
```
#### Output :
| customer_id | plan_name     | start_date |
|-------------|---------------|------------|
| 13          | trial         | 2020-12-15 |
| 13          | basic monthly | 2020-12-22 |
| 13          | pro monthly   | 2021-03-29 |
- The onboarding journey for this customer began with a free trial on 15 Dec 2020. Following the trial period, on 22 Dec 2020
- They subscribed to the basic monthly plan. After three months, on 29 Mar 2021, they upgraded to the pro monthly plan.
***
#### Customer 15:
```sql
select s.customer_id,p.plan_name,s.start_date
from subscriptions s
join plans p on s.plan_id = p.plan_id
where s.customer_id = 15;
```
#### Output :
| customer_id | plan_name   | start_date |
|-------------|-------------|------------|
| 15          | trial       | 2020-03-17 |
| 15          | pro monthly | 2020-03-24 |
| 15          | churn       | 2020-04-29 |
- Initially, this customer commenced their onboarding journey with a free trial on 17 Mar 2020.
- Once the trial ended, on 24 Mar 2020, they upgraded to the pro monthly plan. However, the following month, on 29 Apr 2020, The customer decided to terminate their subscription and subsequently churned until the paid subscription ends.

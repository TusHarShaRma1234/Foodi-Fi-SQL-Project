Use foodie_fi;
-- A. Customer Journey
/*Based off the 4 sample customers provided in the sample from the subscriptions table,
 write a brief description about each customer’s onboarding journey.
Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!*/

select p.plan_name,
	   p.price,
       s.*
  from plans p 
  join subscriptions s
  on s.plan_id = p.plan_id
  where customer_id  in  (1,2,11,13,15,16,18,19);
  
  --  Customer ID 1 started their subscription in 2020-08-01 with the free trail and after ending of free trail he bought monthly subscription on 2020-08-01.
  --  Customer ID 2 started their subscription in 2020-09-08 with the free trail and after ending of free trail he bought Pro_annual subscription on 2020-09-20.
  -- Customer ID 11 started their subscription in 2020-11-19 with the free trail and after ending of free trail he didn't bousght any plan
  /*Customer ID 13 started their subscription in 2020-12-15 with the free trail and after ending of free trail  first he bought basic-monthly 
  After 3 - month he bought pro_munthly on 2020-03-29.*/

-- B. Data Analysis Questions

# How many customers has Foodie-Fi ever had?
select count(distinct customer_id) as total_customer
from subscriptions;

-- Their are 1000 unique customer 

# What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

select extract(month from start_date) as month_date ,
	  monthname(sta) as month_name,
       count(customer_id) as Customer_count
  from plans p 
  join subscriptions s
  on s.plan_id = p.plan_id
  where plan_name = "trial"
  group by  month_name,month_date
  order by month_date ;
  
  #What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
  
  select  p.plan_id,
          upper(p.Plan_name) as plan_name ,
          count(s.start_date) as events
  from plans p 
  right join subscriptions s
  on s.plan_id = p.plan_id
  where  extract(year from start_date) > '2020'
  group by p.plan_name,p.plan_id
  order by p.plan_id;
  
  
  # What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
  
SELECT 
  COUNT(CASE WHEN plan_name = 'churn' THEN 1 END) AS customer_churn,
  COUNT(DISTINCT customer_id) AS total_customers,
  ROUND(COUNT(CASE WHEN plan_name = 'churn' THEN 1 END)/ COUNT(DISTINCT customer_id) * 100, 1) AS churn_rate
FROM subscriptions
JOIN plans
USING (plan_id);

-- customer_churn is 307 and the total no. of customer is 1000 and purcentage or churn rate is 30.7

# How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

With cte as (
          Select  s.plan_id,
                  s.customer_id,
                  p.plan_name,
              row_number () over(partition by  s.customer_id order by s.plan_id )  as rank_no
         from subscriptions s 
		left join plans p 
         on p.plan_id = s.plan_id
)
select count(*) as churn_count,
       round(100 * count(*)/( select count(distinct customer_id)from subscriptions) , 0) as churn_percentage
       from cte
       where plan_id = 4 and rank_no = 2;
       
   # What is the number and percentage of customer plans after their initial free trial?    
   
  With cte as (
          Select  plan_id,
                  customer_id,
              lead (plan_id,1) over(partition by  customer_id order by plan_id )  as nextplan
         from subscriptions 
)
select nextplan,
       count(*) as nextplan,
       round(100 * count(*)/( select count(distinct customer_id)from subscriptions) , 1) as percentage
       from cte
       where nextplan is not null and plan_id = 0
       group by nextplan
       order by nextplan desc;
       
# What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?      
   
  With cte as (
          Select  plan_id,
                  customer_id,
                  start_date,
              rank () over(partition by  customer_id order by plan_id )  as allfive
         from subscriptions 
)
select allfive,
       count(*) as allfive,
       round(100 * count(*)/( select count(distinct customer_id)from subscriptions) , 1) as percentage
       from cte
       where start_date = " 2020-12-31"
       group by allfive;
  
  # How many customers have upgraded to an annual plan in 2020?
  
  select count(distinct customer_id ) as no_customer
       from subscriptions 
       where plan_id = 3 and  start_date <= "2020-12-31";
       
# How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?      
 
with trail_plan  as (
                select customer_id,
                  start_date as trail_date 
                  from subscriptions 
                  where plan_id = 0 
),
 annual_plan as (
                 select customer_id,
                  start_date as annual_date 
                  from subscriptions 
                  where plan_id = 3 
 )
 select round(avg(datediff(an.annual_date, tp.trail_date))) as avg_days_to_annual_plan
        from trail_plan  tp
        join annual_plan an 
        on an.customer_id =  tp.customer_id;
        
 -- On an average custoner takes 105 days to by an annual plan.alter
 
 # Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

 with trail_plan  as (
                select customer_id,
                  start_date as trail_date 
                  from subscriptions 
                  where plan_id = 0 
),
 annual_plan as (
                 select customer_id,
                  start_date as annual_date 
                  from subscriptions 
                  where plan_id = 3 
 ),

 bucket_tile  as (
                 select 
                        ntile(12) over(order by datediff(an.annual_date, tp.trail_date)) as avg_days_to_annual_plan
                        from trail_plan  tp
                        join annual_plan an
					   using (customer_id)
)
select  concat( (( avg_days_to_annual_plan -1)* 30), ' - ' , (avg_days_to_annual_plan * 30), " days") as Periiode_of_days,
		count(*) as customers
        from bucket_tile
        group by avg_days_to_annual_plan
        order by avg_days_to_annual_plan; 
 
 # How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
 with pro_to_basic as ( select customer_id,
                               plan_id,
							   start_date, 
                               lead(plan_id,1) over(partition by customer_id order by plan_id ) as next_plan
                               from   subscriptions 
 )
 
SELECT 
  COUNT(*) AS downgraded
FROM pro_to_basic
WHERE start_date <= '2020-12-31'
  AND plan_id = 2 
  AND next_plan = 1;
  
 --  there is 0 downgraded
	
/* The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts
 paid by each customer in the subscriptions table with the following requirements:
monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
once a customer churns they will no longer make payments  */



create table payments ( 
                        plan_id int,
                      customer_id int ,
                      plan_name varchar(20),
                      payment_date date,
                      amount decimal (10,2) ,
                      payment_oder int 
) ;

  insert into  payments  (plan_id,customer_id,plan_name,payment_date,amount,payment_oder)
  select s.plan_id,s.customer_id,p.plan_name,s.start_date,price,
		row_number()over(partition by plan_name order by customer_id asc) as payment_oder
	from subscriptions s
    join plans p
    using(plan_id)
    where  start_date <= '2020-12-31';
   -- total 4896 rows returned ;
   
   
   
  
  
  
  
  
  
  
  
  
  
  
  
  
 
          
       
       
       
       
       
       
       
       
       
       
       
       
       
       
       



































  
  
  
  
  
  
  
  
  
  
  
  
  

  

        

























  
  
  
  
  
  
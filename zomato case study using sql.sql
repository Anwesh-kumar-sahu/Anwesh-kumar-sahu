drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'2017-09-22'),
(3,'2017-04-21');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'2014-02-09'),
(2,'2015-01-15'),
(3,'2014-04-11');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'2017-04-19',2),
(3,'2019-12-18',1),
(2,'2020-07-20',3),
(1,'2019-10-23',2),
(1,'2018-03-19',3),
(3,'2016-12-20',2),
(1,'2016-09-11',1),
(1,'2016-05-20',3),
(2,'2017-09-24',1),
(1,'2017-03-11',2),
(1,'2016-03-11',1),
(3,'2016-11-10',1),
(3,'2017-12-07',2),
(3,'2016-12-15',2),
(2,'2017-11-08',2),
(2,'2018-09-10',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

1. What is the total amount each customer spent on zomato?

SELECT 
    a.userid, SUM(b.price) total_amt_spent
FROM
    sales a
        INNER JOIN
    product b ON a.product_id = b.product_id
GROUP BY a.userid;

2.How many days each customer visited zamoto?

SELECT 
    userid, COUNT(DISTINCT created_date)
FROM
    sales
GROUP BY userid;

3. What was the first product purchased by each customer?

select * from
(select *,rank() over(partition by userid order by created_date)rnk from sales) a where rnk = 1

4. What is the total purchase item on the menu and how many times it was purchase by all customer?

select userid,count(product_id) as pid from sales where product_id = (
select product_id from sales group by product_id order by count(product_id) desc limit 1)
group by userid
order by userid

5. which item was the most popular for each customer?

select * from(
select *,rank() over(partition by userid order by pid desc) rnk from(
select userid,product_id,count(product_id) pid from sales group by userid,product_id) a)b
where rnk = 1

6. Which item was purchased first by customer after they become a member?

select * from(
select c.*,rank() over(partition by userid order by created_date) as rnk from(
select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales as a inner join goldusers_signup as b 
on a.userid = b.userid and created_date >= gold_signup_date) as c) as d where rnk = 1

7. Which item was purchase just before the customer become a member?

select * from(
select c.*,rank() over(partition by userid order by created_date desc) as rnk from(
select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales as a inner join goldusers_signup as b 
on a.userid = b.userid and created_date <= gold_signup_date) as c) as d where rnk = 1

8. what is the total orders and amount spent for each member before they became a member?

select userid,count(created_date),sum(price) from
(select c.*,d.price from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales as a inner join goldusers_signup as b 
on a.userid = b.userid and created_date <= gold_signup_date) as c inner join product as d on c.product_id = d.product_id) as e
group by userid

9. if buying each product generates points for eg 5rs = 2 zamoto point and each product has different purchasing points 
for eg for p1 5rs = 1 zamoto points and p3 5rs = 1 zamoto point,calculate points collected by each customer 
and for which product most points have been given till now.

select userid,sum(total_points)*2.5 as total_money_earned from
(select e.*,amt / points as total_points from
(select d.*,case when product_id = 1 then 5 when product_id = 2 then 2 when product_id = 3 then 5 else 0 end as points from
(select c.userid,c.product_id,sum(price) as amt from
(select a.*,b.price from sales as a join product as b on a.product_id = b.product_id) as c
group by userid,product_id) as d) as e) as f group by userid

select * from
(select *,rank() over(order by total_point_earned desc) as rnk from
(select product_id,sum(total_points) as total_point_earned from
(select e.*,amt / points as total_points from
(select d.*,case when product_id = 1 then 5 when product_id = 2 then 2 when product_id = 3 then 5 else 0 end as points from
(select c.userid,c.product_id,sum(price) as amt from
(select a.*,b.price from sales as a join product as b on a.product_id = b.product_id) as c
group by userid,product_id) as d) as e) as f group by product_id) as f) as g where rnk = 1

select e.*,amt / points as total_points from
(select d.*,case when product_id = 1 then 5 when product_id = 2 then 2 when product_id = 3 then 5 else 0 end as points from
(select c.userid,c.product_id,sum(price) as amt from
(select a.*,b.price from sales as a join product as b on a.product_id = b.product_id) as c
group by userid,product_id) as d) as e

select e.*,amt / points as total_points from
(select d.*,case when product_id = 1 then 5 when product_id = 2 then 2 when product_id = 3 then 5 else 0 end as points from
(select c.userid,c.product_id,sum(price) as amt from
(select a.*,b.price from sales as a join product as b on a.product_id = b.product_id) as c
group by userid,product_id) as d) as e

10. In the first one year after a customer joins the gold program (including their join date) 
irrespective of what the customer has purchased they earn 5 zamoto points for every 10rs spent who earned more 1 or 3 
and what was their points earning in thheir first yr?

1 zp = 2rs
0.5zp = 1rs

select c.*,d.price*0.5 as total_points_earned from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales as a inner join goldusers_signup as b 
on a.userid = b.userid and created_date >= gold_signup_date and created_date <= date_add(gold_signup_date,interval 1 year)) as c
join product as d on c.product_id = d.product_id

11. rnk all the transaction of the customers?

select *,rank() over(partition by userid order by created_date) as rnk from sales

12.rank all the transaction for each member whenever they are zamoto gold member for every non gold member transaction mark as na

select e.*,case when rnk = 0 then "na" else rnk end as rnkk from
(select c.*,case when gold_signup_date is null then "na" else rank() over(partition by userid order by created_date desc) end as rnk from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales as a left join goldusers_signup as b 
on a.userid = b.userid and created_date >= gold_signup_date) as c) as e


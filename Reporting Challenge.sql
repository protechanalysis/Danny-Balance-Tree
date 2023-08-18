-- create a table that contains only sales_monthly transaction for only that nonth
-- in that year 
drop table if exists balanced_tree.sales_monthly_monthly_monthly;
create table balanced_tree.sales_monthly_monthly_monthly as 
select * 
from sales_monthly_monthly
where extract(month from start_txn_time) = 
			( select max(extract(month from start_txn_time))
				from sales_monthly_monthly) and extract(year from start_txn_time) = 
			( select max(extract(year from start_txn_time)));
select start_txn_time
from balanced_tree.sales_monthly_monthly_monthly;

-- High Level sales_monthly Analysis

-- What was the total quantity sold for all products?
select sum(qty)  as total_quantity_sold
from sales_monthly;

-- What is the total generated revenue for all products before discounts?
select sum(qty*price) as gross_revenue
from sales_monthly;

-- What was the total discount amount for all products?
select sum(discount*(qty*price)/100) as total_discount
from sales_monthly;

-- transaction analysis

-- How many unique transactions were there?
select count(distinct txn_id) as num_unique_trnsaction
from sales_monthly;

-- What is the average unique products purchased in each transaction?
select round(avg(unique_product)) as avg_unique_purchase
from (select txn_id, count(distinct prod_id) as unique_product
		from sales_monthly group by txn_id) as uniquiue_txn;

-- What are the 25th, 50th and 75th percentile values for the revenue per transaction?

-- What is the average discount value per transaction?
select avg(discount*qty*price/100) as avg_discounts
from sales_monthly;


-- What is the percentage split of all transactions for members vs non-members?
select round(num_member*100/(num_member + num_non_member)) as percentage_member,
	 round(num_non_member*100/(num_member + num_non_member)) as percentage_non_member
from (select count(distinct txn_id) as num_member
		from sales_monthly
		where member = TRUE) as m,
	(select count(distinct txn_id) as num_non_member
		from sales_monthly
		where member = FALSE) as nm;
 
-- What is the average revenue for member transactions and non-member transactions
with txn_sales_monthly as (select *, (qty*price) as goods_amount, (discount*qty*price/100) as discount_amount
		from sales_monthly),
non_member as (select round(avg(goods_amount- discount_amount), 2) as non_member_revenue
		from txn_sales_monthly
		where member = FALSE),
members as (select round(avg(goods_amount- discount_amount), 2) as member_revenue
		from txn_sales_monthly
		where member = TRUE)
select member_revenue, non_member_revenue
from members, non_member;

-- ## Product Analysis questions
--  What are the top 3 products by total revenue before discount?
with cal_quantity as (
	select prod_id, sum(qty) as total_quantity, price
from sales_monthly_monthly
group by prod_id, price)
select product_name, total_quantity * c.price as total_revenue_bd
from cal_quantity as c
inner join product_details
on prod_id = product_id
order by total_revenue_bd desc
limit 3;
 
 
 -- What is the total quantity, revenue and discount for each segment?
 with discount_tab as (
	select *, round(discount*qty*price/100, 2) as discount_amount
    from sales_monthly_monthly),
cal_quantity as (
	select prod_id, sum(qty) as quantity, sum(discount_amount) as discount_given
from discount_tab
group by prod_id, price)

select segment_name, sum(quantity) as total_quantity, sum(quantity * c.price)-sum(discount_given) as total_revenue, sum(discount_given) as total_discount_given
from cal_quantity 
inner join product_details as c
on prod_id = product_id
group by segment_name
order by total_revenue desc;


-- What is the top selling product for each segment?
with cal_quantity as (
	select prod_id, sum(qty) as total_quantity
from sales_monthly_monthly
group by prod_id, price),
ranking as (
select segment_name, product_name, total_quantity * c.price as total_revenue,
	row_number() over(partition by segment_name order by total_quantity * c.price desc) as rank_number
from cal_quantity 
inner join product_details as c
on prod_id = product_id)
select segment_name, product_name, total_revenue
from ranking 
where rank_number = 1;

-- What is the total quantity, revenue and discount for each category?
with discount_tab as (
	select *, round(discount*qty*price/100, 2) as discount_amount
    from sales_monthly_monthly),
cal_quantity as (
	select prod_id, sum(qty) as quantity, sum(discount_amount) as discount_given
from discount_tab
group by prod_id, price)

select category_name, sum(quantity) as total_quantity, sum(quantity * c.price) - sum(discount_given) as total_revenue, sum(discount_given) as total_discount_given
from cal_quantity 
inner join product_details as c
on prod_id = product_id
group by category_name
order by total_revenue desc;

-- What is the top selling product for each category?
with cal_quantity as (
	select prod_id, sum(qty) as total_quantity
from sales_monthly_monthly
group by prod_id, price),
ranking as (
select category_name, product_name, total_quantity * c.price as total_revenue_with_discount,
	row_number() over(partition by category_name order by total_quantity * c.price desc) as rank_number
from cal_quantity 
inner join product_details as c
on prod_id = product_id)
select category_name, product_name, total_revenue_with_discount
from ranking 
where rank_number = 1;

-- What is the percentage split of revenue by product for each segment?

with rev as (
	select prod_id, sum(round(qty*(price*(1-discount/100)), 2)) as revenue
from sales_monthly_monthly
group by prod_id),
seg as (select segment_name, product_name, sum(revenue) as total_revenue
from rev 
left join product_details
on prod_id = product_id
group by segment_name, product_name),
seg_name as (
	select segment_name, sum(total_revenue) as seg_rev 
    from seg 
    group by segment_name)
select segment_name, product_name, round(total_revenue*100/seg_rev, 2) as percentage_revenue
from seg
inner join seg_name using(segment_name)
order by segment_name, percentage_revenue desc;

-- What is the percentage split of revenue by segment for each category?
with rev as (
	select prod_id, sum(round(qty*(price*(1-discount/100)), 2)) as revenue
from sales_monthly_monthly
group by prod_id),
cate as (select category_name, segment_name, sum(revenue) as total_revenue
from rev 
left join product_details
on prod_id = product_id
group by category_name, segment_name),
cate_name as (
	select category_name, sum(total_revenue) as cate_rev 
    from cate 
    group by category_name)
select category_name, segment_name, round(total_revenue*100/cate_rev, 2) as percentage_revenue
from cate
inner join cate_name using(category_name)
order by segment_name;

--  What is the percentage split of total revenue by category?
with rev as (
	select prod_id, sum(round(qty*(price*(1-discount/100)), 2)) as revenue
from sales_monthly_monthly
group by prod_id),
cate as (select category_name, sum(revenue) as total_revenue
from rev
left join product_details
on prod_id = product_id
group by category_name)
select category_name, round(total_revenue*100/cate_rev,2) as percentage_revenve
from cate, (select sum(total_revenue) as cate_rev from cate) as s;

-- What is the total transaction “penetration” for each product? (hint: penetration = number of transactions
-- where at least 1 quantity of a product was purchased divided by total number of transactions)
with prod_count as (select prod_id, count(distinct txn_id) as num_product
from sales_monthly_monthly
group by prod_id
order by num_product desc),
txn_count as (select count(distinct txn_id) as num_distinct_txn from sales_monthly_monthly)
select prod_id, num_product, num_distinct_txn, round(num_product/num_distinct_txn *100,2) as pentration_rate
from prod_count
cross join txn_count;

-- What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
with prod_name as (select product_name, txn_id
from sales_monthly_monthly
join product_details
on prod_id = product_id),
product_combination as (select s1.txn_id, s1.product_name as product_1, s2.product_name as product_2, s3.product_name as product_3
from prod_name s1
join prod_name s2 on s1.txn_id = s2.txn_id and s1.product_name != s2.product_name 
join prod_name s3 on s1.txn_id = s3.txn_id and s1.product_name != s2.product_name and s1.product_name != s3.product_name and s2.product_name != s3.product_name)
select product_1, product_2, product_3, count(txn_id) as num_combination
from product_combination
group by product_1, product_2, product_3
order by num_combination desc
limit 1;
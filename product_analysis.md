## Product Analysis

1. What are the top 3 products by total revenue before discount?
<details>
<summary>Click to show SQL query</summary>
	
```sql
with cal_quantity as (
	select prod_id, sum(qty) as total_quantity, price
	from sales
	group by prod_id, price)
select product_name, total_quantity * c.price as total_revenue_bd
from cal_quantity as c
inner join product_details
on prod_id = product_id
order by total_revenue_bd desc
limit 3;
```

</details>

### Output:
product_name | total_revenue_bd
-----|-----
Blue Polo Shirt - Mens | 217683
Grey Fashion Jacket - Womens | 209304
White Tee Shirt - Mens | 152000

 
2. What is the total quantity, revenue and discount for each segment?
<details>
<summary>Click to show SQL query</summary>
	
```sql
 with discount_tab as (
	select *, round(discount*qty*price/100, 2) as discount_amount
    	from sales),
cal_quantity as (
	select prod_id, sum(qty) as quantity, sum(discount_amount) as discount_given
	from discount_tab
	group by prod_id, price)

select segment_name, sum(quantity) as total_quantity, 
	 sum(quantity * c.price)-sum(discount_given) as total_revenue, 
	 sum(discount_given) as total_discount_given
from cal_quantity 
inner join product_details as c
on prod_id = product_id
group by segment_name
order by total_revenue desc;
```

</details>

### Output:
segment_name | total_quantity | total_revenue | total_discount_given
-----|-----|-----|-----
Shirt | 11265 | 356548.73 | 49594.27
Jacket | 11385 | 322705.54 | 44277.46
Socks | 11217 | 270963.56 | 37013.44
Jeans | 11349 | 183006.03 | 25343.97


3. What is the top-selling product for each segment?
<details>
<summary>Click to show SQL query</summary>
	
```sql
with cal_quantity as (
	select prod_id, sum(qty) as total_quantity
from sales
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
```

</details>

### Output:
segment_name | product_name | total_revenue
-----|-----|-----
Jacket | Grey Fashion Jacket - Womens | 209304
Jeans | Black Straight Jeans - Womens | 121152
Shirt | Blue Polo Shirt - Mens | 217683
Socks | Navy Solid Socks - Mens | 136512


4. What is the total quantity, revenue and discount for each category?
<details>
<summary>Click to show SQL query</summary>
	
```sql
with discount_tab as (
	select *, round(discount*qty*price/100, 2) as discount_amount
    	from sales),
cal_quantity as (
	select prod_id, sum(qty) as quantity, sum(discount_amount) as discount_given
	from discount_tab
	group by prod_id, price)

select category_name, sum(quantity) as total_quantity, 
	sum(quantity * c.price) - sum(discount_given) as total_revenue, 
	sum(discount_given) as total_discount_given
from cal_quantity 
inner join product_details as c
on prod_id = product_id
group by category_name
order by total_revenue desc;
```
</details>

### Output:
category_name | total_quantity | total_revenue | total_discount_given
-----|-----|-----|-----
Mens | 22482 | 627512.29 | 86607.71
Womens | 22734 | 505711.57 | 69621.43


5. What is the top selling product for each category?
<details>
<summary>Click to show SQL query</summary>
	
```sql
with cal_quantity as (
	select prod_id, sum(qty) as total_quantity
from sales
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
```
</details>

### Output:
category_name | product_name | total_revenue_with_discount
-----|-----|-----
Mens | Blue Polo Shirt - Mens | 217683
Womens | Grey Fashion Jacket - Womens | 209304


6. What is the percentage split of revenue by product for each segment?
<details>
<summary>Click to show SQL query</summary>
	
```sql
with rev as (
	select prod_id, sum(round(qty*(price*(1-discount/100)), 2)) as revenue
from sales
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
```
</details>

### Output:
segment_name | product_name | percentage_revenue
-----|-----|-----
Jacket | Grey Fashion Jacket - Womens | 56.99
Jacket | Khaki Suit Jacket - Womens | 23.57
Jacket | Indigo Rain Jacket - Womens | 19.44
Jeans | Black Straight Jeans - Womens | 58.14
Jeans | Navy Oversized Jeans - Womens | 24.04
Jeans | Cream Relaxed Jeans - Womens | 17.82
Shirt | Blue Polo Shirt - Mens | 53.53
Shirt | White Tee Shirt - Mens | 37.48
Shirt | Teal Button Up Shirt - Mens | 8.99
Socks | Navy Solid Socks - Mens | 44.24
Socks | Pink Fluro Polkadot Socks - Mens | 35.57
Socks | White Striped Socks - Mens | 20.20


7. What is the percentage split of revenue by segment for each category?
<details>
<summary>Click to show SQL query</summary>
	
```sql
with rev as (
	select prod_id, sum(round(qty*(price*(1-discount/100)), 2)) as revenue
	from sales
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
```
</details>

### Output:
category_name | segment_name | percentage_revenue
-----|-----|-----
Womens | Jacket | 63.81
Womens | Jeans | 36.19
Mens | Shirt | 56.82
Mens | Socks |43.18


8.  What is the percentage split of total revenue by category?
<details>
<summary>Click to show SQL query</summary>
	
```sql
with rev as (
	select prod_id, sum(round(qty*(price*(1-discount/100)), 2)) as revenue
	from sales
	group by prod_id),
cate as (
	select category_name, sum(revenue) as total_revenue
	from rev
	left join product_details
	on prod_id = product_id
	group by category_name)
select category_name, round(total_revenue*100/cate_rev,2) as percentage_revenve
from cate, (select sum(total_revenue) as cate_rev 
		from cate) as s;
```
</details>

### Output:
category_name | percentage_revenve
-----|-----
Mens | 55.37
Womens | 44.63


9. What is the total transaction “penetration” for each product? (hint: penetration = number of transactions
-- where at least 1 quantity of a product was purchased divided by total number of transactions)
<details>
<summary>Click to show SQL query</summary>
	
```sql
with prod_count as (
	select prod_id, count(distinct txn_id) as num_product
	from sales
	group by prod_id
	order by num_product desc),
txn_count as (
	select count(distinct txn_id) as num_distinct_txn 
	from sales)
select prod_id, num_product, num_distinct_txn, round(num_product/num_distinct_txn *100,2) as pentration_rate
from prod_count
cross join txn_count;
```

</details>

### Output:
prod_id | num_product | num_distinct_txn | pentration_rate
-----|-----|-----|-----
f084eb | 1281 | 2500 | 51.24
9ec847 | 1275 | 2500 | 51.00
c4a632 | 1274 | 2500 | 50.96
2a2353 | 1268 | 2500 | 50.72
5d267b | 1268 | 2500 | 50.72
2feb6b | 1258 | 2500 | 50.32
72f5d4 | 1250 | 2500 | 50.00
d5e9a6 | 1247 | 2500 | 49.88
e83aa3 | 1246 | 2500 | 49.84
b9a74d | 1243 | 2500 | 49.72
e31d39 | 1243 | 2500 | 49.72
c8d436 | 1242 | 2500 | 49.68


10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
<details>
<summary>Click to show SQL query</summary>
	
```sql
with prod_name as (select product_name, txn_id
from sales
join product_details
on prod_id = product_id),
product_combination as (
	select s1.txn_id, s1.product_name as product_1, s2.product_name as product_2, s3.product_name as product_3
	from prod_name s1
	join prod_name s2 on s1.txn_id = s2.txn_id and s1.product_name != s2.product_name 
	join prod_name s3 on s1.txn_id = s3.txn_id 
	and s1.product_name != s2.product_name 
	and s1.product_name != s3.product_name 
	and s2.product_name != s3.product_name)
select product_1, product_2, product_3, count(txn_id) as num_combination
from product_combination
group by product_1, product_2, product_3
order by num_combination desc
limit 1;
```
</details>

### Output:
product_1 | product_2 | product_3 | num_combination
-----|-----|-----|-----
Grey Fashion Jacket - Womens | Teal Button Up Shirt - Mens | White Tee Shirt - Mens | 352

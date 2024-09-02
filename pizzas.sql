/*
Created By: Brandy Nolan
Created On: August 31,2024
Description: Kaggle dataset showing Pizza Data Set order detail.
*/

-- Total number of orders placed.
SELECT
	COUNT(DISTINCT order_id) total_orders
FROM 
	dbo.orders;

-- Total revenue generated from pizza sales.
SELECT
	ROUND(SUM(price),2) total_revenue
FROM 
	dbo.pizzas;

-- The highest-priced pizza.
SELECT
	*
FROM 
	dbo.pizzas 
WHERE price = (SELECT MAX(price) FROM dbo.pizzas);

-- The most common pizza size ordered.
SELECT TOP 1
	size,
	COUNT(*) total
FROM 
	dbo.pizzas
GROUP BY
	size
ORDER BY 2 DESC

--Top 5 most ordered pizza types along with their quantities.
SELECT TOP 5
	pizza_id,
	SUM(quantity) total
FROM 
	dbo.order_details
GROUP BY
	pizza_id
ORDER BY COUNT(*) DESC;

--  Total quantity of each pizza category ordered.
SELECT
	category,
	SUM(quantity) total_quantity
FROM
	dbo.pizza_types pt
JOIN
	dbo.pizzas p
ON 
	pt.pizza_type_id = p.pizza_type_id
JOIN
	dbo.order_details od
ON 
	p.pizza_id = od.pizza_id
GROUP BY
	category
ORDER BY 2 DESC;

-- Determine the distribution of orders by hour of the day.
SELECT 
	DATEPART(HOUR, time) AS Hour_of_the_day,
	COUNT(*) total_orders
FROM
	dbo.orders
GROUP BY 
	DATEPART(HOUR, time)
ORDER BY 2 DESC;

--Category-wise distribution of pizzas.
SELECT
	category,
	COUNT(order_id) order_count
FROM
	dbo.pizza_types pt
JOIN
	dbo.pizzas p
ON 
	pt.pizza_type_id = p.pizza_type_id
JOIN
	dbo.order_details od
ON 
	p.pizza_id = od.pizza_id
GROUP BY
	category
ORDER BY 2 DESC;

--Group the orders by date and calculate the average number of pizzas ordered per day.
SELECT
	date,
	AVG(total_quantity)
FROM(
	SELECT
		date,
		SUM(quantity) total_quantity
	FROM
		dbo.orders o
	JOIN
		dbo.order_details od
	ON o.order_id = od.order_id
	GROUP BY
		date
) daily_totals
GROUP BY date
ORDER BY 1 

-- Top 3 most ordered pizza types based on revenue.
WITH revenue_cte AS (
	SELECT
		name,
		price * quantity as revenue
	FROM
		dbo.pizzas p
	JOIN
		dbo.order_details od
	ON p.pizza_id = od.pizza_id
	JOIN
		dbo.pizza_types pt
	ON pt.pizza_type_id = p.pizza_type_id
)
SELECT TOP 3
	name,
	SUM(revenue) total_revenue
FROM 
	revenue_cte
GROUP BY 
	name
ORDER BY total_revenue DESC

--The percentage contribution of each pizza type to total revenue.
WITH revenue_cte AS (
	SELECT
		name,
		SUM(price * quantity) as revenue
	FROM
		dbo.pizzas p
	JOIN
		dbo.order_details od
	ON p.pizza_id = od.pizza_id
	JOIN
		dbo.pizza_types pt
	ON pt.pizza_type_id = p.pizza_type_id
GROUP BY
	name
),
total_revenue_cte AS (
    SELECT
        SUM(revenue) AS total_revenue
    FROM
        revenue_cte
)
SELECT
	name,
	CONCAT(ROUND((revenue/total_revenue)*100,2), '%') as percentage_contribution
FROM
	revenue_cte
CROSS JOIN
	total_revenue_cte

-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.
WITH revenue_cte AS (
	SELECT
		category,
		name,
		ROUND(SUM(price * quantity),2) revenue
	FROM 
		dbo.pizza_types pt
	JOIN
		dbo.pizzas p
	ON 
		pt.pizza_type_id = p.pizza_type_id
	JOIN 
		order_details od
	ON 
		od.pizza_id = p.pizza_id
	GROUP BY
		category, 
		name
),
ranked_pizzas AS (
	SELECT
		name,
		category,
		revenue,
		ROW_NUMBER() OVER (PARTITION BY category ORDER BY revenue DESC) AS revenue_rank
	FROM 
		revenue_cte
)
SELECT
    category,
    name,
    revenue
FROM
    ranked_pizzas
WHERE
    revenue_rank <= 3
ORDER BY
    category,
    revenue_rank;

--Analyze the cumulative revenue generated over time.
WITH daily_revenue_cte AS (
    SELECT
        date,
        SUM(price * quantity) AS daily_revenue
	FROM 
		dbo.orders o
	JOIN
		dbo.order_details od
	ON
		o.order_id = od.order_id
	JOIN
		dbo.pizzas p
	ON
		p.pizza_id = od.pizza_id
	GROUP BY 
		date
)
SELECT
    date,
    daily_revenue,
    SUM(daily_revenue) OVER (ORDER BY date) AS cumulative_revenue
FROM
    daily_revenue_cte
ORDER BY
    date;
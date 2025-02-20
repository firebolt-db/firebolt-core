-- Simple aggregation example with avg function
SELECT l_shipdate, l_shipmode, l_suppkey, avg(l_quantity) AS avg_quantity
FROM lineitem l1
GROUP BY 1, 2, 3
order by avg_quantity desc
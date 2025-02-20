-- Create an aggregating index for the avg quantity
CREATE AGGREGATING INDEX lineitem_l_linestatus_avg_quantity
ON lineitem
(
    l_shipdate, l_shipmode, l_suppkey, avg(l_quantity)
);
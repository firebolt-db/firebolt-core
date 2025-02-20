-- Optionally, you can increase the amount of data in the 'lineitem' table by duplicating it.
-- The table 'lineitem' has originally ~6k tuples. This query duplicates the table 5k times to create around ~30M tuples.
INSERT lineitem
SELECT l.*
FROM lineitem as l, generate_series(1, 5000) AS copy_number;
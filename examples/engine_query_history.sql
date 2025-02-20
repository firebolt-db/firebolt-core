-- Show the last 5 queries executed (one start and one finish entry per query)
SELECT query_text, duration_us
FROM information_schema.engine_query_history
ORDER BY start_time asc
LIMIT 10;
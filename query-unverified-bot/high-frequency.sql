-- Check for high-frequency requesters, converts the millisecond time span into a human-readable format showing days, hours, and minutes
SELECT 
    httprequest.clientip,
    COUNT(*) AS request_count,
    CONCAT(
        CAST(FLOOR((MAX(timestamp) - MIN(timestamp)) / 86400000) AS VARCHAR), ' days, ',
        CAST(FLOOR(((MAX(timestamp) - MIN(timestamp)) % 86400000) / 3600000) AS VARCHAR), ' hours, ',
        CAST(FLOOR(((MAX(timestamp) - MIN(timestamp)) % 3600000) / 60000) AS VARCHAR), ' minutes'
    ) AS time_span_readable,
    ROUND(COUNT(*) / ((MAX(timestamp) - MIN(timestamp)) / 3600000.0), 2) AS requests_per_hour
FROM waf_logs_partition_projection
CROSS JOIN UNNEST(CASE 
                  WHEN cardinality(labels) >= 1 THEN labels
                  ELSE ARRAY[cast(row('NOLABEL') as row(name varchar))]
                  END) AS t(label_item)
WHERE label_item.name = 'awswaf:managed:aws:bot-control:bot:unverified%'
AND log_time >= date_format(current_date - interval '7' day, '%Y/%m/%d')
GROUP BY httprequest.clientip
HAVING COUNT(*) > 100
ORDER BY requests_per_hour DESC
LIMIT 100;
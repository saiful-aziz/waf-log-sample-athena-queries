-- This SQL query identifies URIs accessed frequently by specific IP addresses with no WAF labels, 
-- showing when each access pattern began, ended, and how long it persisted, helping detect potential unrecognized bot activity.
SELECT 
    httprequest.clientip,
    httprequest.uri,
    COUNT(*) AS access_count,
    -- Convert timestamp (milliseconds since epoch) to readable datetime format
    date_format(from_unixtime(MIN(timestamp) / 1000), '%Y-%m-%d %H:%i:%s') AS first_access,
    date_format(from_unixtime(MAX(timestamp) / 1000), '%Y-%m-%d %H:%i:%s') AS last_access,
    -- Add time difference between first and last access
    CONCAT(
        CAST(FLOOR((MAX(timestamp) - MIN(timestamp)) / 86400000) AS VARCHAR), ' days, ',
        CAST(FLOOR(((MAX(timestamp) - MIN(timestamp)) % 86400000) / 3600000) AS VARCHAR), ' hours, ',
        CAST(FLOOR(((MAX(timestamp) - MIN(timestamp)) % 3600000) / 60000) AS VARCHAR), ' minutes'
    ) AS access_duration
FROM waf_logs_partition_projection
CROSS JOIN UNNEST(CASE 
                  WHEN cardinality(labels) >= 1 THEN labels
                  ELSE ARRAY[cast(row('NOLABEL') as row(name varchar))]
                  END) AS t(label_item)
WHERE label_item.name = 'NOLABEL'
AND log_time >= date_format(current_date - interval '7' day, '%Y/%m/%d')
GROUP BY httprequest.clientip, httprequest.uri
HAVING COUNT(*) > 20
ORDER BY httprequest.clientip, access_count DESC
LIMIT 100;
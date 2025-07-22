-- Check for consistent timing patterns (potential automation)
-- This SQL query identifies potential automated bot traffic by analyzing the consistency of request timing patterns from each IP address, with lower variation coefficients and interpretive labels indicating higher likelihood of non-human activity.
WITH request_times AS (
    SELECT 
        httprequest.clientip,
        timestamp,
        lag(timestamp) OVER (PARTITION BY httprequest.clientip ORDER BY timestamp) AS prev_timestamp
    FROM waf_logs_partition_projection
    CROSS JOIN UNNEST(CASE 
                      WHEN cardinality(labels) >= 1 THEN labels
                      ELSE ARRAY[cast(row('NOLABEL') as row(name varchar))]
                      END) AS t(label_item)
    WHERE label_item.name = 'awswaf:managed:aws:bot-control:bot:unverified%'
    AND log_time >= date_format(current_date - interval '7' day, '%Y/%m/%d')
)
SELECT 
    clientip,
    COUNT(*) AS request_count,
    -- Show interval in more readable format using CAST to convert numbers to strings
    CASE
        WHEN approx_percentile(timestamp - prev_timestamp, 0.5) < 1000 THEN 
            CAST(ROUND(approx_percentile(timestamp - prev_timestamp, 0.5), 2) AS VARCHAR) || ' ms'
        WHEN approx_percentile(timestamp - prev_timestamp, 0.5) < 60000 THEN 
            CAST(ROUND(approx_percentile(timestamp - prev_timestamp, 0.5) / 1000.0, 2) AS VARCHAR) || ' seconds'
        ELSE 
            CAST(ROUND(approx_percentile(timestamp - prev_timestamp, 0.5) / 60000.0, 2) AS VARCHAR) || ' minutes'
    END AS median_interval_readable,
    -- Standard deviation in readable format
    CASE
        WHEN stddev(timestamp - prev_timestamp) < 1000 THEN 
            CAST(ROUND(stddev(timestamp - prev_timestamp), 2) AS VARCHAR) || ' ms'
        WHEN stddev(timestamp - prev_timestamp) < 60000 THEN 
            CAST(ROUND(stddev(timestamp - prev_timestamp) / 1000.0, 2) AS VARCHAR) || ' seconds'
        ELSE 
            CAST(ROUND(stddev(timestamp - prev_timestamp) / 60000.0, 2) AS VARCHAR) || ' minutes'
    END AS stddev_interval_readable,
    -- Keep variation coefficient as is (it's a ratio, so already readable)
    ROUND(stddev(timestamp - prev_timestamp) / approx_percentile(timestamp - prev_timestamp, 0.5), 4) AS interval_variation_coefficient,
    -- Add interpretation of the variation coefficient
    CASE
        WHEN stddev(timestamp - prev_timestamp) / approx_percentile(timestamp - prev_timestamp, 0.5) < 0.1 THEN 'Highly consistent (likely bot)'
        WHEN stddev(timestamp - prev_timestamp) / approx_percentile(timestamp - prev_timestamp, 0.5) < 0.3 THEN 'Very consistent (probable bot)'
        WHEN stddev(timestamp - prev_timestamp) / approx_percentile(timestamp - prev_timestamp, 0.5) < 0.7 THEN 'Somewhat consistent (possible bot)'
        ELSE 'Variable timing (likely human or sophisticated bot)'
    END AS pattern_interpretation
FROM request_times
WHERE prev_timestamp IS NOT NULL
GROUP BY clientip
HAVING COUNT(*) > 50
ORDER BY interval_variation_coefficient ASC, request_count DESC
LIMIT 100;
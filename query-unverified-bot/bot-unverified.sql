-- This SQL query counts and ranks requests from unverified bots in AWS WAF logs over the past 7 days, grouped by client IP, country, URI, and specific bot label type.
SELECT
  httprequest.clientip,
  httprequest.country,
  httprequest.uri,
  label_item.name AS bot_label,
  count(*) AS request_count
FROM waf_logs_partition_projection,
     UNNEST(
       CASE
         WHEN cardinality(labels) >= 1 THEN labels
         ELSE ARRAY[CAST(ROW('NOLABEL') AS ROW(name VARCHAR))]
       END
     ) AS t(label_item)
-- WHERE label_item.name LIKE 'awswaf:managed:aws:bot-control:bot:unverified%'
WHERE (label_item.name LIKE 'awswaf:managed:aws:bot-control:bot:unverified%' 
       OR label_item.name = 'NOLABEL')
  AND log_time >= date_format(current_date - interval '7' day, '%Y/%m/%d')
GROUP BY
  httprequest.clientip,
  httprequest.country,
  httprequest.uri,
  label_item.name
ORDER BY request_count DESC
LIMIT 50;
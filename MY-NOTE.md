# SQL Query Samples for AWS WAF Logging (S3 Destination)

> **Note**: You must create the Athena table first — either with partition or without.

---

## 📚 References

- [Amazon Athena + AWS WAF Blog](https://aws.amazon.com/blogs/networking-and-content-delivery/how-to-use-amazon-athena-queries-to-analyze-aws-waf-logs-and-provide-the-visibility-needed-for-threat-detection/)
- [AWS Knowledge Center: Analyze WAF logs](https://repost.aws/knowledge-center/aws-waf-logs-athena)
- [AWS Docs: Query AWS WAF logs](https://docs.aws.amazon.com/athena/latest/ug/waf-logs.html)
- [Create Athena Table with Partition Projection](https://docs.aws.amazon.com/athena/latest/ug/create-waf-table-partition-projection.html)
- [Example queries GitHub repo](https://github.com/aws-samples/waf-log-sample-athena-queries)

> During testing, it took more than 30 minutes before the data could be queried (remove date filter temporarily).

---

## 🔍 Sample Queries

### 🎯 Example 1 – Bot Control Labels

```sql
SELECT count(*) AS count,
       httprequest.clientip,
       httprequest.country,
       httprequest.uri,
       label_item.name
FROM "waf_logs_partition_projection",
     UNNEST(CASE 
                WHEN cardinality(labels) >= 1 THEN labels
                ELSE ARRAY[CAST(ROW('NOLABEL') AS ROW(name VARCHAR))]
            END) AS t(label_item)
WHERE label_item.name LIKE 'awswaf:managed:aws:bot-control:bot:unverified:%'
GROUP BY httprequest.clientip, httprequest.country, label_item.name, httprequest.uri
ORDER BY count;


Example 2 – Top 10 IPs on Specific Day
SELECT httprequest.clientip,
       count(httprequest.clientip) AS requests
FROM waf_logs_partition_projection
WHERE log_time = '2025/07/18'
GROUP BY httprequest.clientip
ORDER BY requests DESC
LIMIT 10;

Example 3 – Combined Query: Top Clients, URIs, and Labels
WITH 
top_clients AS (
    SELECT httprequest.clientip AS client_ip,
           count(httprequest.clientip) AS client_requests,
           'top_client' AS query_type
    FROM waf_logs_partition_projection
    GROUP BY httprequest.clientip
    ORDER BY client_requests DESC
    LIMIT 10
),

top_uris AS (
    SELECT httprequest.uri AS uri,
           count(httprequest.uri) AS uri_requests,
           'top_uri' AS query_type
    FROM waf_logs_partition_projection
    GROUP BY httprequest.uri
    ORDER BY uri_requests DESC
    LIMIT 10
),

client_labels AS (
    SELECT httprequest.clientip AS client_ip,
           count(*) AS label_count,
           label_item.name AS label_name,
           'client_label' AS query_type
    FROM waf_logs_partition_projection,
         UNNEST(CASE 
                    WHEN cardinality(labels) >= 1 THEN labels
                    ELSE ARRAY[CAST(ROW('NOLABEL') AS ROW(name VARCHAR))]
               END) AS t(label_item)
    GROUP BY httprequest.clientip, label_item.name
)

SELECT 'TOP_CLIENTS' AS result_type,
       client_ip AS item,
       client_requests AS count,
       NULL AS label
FROM top_clients

UNION ALL

SELECT 'TOP_URIS' AS result_type,
       uri AS item,
       uri_requests AS count,
       NULL AS label
FROM top_uris

UNION ALL

SELECT 'CLIENT_LABELS' AS result_type,
       client_ip AS item,
       label_count AS count,
       label_name AS label
FROM client_labels
ORDER BY result_type, count DESC;



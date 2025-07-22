-- MODIFIED from https://repost.aws/knowledge-center/waf-allow-blocked-bot-rule-group
-- finding requests that were terminated by the AWS Bot Control rule set, with special attention to Pingdom traffic.
WITH waf_data AS (
    SELECT 
        from_unixtime(timestamp / 1000) as time,
        terminatingruleid,
        action,
        httprequest.clientip as clientip,
        httprequest.requestid as requestid,
        httprequest.country as country,
        rulegroup.terminatingrule.ruleid as matchedRule,
        labels,
        map_agg(LOWER(header.name), header.value) AS kv
    FROM waf_logs_partition_projection,
         UNNEST(httprequest.headers) AS t(header),
         UNNEST(rulegrouplist) AS t(rulegroup)
    WHERE rulegroup.terminatingrule.ruleid IS NOT NULL
    AND log_time >= date_format(current_date - interval '3' day, '%Y/%m/%d')
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
)
SELECT 
    waf_data.time,
    waf_data.action,
    waf_data.terminatingruleid,
    waf_data.matchedRule,
    waf_data.kv['user-agent'] as UserAgent,
    waf_data.kv['user-agent'] LIKE 'pingdom%' as is_pingdom,
    waf_data.clientip,
    waf_data.country,
    waf_data.labels
FROM waf_data
WHERE terminatingruleid = 'AWS-AWSManagedRulesBotControlRuleSet'
ORDER BY time DESC
LIMIT 1000;
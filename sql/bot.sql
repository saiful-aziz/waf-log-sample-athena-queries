-- This sql is categorizing all requests based on the labels attached such as relating to bots, amazon managed rules, types of requests
 SELECT
        log_time,
        count(DISTINCT(httprequest.requestid)) AS total_requests,
        count(DISTINCT(	CASE 			WHEN action = 'CHALLENGE' THEN httprequest.requestid  			END		)) as challenge_requests,
        count(DISTINCT(	CASE 			WHEN action = 'ALLOW' THEN httprequest.requestid  		END		)) as allow_requests,
        count(DISTINCT(	CASE 			WHEN action = 'BLOCK' THEN httprequest.requestid 			END		)) as block_requests,
        count(DISTINCT(	CASE 			WHEN action = 'CAPTCHA' THEN httprequest.requestid  		END		)) as captcha_requests,
        --baseline rule groups
        SUM(CASE WHEN label_items.name LIKE '%:core-rule-set:%' THEN 1 ELSE 0 END) is_core_rule_set, -- commonly occurring vulnerabilities described in OWASP publications such AS OWASP Top 10
        SUM(CASE WHEN label_items.name LIKE '%:admin-protection:%' THEN 1 ELSE 0 END) is_admin_protection,--  risk of a malicious actor gaining administrative access to your application
        SUM(CASE WHEN label_items.name LIKE '%:known-bad-inputs:%' THEN 1 ELSE 0 END) is_known_bad_inputs, -- risk of a malicious actor discovering a vulnerable application

        --Use-case specific rule groups
        SUM(CASE WHEN label_items.name LIKE '%:sql-database:%' THEN 1 ELSE 0 END) is_sql_databASe, --  exploitation of SQL databASes, like SQL injection attacks
        SUM(CASE WHEN label_items.name LIKE '%:linux-os:%' THEN 1 ELSE 0 END) is_linux_os, -- exploitation of vulnerabilities specific to Linux, including Linux-specific Local File Inclusion (LFI) attacks
        SUM(CASE WHEN label_items.name LIKE '%:posix-os:%' THEN 1 ELSE 0 END) is_posix_os, --exploitation of vulnerabilities specific to POSIX and POSIX-like operating systems, including Local File Inclusion (LFI) attacks
        SUM(CASE WHEN label_items.name LIKE '%:windows-os:%' THEN 1 ELSE 0 END) is_windows_os, -- exploitation of vulnerabilities that permit an attacker to run unauthorized commands or run malicious code
        SUM(CASE WHEN label_items.name LIKE '%:php-app:%' THEN 1 ELSE 0 END) is_php_app, -- exploitation of vulnerabilities specific to the use of the PHP programming language, including injection of unsafe PHP functions
        SUM(CASE WHEN label_items.name LIKE '%:wordpress-app:%' THEN 1 ELSE 0 END) is_wordpress_app, -- exploitation of vulnerabilities specific to WordPress sites

        -- IP reputation rule groups
        SUM(CASE WHEN label_items.name LIKE '%:amazon-ip-list:%' THEN 1 ELSE 0 END) is_amazon_ip_list, -- bASed on Amazon internal threat intelligence

        -- Bot Control rule group
        SUM(CASE WHEN label_items.name LIKE '%:bot:verified%' THEN 1 ELSE 0 END) is_bot_verified,
        SUM(CASE WHEN label_items.name LIKE '%:bot-control:bot:%' THEN 1 ELSE 0 END) is_bot_common,
        SUM(CASE WHEN label_items.name LIKE '%:bot-control:signal:automated_browser%' THEN 1 ELSE 0 END) is_automated_browser,
        SUM(CASE WHEN label_items.name LIKE '%:signal:known_bot_data_center%' THEN 1 ELSE 0 END) is_known_bot_data_center,
        SUM(CASE WHEN label_items.name LIKE '%:signal:cloud_service_provider%' THEN 1 ELSE 0 END) is_cloud_service_provider,
        SUM(CASE WHEN label_items.name LIKE '%:signal:non_browser_user_agent%' THEN 1 ELSE 0 END) is_non_browser_user_agent,
        SUM(CASE WHEN label_items.name LIKE '%:signal:non_browser_header%' THEN 1 ELSE 0 END) is_non_browser_header,
        SUM(CASE WHEN label_items.name LIKE '%:targeted:aggregate:volumetric:ip:token_absent%' THEN 1 ELSE 0 END) is_targeted_volumetric_token_absent,
        SUM(CASE WHEN label_items.name LIKE '%:targeted:aggregate:volumetric:session:low%' THEN 1 ELSE 0 END) is_targeted_session_low,
        SUM(CASE WHEN label_items.name LIKE '%:targeted:aggregate:volumetric:session:medium%' THEN 1 ELSE 0 END) is_targeted_session_medium,
        SUM(CASE WHEN label_items.name LIKE '%:targeted:aggregate:volumetric:session:high%' THEN 1 ELSE 0 END) is_targeted_session_high,
        SUM(CASE WHEN label_items.name LIKE '%:targeted:aggregate:volumetric:session:maximum%' THEN 1 ELSE 0 END) is_targeted_session_maximum,
        SUM(CASE WHEN label_items.name LIKE '%:targeted:signal:automated_browser%' THEN 1 ELSE 0 END) is_targeted_automated_browser,
        SUM(CASE WHEN label_items.name LIKE '%:targeted:signal:browser_inconsistency%' THEN 1 ELSE 0 END) is_targeted_browser_inconsistency,
        SUM(CASE WHEN label_items.name LIKE '%:targeted:signal:browser_automation_extension%' THEN 1 ELSE 0 END) is_targeted_browser_automation_extension,
        SUM(CASE WHEN label_items.name LIKE '%:targeted:aggregate:volumetric:session:token_reuse:ip:low%' THEN 1 ELSE 0 END) is_targeted_token_reuse_by_ips_low, 
        SUM(CASE WHEN label_items.name LIKE '%:targeted:aggregate:volumetric:session:token_reuse:ip:medium%' THEN 1 ELSE 0 END) is_targeted_token_reuse_by_ips_medium, 
        SUM(CASE WHEN label_items.name LIKE '%:targeted:aggregate:volumetric:session:token_reuse:ip:high%' THEN 1 ELSE 0 END) is_targeted_token_reuse_by_ips_high, 
        SUM(CASE WHEN label_items.name LIKE '%:targeted:aggregate:volumetric:session:token_reuse:asn:low%' THEN 1 ELSE 0 END) is_targeted_token_reuse_by_asn_low, 
        SUM(CASE WHEN label_items.name LIKE '%:targeted:aggregate:volumetric:session:token_reuse:asn:medium%' THEN 1 ELSE 0 END) is_targeted_token_reuse_by_asn_medium, 
        SUM(CASE WHEN label_items.name LIKE '%:targeted:aggregate:volumetric:session:token_reuse:asn:high%' THEN 1 ELSE 0 END) is_targeted_token_reuse_by_asn_high, 
        SUM(CASE WHEN label_items.name LIKE '%:targeted:aggregate:volumetric:session:token_reuse:country:low%' THEN 1 ELSE 0 END) is_targeted_token_reuse_by_country_low, 
        SUM(CASE WHEN label_items.name LIKE '%:targeted:aggregate:volumetric:session:token_reuse:country:medium%' THEN 1 ELSE 0 END) is_targeted_token_reuse_by_country_medium, 
        SUM(CASE WHEN label_items.name LIKE '%:targeted:aggregate:volumetric:session:token_reuse:country:high%' THEN 1 ELSE 0 END) is_targeted_token_reuse_by_country_high, 
        SUM(CASE WHEN label_items.name LIKE '%:targeted:aggregate:coordinated_activity:low%' THEN 1 ELSE 0 END) is_coordinated_activity_low,
        SUM(CASE WHEN label_items.name LIKE '%:targeted:aggregate:coordinated_activity:medium%' THEN 1 ELSE 0 END) is_coordinated_activity_medium,
        SUM(CASE WHEN label_items.name LIKE '%:targeted:aggregate:coordinated_activity:high%' THEN 1 ELSE 0 END) is_coordinated_activity_high,
        -- ATP
        SUM(CASE WHEN label_items.name LIKE '%::managed:aws:atp:%' THEN 1 ELSE 0 END) is_atp,

        -- ACFP
        SUM(CASE WHEN label_items.name LIKE '%::managed:aws:acfp:%' THEN 1 ELSE 0 END) is_acfp,


        -- OTHER RULES       
        SUM(CASE WHEN label_items.name = 'awswaf:managed:token:accepted' THEN 1 ELSE 0 END) token_valid,
        SUM(CASE WHEN label_items.name = 'awswaf:managed:token:rejected' THEN 1 ELSE 0 END) token_rejected,
        SUM(CASE WHEN label_items.name = 'awswaf:managed:token:absent' THEN 1 ELSE 0 END) tokeN_absent,
        SUM(CASE WHEN label_items.name = 'awswaf:managed:token:rejected:not_solved' THEN 1 ELSE 0 END) token_rejected_not_solved,
        SUM(CASE WHEN label_items.name = 'awswaf:managed:token:rejected:expired' THEN 1 ELSE 0 END) token_rejected_expired,
        SUM(CASE WHEN label_items.name = 'awswaf:managed:token:rejected:domain_mismatch' THEN 1 ELSE 0 END) token_rejected_domain_mismatch,
        SUM(CASE WHEN label_items.name = 'awswaf:managed:token:rejected:invalid' THEN 1 ELSE 0 END) token_rejected_invalid,

    
        -- Static Assets
        SUM(CASE WHEN ELEMENT_AT(SPLIT(httprequest.uri, '.'), -1) IN ('css', 'js','ejs') THEN 1 ELSE 0 END) AS css_js_ejs,
        SUM(CASE WHEN ELEMENT_AT(SPLIT(httprequest.uri, '.'), -1) IN ('ico','svg','svgz','jpg','jpeg','gif','ico','png','bmp','pict','tif','tiff','webp','eps') THEN 1 ELSE 0 END) AS images,
        SUM(CASE WHEN ELEMENT_AT(SPLIT(httprequest.uri, '.'), -1) IN ( 'csv','doc','docx','xls','xlsx','pdf','pptx','ppt','txt','ps','json') THEN 1 ELSE 0 END) AS documents,
        SUM(CASE WHEN ELEMENT_AT(SPLIT(httprequest.uri, '.'), -1) IN ( 'cfm','xml','yaml','html','htm', 'php', 'min', 'aspx') THEN 1 ELSE 0 END) AS markup,
        SUM(CASE WHEN ELEMENT_AT(SPLIT(httprequest.uri, '.'), -1) IN ('ico') THEN 1 ELSE 0 END) AS ico,
        SUM(CASE WHEN ELEMENT_AT(SPLIT(httprequest.uri, '.'), -1) IN ('woff','woff2','ttf','otf','eot') THEN 1 ELSE 0 END) AS font,
        SUM(CASE WHEN ELEMENT_AT(SPLIT(httprequest.uri, '.'), -1) IN ('pls','swf','midi','mid','mp3','mp4','wav','wma') THEN 1 ELSE 0 END) AS media,
        SUM(CASE WHEN ELEMENT_AT(SPLIT(httprequest.uri, '.'), -1) IN ('jar','torrent','rar','zip','tar') THEN 1 ELSE 0 END) AS compressed_file,
        
        -- Bot Categories
        SUM(CASE WHEN label_items.name LIKE '%:bot-control:bot:category:advertising%' THEN 1 ELSE 0 END) advertising,
        SUM(CASE WHEN label_items.name LIKE '%:bot-control:bot:category:archiver%' THEN 1 ELSE 0 END) archiver,
        SUM(CASE WHEN label_items.name LIKE '%:bot-control:bot:category:ai%' THEN 1 ELSE 0 END) ai,
        SUM(CASE WHEN label_items.name LIKE '%:bot-control:bot:category:content_fetcher%' THEN 1 ELSE 0 END) content_fetcher,
        SUM(CASE WHEN label_items.name LIKE '%:bot-control:bot:category:email_client%' THEN 1 ELSE 0 END) email_client,
        SUM(CASE WHEN label_items.name LIKE '%:bot-control:bot:category:link_checker%' THEN 1 ELSE 0 END) link_checker,
        SUM(CASE WHEN label_items.name LIKE '%:bot-control:bot:category:miscellaneous%' THEN 1 ELSE 0 END) miscellaneous,
        SUM(CASE WHEN label_items.name LIKE '%:bot-control:bot:category:monitoring%' THEN 1 ELSE 0 END) monitoring,
        SUM(CASE WHEN label_items.name LIKE '%:bot-control:bot:category:scraping_framework%' THEN 1 ELSE 0 END) scraping_framework,
        SUM(CASE WHEN label_items.name LIKE '%:bot-control:bot:category:search_engine%' THEN 1 ELSE 0 END) search_engine,
        SUM(CASE WHEN label_items.name LIKE '%:bot-control:bot:category:security%' THEN 1 ELSE 0 END) security,
        SUM(CASE WHEN label_items.name LIKE '%:bot-control:bot:category:seo%' THEN 1 ELSE 0 END) seo,
        SUM(CASE WHEN label_items.name LIKE '%:bot-control:bot:category:social_media%' THEN 1 ELSE 0 END) social_media,
        SUM(CASE WHEN label_items.name LIKE '%:bot-control:bot:category:http_library%' THEN 1 ELSE 0 END) http_library,

        
        -- Other stats distinct Count
        SUM (CASE WHEN   try( filter( httprequest.headers, x -> LOWER(x.name) = 'x-forwarded-for' )[1].value ) is NULL then 0 ELSE 1 END ) AS header_x_forwarded_for_provided,
        COUNT (DISTINCT  try( filter( httprequest.headers, x -> LOWER(x.name) = 'x-forwarded-for' )[1].value )) AS unique_header_x_forwarded_for,
        COUNT (DISTINCT  try( filter( httprequest.headers, x -> LOWER(x.name) = 'accept-encoding' )[1].value )) AS unique_header_accept_encoding,
        COUNT (DISTINCT  try( filter( httprequest.headers, x -> LOWER(x.name) = 'accept-language' )[1].value )) AS unique_header_accept_language,
        COUNT(DISTINCT httprequest.clientip) AS unique_client_ip,
        COUNT(DISTINCT try( filter( httprequest.headers, x -> LOWER(x.name) = 'user-agent' )[1].value)) AS unique_header_user_agent,
        COUNT(DISTINCT httprequest.uri) AS unique_uri,
        COUNT(DISTINCT try( filter( httprequest.headers, x -> LOWER(x.name) = 'host' )[1].value )) AS unique_header_host

    FROM  waf_logs_partition_projection cross join 
    UNNEST( CASE WHEN cardinality(labels) >= 1
               THEN labels
               ELSE array[ cast( row('NOLABEL') as row(name varchar)) ]  
			END ) AS t(label_items)
    WHERE
log_time >= date_format(current_date - interval '7' day, '%Y/%m/%d')  
    GROUP BY log_time
order by log_time desc
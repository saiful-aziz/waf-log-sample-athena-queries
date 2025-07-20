-- ref: https://docs.aws.amazon.com/athena/latest/ug/create-waf-table-partition-projection.html
-- replace S3 location with your S3 bucket which being used to store the WAF log, i.e aws-waf-logs-xxxxxx
-- you need to create another S3 bucket also to store the athena query log, i.e waf-log-athena-query-results
-- create a database first with 'create-database.sql', then you need to select the database on the left side of athena query editor option before creating a table by running "create-athena-table.sql"

CREATE EXTERNAL TABLE `waf_logs_partition_projection`(
  `timestamp` bigint, 
  `formatversion` int, 
  `webaclid` string, 
  `terminatingruleid` string, 
  `terminatingruletype` string, 
  `action` string, 
  `terminatingrulematchdetails` array<struct<conditiontype:string,sensitivitylevel:string,location:string,matcheddata:array<string>>>, 
  `httpsourcename` string, 
  `httpsourceid` string, 
  `rulegrouplist` array<struct<rulegroupid:string,terminatingrule:struct<ruleid:string,action:string,rulematchdetails:array<struct<conditiontype:string,sensitivitylevel:string,location:string,matcheddata:array<string>>>>,nonterminatingmatchingrules:array<struct<ruleid:string,action:string,overriddenaction:string,rulematchdetails:array<struct<conditiontype:string,sensitivitylevel:string,location:string,matcheddata:array<string>>>,challengeresponse:struct<responsecode:string,solvetimestamp:string>,captcharesponse:struct<responsecode:string,solvetimestamp:string>>>,excludedrules:string>>, 
  `ratebasedrulelist` array<struct<ratebasedruleid:string,limitkey:string,maxrateallowed:int>>, 
  `nonterminatingmatchingrules` array<struct<ruleid:string,action:string,rulematchdetails:array<struct<conditiontype:string,sensitivitylevel:string,location:string,matcheddata:array<string>>>,challengeresponse:struct<responsecode:string,solvetimestamp:string>,captcharesponse:struct<responsecode:string,solvetimestamp:string>>>, 
  `requestheadersinserted` array<struct<name:string,value:string>>, 
  `responsecodesent` string, 
  `httprequest` struct<clientip:string,country:string,headers:array<struct<name:string,value:string>>,uri:string,args:string,httpversion:string,httpmethod:string,requestid:string,fragment:string,scheme:string,host:string>,
  `labels` array<struct<name:string>>, 
  `captcharesponse` struct<responsecode:string,solvetimestamp:string,failurereason:string>, 
  `challengeresponse` struct<responsecode:string,solvetimestamp:string,failurereason:string>, 
  `ja3fingerprint` string, 
  `ja4fingerprint` string, 
  `oversizefields` string, 
  `requestbodysize` int, 
  `requestbodysizeinspectedbywaf` int)
  PARTITIONED BY ( 
   `log_time` string)
ROW FORMAT SERDE 
  'org.openx.data.jsonserde.JsonSerDe' 
STORED AS INPUTFORMAT 
  'org.apache.hadoop.mapred.TextInputFormat' 
OUTPUTFORMAT 
  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION
  's3://amzn-s3-demo-bucket/AWSLogs/AWS_ACCOUNT_NUMBER/WAFLogs/cloudfront/testui/'
TBLPROPERTIES (
 'projection.enabled'='true',
  'projection.log_time.format'='yyyy/MM/dd/HH/mm',
  'projection.log_time.interval'='1',
  'projection.log_time.interval.unit'='minutes',
  'projection.log_time.range'='2025/01/01/00/00,NOW',
  'projection.log_time.type'='date',
  'storage.location.template'='s3://amzn-s3-demo-bucket/AWSLogs/AWS_ACCOUNT_NUMBER/WAFLogs/cloudfront/testui/${log_time}')
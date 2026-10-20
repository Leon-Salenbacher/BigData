CREATE EXTERNAL TABLE IF NOT EXISTS title_basics (
 tconst STRING, title_type STRING, primary_title STRING, original_title STRING,
 is_adult DECIMAL(1,0), start_year DECIMAL(4,0), end_year STRING,
 runtime_minutes INT, genres STRING
) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE LOCATION '/user/hadoop/imdb/title_basics'
TBLPROPERTIES ('skip.header.line.count'='1');

CREATE EXTERNAL TABLE IF NOT EXISTS title_ratings (
 tconst STRING, average_rating DECIMAL(3,1), num_votes BIGINT
) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE LOCATION '/user/hadoop/imdb/title_ratings'
TBLPROPERTIES ('skip.header.line.count'='1');

CREATE EXTERNAL TABLE IF NOT EXISTS name_basics (
 nconst STRING, primary_name STRING, birth_year INT, death_year STRING,
 primary_profession STRING, known_for_titles STRING
) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE LOCATION '/user/hadoop/imdb/name_basics'
TBLPROPERTIES ('skip.header.line.count'='1');

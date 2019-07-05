import configparser


# CONFIG
config = configparser.ConfigParser()
config.read('dwh.cfg')
ARN = config.get('IAM_ROLE','ARN')
# DROP TABLES

staging_events_table_drop = "drop table if exists staging_events"
staging_songs_table_drop = "drop table if exists staging_songs"
songplay_table_drop = "drop table if exists songplay"
user_table_drop = "drop table if exists user_table"
song_table_drop = "drop table if exists song"
artist_table_drop = "drop table if exists artist"
time_table_drop = "drop table if exists time"

# CREATE TABLES

staging_events_table_create= ("""create table if not exists staging_events 
(artist varchar, 
auth varchar, 
firstName varchar, 
gender varchar(1), 
iteminSession int, 
lastName varchar, 
length float, 
level varchar(4), 
location varchar, 
method varchar(3), 
page varchar, 
registration bigint, 
sessionId int, 
song varchar, 
status int, 
ts bigint, 
userAgent varchar, 
userid int)
""")

staging_songs_table_create = ("""create table if not exists staging_songs
(num_songs int, 
artist_id varchar, 
artist_latitude float,
artist_longitude float,
artist_location varchar,
artist_name varchar, 
song_id varchar,
title varchar,
duration float,
year int)
""")

songplay_table_create = ("""create table if not exists songplay
(songplay_id int IDENTITY (0,1) PRIMARY KEY,
ts bigint, 
userid int NOT NULL distkey,
level varchar(4), 
song_id varchar NOT NULL,
artist_id varchar NOT NULL,
sessionId int NOT NULL, 
location varchar, 
userAgent varchar
)
INTERLEAVED SORTKEY(songplay_id, userid, song_id)

""")

user_table_create = ("""create table if not exists user_table
(userid int PRIMARY KEY sortkey distkey, 
firstName varchar,
lastName varchar,
gender varchar(1), 
level varchar(4));
""")

song_table_create = ("""create table if not exists song
(song_id varchar PRIMARY KEY sortkey,
title varchar,
artist_id varchar NOT NULL distkey,
year int NOT NULL, 
duration float);
""")

artist_table_create = ("""create table if not exists artist
(artist_id varchar PRIMARY KEY sortkey distkey, 
artist_name varchar, 
artist_location varchar,
artist_latitude float,
artist_longitude float);
""")

time_table_create = ("""create table if not exists time
(ts timestamp PRIMARY KEY,
hour int, 
day int,
week int,
month int,
year int,
weekday varchar)
diststyle all;
""")

# STAGING TABLES

staging_events_copy = ("""copy staging_events from 's3://udacity-dend/log_data' 
credentials 'aws_iam_role={}'
json 'auto';
""").format(ARN)

staging_songs_copy = ("""copy staging_songs from 's3://udacity-dend/song_data' 
credentials 'aws_iam_role={}'
json 'auto';
""").format(ARN)

# FINAL TABLES
songplay_table_insert = (""" INSERT INTO songplay 
(ts, userid, level, song_id, artist_id, sessionId, location, userAgent)
SELECT a.ts, a.userid, a.level, b.song_id, b.artist_id, a.sessionId, a.location, a.userAgent
FROM staging_events a
JOIN staging_songs b ON a.song = b.title AND a.artist=b.artist_name
WHERE a.page = 'NextSong'
GROUP BY 1,2,3,4,5,6,7,8
""")

user_table_insert = (""" INSERT INTO user_table
(userid, firstName, lastName, gender, level)
SELECT DISTINCT a.userid, a.firstName, a.lastName, a.gender, a.level
FROM staging_events a 
WHERE a.page = 'NextSong'
GROUP BY 1,2,3,4,5
""")

song_table_insert = ("""INSERT INTO song
(song_id, title, artist_id, year, duration)
SELECT DISTINCT b.song_id, b.title, b.artist_id, b.year, b.duration
FROM staging_songs b
GROUP BY 1,2,3,4,5
""")

artist_table_insert = ("""INSERT INTO artist
(artist_id, artist_name, artist_location, artist_latitude, artist_longitude)
SELECT DISTINCT b.artist_id, b.artist_name, b.artist_location, b.artist_latitude, b.artist_longitude
FROM staging_songs b
GROUP BY 1,2,3,4,5
""")

time_table_insert = ("""INSERT INTO time
(ts, hour, day, week, month, year, weekday)
SELECT DISTINCT b.ts, 
extract(hour from b.ts) as hour, 
extract(day from b.ts) as day,
extract(week from b.ts) as week,
extract(month from b.ts) as month, 
extract(year from b.ts) as year,
extract(weekday from b.ts) as weekday
FROM
(select distinct timestamp 'epoch' + a.ts * interval '1 second' AS ts FROM songplay a) b
""")

# QUERY LISTS

create_table_queries = [staging_events_table_create, staging_songs_table_create, songplay_table_create, user_table_create, song_table_create, artist_table_create, time_table_create]
drop_table_queries = [staging_events_table_drop, staging_songs_table_drop, songplay_table_drop, user_table_drop, song_table_drop, artist_table_drop, time_table_drop]
copy_table_queries = [staging_events_copy, staging_songs_copy]
insert_table_queries = [songplay_table_insert, user_table_insert, song_table_insert, artist_table_insert, time_table_insert]

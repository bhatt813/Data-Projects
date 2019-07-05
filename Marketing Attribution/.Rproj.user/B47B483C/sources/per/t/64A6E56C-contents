require(RSQLite)
require(XLConnect)
require(sqldf)
##Loading the Data
location_csv <- "/Users/neilbhatt/Documents/Earnin/AssessmentData/"
db <- dbConnect(SQLite(), dbname="Earnin.sqlite")
dbWriteTable(conn=db, name = "attribution", value=paste0(location_csv,"attribution.csv"))
dbWriteTable(conn=db, name = "device", value=paste0(location_csv,"device.csv"))
dbWriteTable(conn=db, name = "item", value=paste0(location_csv,"item.csv"))
dbWriteTable(conn=db, name = "sale", value=paste0(location_csv,"sale.csv"))
dbWriteTable(conn=db, name = "user_device", value=paste0(location_csv,"user_device.csv"))
dbWriteTable(conn=db, name = "user", value=paste0(location_csv,"user.csv"))
attribution <- dbGetQuery(db, "SELECT * FROM attribution")
device <- dbGetQuery(db, "SELECT * FROM device")
item <- dbGetQuery(db, "SELECT * FROM item")
sale <- dbGetQuery(db, "SELECT * FROM sale")
user_device <- dbGetQuery(db, "SELECT * FROM user_device")
user <- dbGetQuery(db, "SELECT * FROM user")


#1. 
device <- dbGetQuery(db, 
  "SELECT a.user_id, count(a.device_id) as Device, count(distinct a.device_type) as Device_Type, 
   count(distinct operating_systems) as OS
   FROM
    (SELECT a.user_id, a.device_id, b.device_type, b.operating_system
    FROM user_device a
    JOIN device b on a.device_id = b.id
    GROUP BY 1,2,3) a
   GROUP BY 1
   ORDER BY 2,3")
##difference in total devices - distinct device type
device$diff <- device$`count(a.device_id)`-device$`count(distinct a.device_type)`
device_flag <- subset(device,device$diff >=1)

d2 <- dbGetQuery(db,"SELECT a.user_id, a.device_id, b.device_type, b.operating_system
  FROM user_device a
  JOIN device b on a.device_id = b.id
  JOIN (SELECT a.user_id, count(a.device_id) as ct FROM user_device a GROUP BY 1) c ON a.user_id = c.user_id
  WHERE c.ct > 1
  GROUP BY 1,2,3")

d3 <- dbGetQuery(db, "SELECT a.user_id, a.device_id, b.device_type, b.operating_system
  FROM user_device a
                 JOIN device b on a.device_id = b.id
                 JOIN (SELECT a.user_id, count(a.device_id) as ct FROM user_device a GROUP BY 1) c ON a.user_id = c.user_id
                 WHERE c.ct > 2
                 GROUP BY 1,2,3")


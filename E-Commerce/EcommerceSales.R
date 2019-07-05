require(RSQLite)
require(XLConnect)
require(sqldf)
##Loading the Data
location_csv <- "/Users/neilbhatt/Documents/Touch of Modern/"
db <- dbConnect(SQLite(), dbname="TouchOfModern.sqlite")
dbWriteTable(conn=db, name = "orders", value=paste0(location_csv,"orders.csv"))
dbWriteTable(conn=db, name = "users", value=paste0(location_csv,"users.csv"))

users <- dbGetQuery(db, "SELECT * FROM users")
orders <- dbGetQuery(db, "SELECT * FROM orders")

#Top 10 Spenders
T10_spenders <- dbGetQuery(db, "SELECT user_id, SUM(item_total - discounts_applied)
                           FROM orders
                           WHERE payment_reject = 'False'
                           GROUP BY 1
                           ORDER BY 2 desc
                           LIMIT 10")
#Second highest Order by user
SecondHighestOrders <- dbGetQuery(db, "SELECT a.user_id, MAX(a.item_total)
                                  FROM orders a
                                  JOIN (SELECT user_id, MAX(item_total) as MX FROM orders WHERE payment_reject = 'False'
                                        GROUP BY 1) b ON b.user_id = a.user_id
                                  WHERE payment_reject = 'False'
                                  AND item_total < b.MX
                                  GROUP BY 1")

##Highest Orders used to validate results from above (second highest < highest)
HighestOrders <- dbGetQuery(db,"SELECT a.user_id, MAX(a.item_total)
                            FROM orders a GROUP BY 1")
"Number of users with >1 purchase to validate Second Highest Orders Result 
(7,459 users with > 1 purchase)"
db2 <- dbGetQuery(db, "SELECT b.user_id FROM (SELECT a.user_id, count(a.id) as CT FROM orders a WHERE a.payment_reject = 'False' group by 1) b 
                  WHERE b.CT > 1")

##Shipping
dbGetQuery(db, "SELECT Distinct shipping_cost from orders")
"There are 4 shipping levels"

##Summary statistics based on shipping levels
library(dplyr)
Shipping_Table <- orders %>% group_by(shipping_cost) %>% summarize(mean = mean(item_total), 
                                                                   min = min(item_total), 
                                                                   med=median(item_total), 
                                                                   max=max(item_total))
Shipping_Table <- cbind(Shipping_Table, orders %>% group_by(shipping_cost) %>% tally)
"Based on the order min and max by shipping cost it, the shipping cost is based on item prices.  
There is the 10,15 which splits at $115
The 20,25 split also has a similar split at $115 as well, so when we look at costs based on 
country with US shipping set of (10,15) & UK shipping set of (20,25)"

cor(Shipping_Table$shipping_cost, Shipping_Table$n)

##Day of the Week Order
orders$day <- weekdays(as.Date(orders$order_time))

By_day <- orders %>% group_by(day) %>% summarize(mean = mean(item_total), min = min(item_total), med=median(item_total), max=max(item_total))
By_day <- cbind(By_day, orders %>% group_by(day) %>% tally)
library(ggplot2)
Day_plot <- ggplot(data=By_day, aes(x=day, y=n,group=1)) +
  geom_point(stat="identity", fill="steelblue") + geom_line() +
  scale_x_discrete(limits=c('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'))+
  xlab('Day of the Week') + ylab('Order Count')
Day_plot
"Saturday, Sunday, Monday are the highest order days; Wednesday has the lowest orders
Ramp up Wednesday thru Saturday, Decline Saturday thru Wednesday"

#Orders by Month
orders$month <- format(as.Date(orders$order_time),format="%B")

By_month <- orders %>% group_by(month) %>% summarize(mean = mean(item_total), min = min(item_total), med=median(item_total), max=max(item_total))
By_month <- cbind(By_month, orders %>% group_by(month) %>% tally)
library(ggplot2)
Month_plot <- ggplot(data=By_month, aes(x=month, y=n, group=1)) +
  geom_point(stat="identity", fill="steelblue") + geom_line() + 
  scale_x_discrete(limits=c('January','February','March','April','May','June','July','August','September','October','November','December'))+
  xlab('Month') + ylab('Order Count') 
Month_plot
##Revenue by Month (US)
REV_US <- dbGetQuery(db, "SELECT strftime('%m', a.order_time) AS Date, SUM(a.item_total + a.shipping_cost - a.discounts_applied) AS REV
                  FROM orders a
                  JOIN users b ON a.user_id = b.id
                  WHERE payment_reject = 'False'
                  AND b.country = 'US'
                  GROUP BY 1
                  ORDER BY 1 asc")
MonthREV_plot_US <- ggplot(data=REV_US, aes(x=Date, y=REV, group=1)) +
  geom_point(stat="identity", fill="steelblue") + geom_line() + 
  xlab('Month') + ylab('Revenue') +ggtitle("US Revenue by Month") + geom_smooth(method = "lm",colour='red')
MonthREV_plot_US
##Revenue by Month (UK)
REV_CA <- dbGetQuery(db, "SELECT strftime('%m', a.order_time) AS Date, SUM(a.item_total + a.shipping_cost - a.discounts_applied) AS REV
                     FROM orders a
                     JOIN users b ON a.user_id = b.id
                     WHERE payment_reject = 'False'
                     AND b.country = 'CA'
                     GROUP BY 1
                     ORDER BY 1 asc")
MonthREV_plot_CA <- ggplot(data=REV_CA, aes(x=Date, y=REV, group=1)) +
  geom_point(stat="identity", fill="steelblue") + geom_line() + 
  xlab('Month') + ylab('Revenue') +ggtitle("CA Revenue by Month") + geom_smooth(method = "lm",colour='red')
MonthREV_plot_CA
"There is definitely some seasonality with March, May, August, October, December peaks and 
troughs in February, April, June, September, November
CA has a larger MoM revenue growth rate than the US does."

###Customer orders US
order_count_US <- dbGetQuery(db, "SELECT a.user_id, count(a.id) as order_count, sum(item_total) as item_rev 
                          FROM orders a 
                          JOIN users b ON a.user_id = b.id
                          WHERE payment_reject = 'False'
                          AND b.country = 'US' 
                          GROUP BY 1")
US_Boxplot <- boxplot(order_count$order_count) + title("US Orders Box Plot")
US_Boxplot
summary(order_count_US$order_count)
###Customer orders CA
order_count_CA <- dbGetQuery(db, "SELECT a.user_id, count(a.id) as order_count, sum(item_total) as item_rev 
                             FROM orders a 
                             JOIN users b ON a.user_id = b.id
                             WHERE payment_reject = 'False'
                             AND b.country = 'CA' 
                             GROUP BY 1")
CA_Boxplot <- boxplot(order_count_CA$order_count) + title("CA Orders Box Plot")
CA_Boxplot
summary(order_count_CA$order_count)
"A typical customer made 4 purchases in the year, 25% of the users made more than 8 purchases in a year. 
US users have a higher max orders per year than CA"

#By Gender
order_count_gender <- dbGetQuery(db, "SELECT a.user_id,b.gender,b.country, 
                             count(a.id) as order_count, 
                             sum(item_total+shipping_cost-discounts_applied) as REV 
                             FROM orders a 
                             JOIN users b ON a.user_id = b.id
                             WHERE payment_reject = 'False'
                             GROUP BY 1")
country_gender<-order_count_gender %>% group_by(gender,country) %>% 
  summarize(mean = mean(REV), min = min(REV), med=median(REV), max=max(REV))
country_gender<-cbind(country_gender, order_count_gender %>% group_by(gender, country) %>% tally)

gender<-order_count_gender %>% group_by(gender) %>% 
  summarize(mean = mean(REV), min = min(REV), med=median(REV), max=max(REV))
gender<-cbind(gender, order_count_gender %>% group_by(gender) %>% tally)
"A typical male has higher REV than a typical female. 
Females account for higher REV and orders than males in both countries
Canada has a greater mean purchase across genders than US"

##By Age
Age <- dbGetQuery(db, "SELECT a.user_id, b.gender, 
                              Case when b.age <=19 THEN '0-20'
                                   when b.age >19 and b.age<=29 THEN '20-29'
                                   when b.age >29 and b.age<=39 THEN '30-39'          
                                   when b.age >39 and b.age<=49 THEN '40-49'
                                   when b.age >49 and b.age<=59 THEN '50-59'
                                   when b.age >59 THEN '60+'
                                ELSE '' end as Age_Range, b.country,
                             count(a.id) as order_count, 
                             sum(item_total+shipping_cost-discounts_applied) as REV 
                    FROM orders a 
                    JOIN users b ON a.user_id = b.id
                    WHERE payment_reject = 'False'
                    GROUP BY 1")
Age_Table_Gender <- Age %>% group_by(gender, Age_Range) %>% 
  summarize(mean = mean(REV), min = min(REV), med=median(REV), max=max(REV))
Age_Table_Gender <-cbind(Age_Table_Gender, Age %>% group_by(gender, Age_Range) %>% tally)
Age_Table_Gender
Age_Table <- Age %>% group_by(Age_Range) %>% 
  summarize(mean = mean(REV), min = min(REV), med=median(REV), max=max(REV))
Age_Table <-cbind(Age_Table, Age %>% group_by(Age_Range) %>% tally)
Age_Table
Age_Table_Country <- Age %>% group_by(country, Age_Range) %>% 
  summarize(mean = mean(REV), min = min(REV), med=median(REV), max=max(REV))
Age_Table_Country <-cbind(Age_Table_Country, Age %>% group_by(country, Age_Range) %>% tally)
"The typical and average customer across genders tends to spend more the older they are, 
with most orders coming from male customers in their 30s then 40s, and coming from female customers
in their 40s then 30s. By country grouping shows the same trend."

##Length on site with purchases and order count
onsite <- dbGetQuery(db, "SELECT a.user_id, b.gender, b.days_on_site_in_2016,
                          Case when b.age <=19 THEN '0-20'
                          when b.age >19 and b.age<=29 THEN '20-29'
                          when b.age >29 and b.age<=39 THEN '30-39'          
                          when b.age >39 and b.age<=49 THEN '40-49'
                          when b.age >49 and b.age<=59 THEN '50-59'
                          when b.age >59 THEN '60+'
                          ELSE '' end as Age_Range,
                          count(a.id) as order_count, 
                          sum(item_total+shipping_cost-discounts_applied) as REV 
                      FROM orders a 
                      JOIN users b ON a.user_id = b.id
                      WHERE payment_reject = 'False'
                      GROUP BY 1")
cor(onsite$days_on_site_in_2016,onsite$order_count)
cor(onsite$days_on_site_in_2016,onsite$REV)
"As would be expected, the more days on site the more revenue and orders made. 
Based on correlation close to 1 for days on site and order_count and revenue by user."   

onsite_table <- onsite %>% group_by(gender) %>% 
  summarize(mean = mean(days_on_site_in_2016), min = min(days_on_site_in_2016), 
            med=median(days_on_site_in_2016), max=max(days_on_site_in_2016))
onsite_table <-cbind(onsite_table, onsite %>% group_by(gender) %>% tally)
"On average males have spent more days on the site than females. 
The typical male or female spent 8 days on the site in 2016."

onsite_table_age <- onsite %>% group_by(gender, Age_Range) %>% 
  summarize(mean = mean(days_on_site_in_2016), min = min(days_on_site_in_2016), 
            med=median(days_on_site_in_2016), max=max(days_on_site_in_2016))
onsite_table_age <-cbind(onsite_table_age, onsite %>% group_by(gender, Age_Range) %>% tally)
"When looking at days on site by Age typical male customer in their 30s and 50s 
spend an extra day on the site (9 days) versus all other groups (8 days)."

'#
AB TEST BETWEEN desktop and mobile web landing to menu conversion with "Shop_conv.sql"
for shop traffic in the past 28 days
-- Must add resdshift passwords to script
#'

require(RPostgreSQL)
require(data.table)
require(dplyr)

connect_to_seg = function(){
  con_seg <- dbConnect(PostgreSQL(), dbname = "analytics", 
                       host = "veritas.c3byxptpwzdt.us-east-1.redshift.amazonaws.com", 
                       port = 5439, user = "[INSERT USER NAME HERE]", 
                       password = "[INSERT REDSHIFT PASSWORD HERE]")
  con_seg
}

con = connect_to_seg()

query = readLines('Shop_conv.sql')
#drop first comment line
query = paste(query[2:length(query)], collapse = " ")

#load traffic
DT = data.table(dbGetQuery(con, query))

# get conversion metric 
DT[,landing2menu := menu / landing]

#take sample
DT.s = sample_n(DT, .15 * nrow(DT))

#compare sample sizes for each population
table(DT.s$platform)

# perform 2 sample T-test (one shop's landing to menu conversion is independent of anothers)
t.test(x = DT.s[platform == 'Mobile_Web', .(landing2menu)], 
       y = DT.s[platform == 'Desktop_Web', .(landing2menu)],
       alternative = 'two.sided')

#compare P value -- desktop conversion much lower in this case. 


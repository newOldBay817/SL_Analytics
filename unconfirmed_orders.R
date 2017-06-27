library(dplyr)
library(data.table)
library(PostGresPacks)
library(lubridate)
library(purrr)
library(reshape2)

connect_to_seg = function(){
  con_seg <- dbConnect(PostgreSQL(), dbname = "analytics", 
                       host = "veritas.c3byxptpwzdt.us-east-1.redshift.amazonaws.com", 
                       port = 5439, user = "mypizza", 
                       password = "ji9P329nso9u3joinfcjd034")
  con_seg
}

#get online orders to tablet shops
tablet.orders = dbGetQuery(con, "SELECT * FROM mypizza.orders 
WHERE shop_id IN (SELECT shop_id FROM mypizza.shop_master WHERE default_transmission_method = 'tablet')
                           AND date_purchased >= CURRENT_DATE - 90 and deliver_at is NULL")
tablet.orders = data.table(tablet.orders)

tablet.orders[,confirm_time := confirmed_at - date_purchased]

#get admin_events from the tablet orders
tablet.events = dbGetQuery(con, paste0("select * from mypizza.admin_events where event_loggable_id in (", paste(unique(tablet.orders[,orders_id]), collapse = ", "), ")"))
tablet.events = data.table(tablet.events)

tablet.orders[is.na(deliver_at),] %>% select(orders_id, deliver_at, payment_status, date_purchased, confirmed_at, confirm_time) %>% arrange(-confirm_time)

#remove NA confirm times
orders = tablet.orders[!is.na(confirm_time),]


#anything with confirmation times which occur after the incoming > in_kitchen are problem orders
#get in the kitchen event for all orders
get_kitchen = function(order_id){
  kitch_date = tablet.events[event_loggable_id == order_id,][value == 'in_kitchen', created_at]
  return(kitch_date)
}
orders = data.table(orders)

orders[,kitch_time := get_kitchen(orders_id), by = orders_id]

orders.k = orders[!is.na(kitch_time),]

get_steps = function(order_id){
  e.df = tablet.events[event_loggable_id == order_id][order(created_at)][,step := c(1:nrow(tablet.events[event_loggable_id == order_id][order(created_at)]))]
  auto_approve = "auto-approve-success" %in% e.df$action
  auto_approve = ifelse(auto_approve == T, 1, 0)
  string = ifelse(auto_approve == 1, 'auto-approve-success',  'auto-approve-fail')
  auto_step = e.df[action == string, step]
  review_step = ifelse(auto_approve == 0, e.df[event_attribute == 'reviewed_at',step], 0)
  receipt_step = ifelse(is.numeric(e.df[action=='send-receipt',step]), e.df[action=='send-receipt',step], 0)
  kitchen_step = ifelse(is.numeric(e.df[value=='in_kitchen',step]), e.df[value =='in_kitchen',step], 0)
  delivery_step = ifelse(is.numeric(e.df[value=='out for delivery',step]), e.df[value=='out for delivery',step], 0)
  completed_step = ifelse(is.numeric(e.df[value=='completed',step]), e.df[value=='completed',step], 0)
  return(cbind(order_id, auto_approve, auto_step, review_step, receipt_step, kitchen_step, delivery_step, completed_step))
}

ord.df = orders.k[,.(orders_id, shop_id, date_purchased, confirmed_at, confirm_time, customer_emailed_at, kitch_time)][, confirm.problem := ifelse(abs(time_length(interval(confirmed_at, kitch_time), unit = 'minute')) >= 10, 1, 0)]
table(ord.df$confirm.problem)

write.csv(ord.df, 'orders.csv')

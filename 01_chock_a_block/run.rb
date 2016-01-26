sf = StockFighter.new ACCOUNT, VENUE, STOCK

purchased_count = 0
orders = []
current_order = nil
# Algorithm:
#   - Place limit order of size 100 @ 100 below market
#   - Wait until it is filled or market moves 200+ away
#   - (Cancel Order if necessary) and place new order
#
until purchased_count >= 100000 do
  quote = sf.quote
  puts "Intitial quote:"
  puts quote
  if quote[:bid]
    bid_price = quote[:bid] - BELOW_MARKET
  else
    bid_price = quote[:ask] - (2 * BELOW_MARKET)
  end
  processed_response = sf.buy_limit(PURCHASE_SIZE, bid_price)
  puts "Intitial Order"
  puts processed_response
  current_order = Order.new processed_response
  purchased_count += current_order.total_filled
  orders << current_order
  while(current_order.total_filled < PURCHASE_SIZE && quote[:bid] < current_order.price + 2*BELOW_MARKET)
    quote = sf.quote
    puts "Heartbeat Quote"
    puts quote
    puts "Purchased Count: #{purchased_count}"
    puts "Refreshing ... "
    purchased_count += current_order.refresh sf.order_status(current_order)
    puts "New Purchased Count: #{purchased_count}"
    sleep 1
  end
  unless current_order.total_filled == PURCHASE_SIZE
    puts "Market moved, cancelling!"
    sf.cancel(current_order)
  end
end



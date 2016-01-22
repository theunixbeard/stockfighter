class Order
  attr_accessor :id, :total_filled, :price
  def initialize api_response
    @id = api_response[:id]
    @price = api_response[:price]
    @total_filled = api_response[:totalFilled]
  end

  def refresh api_response
    fill_delta = api_response[:totalFilled] - @total_filled
    @total_filled = api_response[:totalFilled]
    return fill_delta
  end

end

class StockFighter
  def initialize account, venue, stock
    @account = account
    @venue = venue
    @stock = stock
  end

  def buy_market qty
    place_order qty, "buy", "market", 0
  end

  def buy_limit qty, price
    place_order qty, "buy", "limit", price
  end

  def place_order qty, buy_sell, order_type, price
    order = {
      account: @account,
      venue: @venue,
      symbol: @stock,
      price: price,
      qty: qty,
      direction: buy_sell,
      orderType: order_type
    }
    response = HTTParty.post("#{BASE_URL}/venues/#{@venue}/stocks/#{@stock}/orders",
      body: JSON.dump(order),
      headers: {"X-Starfighter-Authorization" => API_KEY}
    )
    return StockFighter.processed_response(response)
  end

  def self.processed_response response
    response = JSON.parse(response.body, symbolize_names: true)
    return response
  end

  def quote
    response =  HTTParty.get "#{BASE_URL}/venues/#{@venue}/stocks/#{@stock}/quote",
       headers: {"X-Starfighter-Authorization" => API_KEY}
    response = JSON.parse(response.body, symbolize_names: true)
    return response
  end

  def order_status order
    response = HTTParty.get "#{BASE_URL}/venues/#{@venue}/stocks/#{@stock}/orders/#{order.id}",
       headers: {"X-Starfighter-Authorization" => API_KEY}
    response = JSON.parse(response.body, symbolize_names: true)
    return response
  end

  def cancel order
    response = HTTParty.delete "#{BASE_URL}/venues/#{@venue}/stocks/#{@stock}/orders/#{order.id}"
    response = JSON.parse(response.body, symbolize_names: true)
    return response
  end
end

### Here is what the response looked like.

# {
#   "ok": true,
#   "symbol": "HOGE",
#   "venue": "FOOEX",
#   "direction": "buy",
#   "originalQty": 100,
#   "qty": 0,
#   "price": 25000,
#   "orderType": "limit",
#   "id": 6408,
#   "account": "HB61251714",
#   "ts": "2015-08-18T04:00:08.340298024+09:00",
#   "fills": [
#     {
#       "price": 5960,
#       "qty": 100,
#       "ts": "2015-08-18T04:00:08.340299592+09:00"
#     }
#   ],
#   "totalFilled": 100,
#   "open": false
# }



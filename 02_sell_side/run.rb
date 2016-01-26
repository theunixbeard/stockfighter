sf = StockFighter.new ACCOUNT, VENUE, STOCK

class MarketMaker
  attr_accessor :position, :buy_order, :sell_order, :last_quote
  def initialize sf
    @sf = sf
    @position = 0
    @last_quote = @sf.quote
    issue_buy
    issue_sell
  end

  def new_quote quote
    @last_quote = quote[:quote]
    # Analyze Existing Orders
    #   - Are any filled? (replace them)
    #   - Are any not the best offer? (cancel & replace)

    # Refresh Orders
    @buy_order.refresh @sf.order_status(@buy_order)
    @sell_order.refresh @sf.order_status(@sell_order)

    # Replace if filled/closed
    if @buy_order.closed
      issue_buy
    end
    if @sell_order.closed
      issue_sell
    end

    # Assess if not the best offer
    if @last_quote[:bid] && @last_quote[:bid] > @buy_order.price
      refresh_buy
    end
    if @last_quote[:ask] && @last_quote[:ask] < @sell_order.price
      refresh_sell
    end
  end

  def new_execution exec
    # Is it our order?
    #   - If so, refresh it
    #   - If not, do nothing
    return unless exec[:account] == ACCOUNT
    # TODO: IS THIS CODE EXECUTING ? NEVER SEEING POSITION PRINTOUT ...
    binding.pry

    if exec[:order][:direction] == "buy"
      quantity = @buy_order.refresh exec[:order]
      refresh_buy
      puts "Bought #{quantity}"
      @position += quantity
      puts "Position #{position}\n\n"
    end
    if exec[:order][:direction] == "sell"
      quantity = @sell_order.refresh exec[:order]
      refresh_sell
      puts "Sold #{quantity}"
      @position -= quantity
      puts "Position #{position}\n\n"
    end
  end

  private
  def refresh_buy
    old_buy = @buy_order.clone
    issue_buy
    cancel old_buy
  end
  def refresh_sell
    old_sell = @sell_order.clone
    issue_sell
    cancel old_sell
  end
  def issue_buy
    return if position > MAX_EXPOSURE - 2*ORDER_SIZE
    if @last_quote[:bid]
      price = @last_quote[:bid] + UNDERCUT
    else
      price  = @last_quote[:last] - SPREAD
    end
    resp = @sf.buy_limit(ORDER_SIZE, price)
    @buy_order = Order.new resp
  end
  def issue_sell
    return if position < (-1*MAX_EXPOSURE) + 2*ORDER_SIZE
    if @last_quote[:ask]
      price = @last_quote[:ask] - UNDERCUT
    else
      price  = @last_quote[:last] + SPREAD
    end
    resp = @sf.sell_limit(ORDER_SIZE, price)
    @sell_order = Order.new resp
  end
  def cancel order
    @sf.cancel order
  end
end

mm = MarketMaker.new sf

tickertape_url = "#{BASE_WS_URL}/#{ACCOUNT}/venues/#{VENUE}/tickertape/stocks/#{STOCK}"
execution_url = "#{BASE_WS_URL}/#{ACCOUNT}/venues/#{VENUE}/executions/stocks/#{STOCK}"

EM.run do
  tt_ws = Faye::WebSocket::Client.new(tickertape_url)
  ex_ws = Faye::WebSocket::Client.new(tickertape_url)

  tt_ws.on :open do |event|
    puts "TickerTape WS Open"
  end
  ex_ws.on :open do |event|
    puts "Execution WS Open"
  end

  tt_ws.on :close do |event|
    raise "\n\n\n\n\nTickerTape WS Closed !!!!\n\n"
    #ws = nil
  end
  ex_ws.on :close do |event|
    raise "\n\n\n\n\nExecution WS Closed !!!!\n\n"
    #ws = nil
  end

  # ORDER_SIZE, UNDERCUT
  tt_ws.on :message do |event|
    puts "\n\nTickerTape Message: "
    p [:message, event.data]
    quote = JSON.parse(event.data, symbolize_names: true)
    mm.new_quote quote
  end
  ex_ws.on :message do |event|
    puts "\n\nExecution Message: "
    p [:message, event.data]
    execution = JSON.parse(event.data, symbolize_names: true)
    mm.new_execution execution
  end

end

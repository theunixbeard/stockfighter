# Conntect to WS Quote API
# Write Quotes to File
#   - ENV var to know level
#   - Add Timestamp to file name
tickertape_url = "#{BASE_WS_URL}/#{ACCOUNT}/venues/#{VENUE}/tickertape/stocks/#{STOCK}"
execution_url = "#{BASE_WS_URL}/#{ACCOUNT}/venues/#{VENUE}/executions/stocks/#{STOCK}"

time = Time.now.getutc
bid = File.open("#{ENV['level']}-#{time}-bid.raw", 'w')
ask = File.open("#{ENV['level']}-#{time}-ask.raw", 'w')

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
    puts "Logging TickerTape..."
    #p [:message, event.data]
    quote = JSON.parse(event.data, symbolize_names: true)
    file.write
    mm.new_quote quote
  end
  ex_ws.on :message do |event|
    #puts "\n\nExecution Message: "
    #p [:message, event.data]
    #execution = JSON.parse(event.data, symbolize_names: true)
    #mm.new_execution execution
  end

end

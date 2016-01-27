# Conntect to WS Quote API
# Write Quotes to File
#   - ENV var to know level
#   - Add Timestamp to file name
tickertape_url = "#{BASE_WS_URL}/#{ACCOUNT}/venues/#{VENUE}/tickertape/stocks/#{STOCK}"
execution_url = "#{BASE_WS_URL}/#{ACCOUNT}/venues/#{VENUE}/executions/stocks/#{STOCK}"

BID_FILENAME = "lib/visualizer/highcharts/visualizer1/data/bid.json"
ASK_FILENAME = "lib/visualizer/highcharts/visualizer1/data/ask.json"

comma = nil # to not write comma before first line

bid_f = File.open(BID_FILENAME, 'w')
ask_f = File.open(ASK_FILENAME, 'w')
bid_f.write "["
ask_f.write "["

trap "SIGINT" do
  bid_f.puts "\n]"
  ask_f.puts "\n]"
  exit 130
end

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
    #p [:message, event.data]
    quote = JSON.parse(event.data, symbolize_names: true)[:quote]
    # Handle nils, add timestamp
    time = (Time.parse(quote[:quoteTime]).to_f * 1000).to_i
    puts "Logging TickerTape... #{time}"
    bid_f.write "#{comma}\n[#{time}, #{quote[:bid] || 0}]"
    ask_f.write "#{comma}\n[#{time}, #{quote[:ask] || 0}]"
    comma = ","
  end
  ex_ws.on :message do |event|
    #puts "\n\nExecution Message: "
    #p [:message, event.data]
    #execution = JSON.parse(event.data, symbolize_names: true)
    #mm.new_execution execution
  end

end

require_relative './lib/init.rb'
require_relative './lib/global_constants.rb'
require_relative './lib/ben_lib.rb'

level_map = {
  #"first_steps" => "00_first_steps",
  "chock_a_block" => "01_chock_a_block",
  "sell_side" => "02_sell_side"
  # TODO lvl 4, 5, 6
}

# Get desired level
level = ARGV[0]
ENV['level'] = level
command = ARGV[1]

class GM
  def self.start level
    response = HTTParty.post("#{BASE_GM_URL}/levels/#{level}",
      headers: {"Cookie" => "api_key=#{API_KEY}"}
    )
    response = JSON.parse(response.body, symbolize_names: true)
  end
  def self.restart
    execute "restart"
  end
  def self.stop
    execute "stop"
  end
  def self.resume
    execute "resume"
  end
  private
  def self.execute method
    instance_id = File.open('instance_id', 'rb') { |f| f.read }
    response = HTTParty.post("#{BASE_GM_URL}/instances/#{instance_id}/#{method}",
      headers: {"Cookie" => "api_key=#{API_KEY}"}
    )
    response = JSON.parse(response.body, symbolize_names: true)
  end
end

if command == "restart"
  response = GM.restart
elsif command == "resume"
  response = GM.resume
elsif command == "stop"
  response = GM.stop
  puts response
  exit
else
  response = GM.start level
end

unless response[:ok]
  puts response
  exit
end

# Set VENUE / STOCK / ACCOUNT
VENUE = response[:venues][0]
STOCK = response[:tickers][0]
ACCOUNT = response[:account]
INSTANCE_ID = response[:instanceId]
File.open("instance_id", 'w') {|f| f.write(INSTANCE_ID) }

if command == "visualize"
  require_relative "./lib/visualizer.rb"
else
  # Require level constants & run
  require_relative "./#{level_map[level]}/constants.rb"
  require_relative "./#{level_map[level]}/run.rb"
end

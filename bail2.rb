require 'open-uri'
require 'timers'
require 'json'
require 'ruby-duration'

class Bail
  def initialize
    @last_hour = []
    @doc = nil
    @page = "https://www.indiegogo.com/private_api/campaigns/1343420/funds.json"
    @ua = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.130 Safari/537.36"
    @speed = 0
    @goal = 1000000
    @sofar = 0
    @data_json = "res/data.json"
    @data_bank = "res/data.txt"
    @timers = Timers::Group.new
    @oservation_time = 120 
  end
  
  def git_push
    begin
      puts "#{compute_date}: Pushing on git.."
      system("sh push.sh")
    rescue Exception => e
      puts "[ERROR] #{e.message}"
    end
  end
  
  def download
    success = false
    begin
      @doc = open(@page, 'User-Agent' => @ua).read
      success = true
    rescue Exception => e
      success = false
      puts "[ERROR] #{e.message}"
    end
    success
  end
  
  def read_funds
    hash = JSON(@doc)
    @sofar = hash["response"]["collected_funds"].to_i
    puts @sofar
    @sofar
  end
  
  def collect_update
    print "#{compute_date}: Collecting new update.. "
    @last_hour.shift if @last_hour.size >= 6
    if download
      new_reading = read_funds
      @last_hour.push(new_reading)
      save = compute_date
      save << " - "
      save << @sofar.to_s
      save << "\n"
      File.open(@data_bank, 'a') { |file| file.write(save); }
      new_json
    end
    puts
  end
  
  def compute_speed
    hourly_speed = 0
    # are we really moving?
    if @last_hour.size > 0
      # compute the speed relative to the number of samples gathered
      relative_speed = (@last_hour.last - @last_hour.first) / @last_hour.size 
      # compute the ratio only if needed
      hourly_speed = @last_hour.size < 6 ? relative_speed * 60 / @last_hour.size : relative_speed
    end
    hourly_speed
  end
  
  def compute_left
    left = ""
    if @sofar <= @goal
      resto = @sofar % @goal
      if resto != 0
        missing_funds = @goal - resto
        if @speed > 0
          hours_left = (missing_funds / @speed).ceil.to_i
          if hours_left < 24
            left = Duration.new(:hours => hours_left).format("%h%~h")
          else
            left = Duration.new(:hours => hours_left).format("%d%~d %hh")
          end
        else
          left = "Infinite"
        end
      else
        left = "--"
      end
    else
      left = "Goal reached!"
    end
    puts "#{compute_date}: Missing: #{left}"
    left
  end
  
  def compute_date
    Time.now.utc.to_s
  end
  
  def number_to_s(number)
    parts = number.to_s.split('.')
    parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1,")
    parts.join('.')
    parts[0]
  end
  
  def new_json
          
    @speed = compute_speed
    left = compute_left
    
    speed = number_to_s(@speed) + " EUR/h"
     
    json = { "speed" => speed,
              "left" => left,
              "date" => compute_date }
              
    pretty_json = JSON.pretty_generate(json)
    puts "#{compute_date}: New JSON: #{json}"
    
    File.open(@data_json, 'w') { |file| file.write(pretty_json) }
    git_push
    puts
  end
  
  def work
    ten_min = 4
    puts "#{compute_date}: Running..."
    puts
    every_ten_min = @timers.every(ten_min) { collect_update }
    loop { @timers.wait }
  end
end

b = Bail.new
b.work
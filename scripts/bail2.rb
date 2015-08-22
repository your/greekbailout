require 'open-uri'
require 'timers'
require 'json'
#require 'ruby-duration'

class Integer
    def pretty_duration
      parse_string = case self
        when 0..3599 then '%MMinutes'
        when 3600..86399 then '%HHours %MM'
        when 86400..604799 then
          d = self / 24 / 3600
          d.to_s + 'Days %HH'
        else
          d = self / 24 / 3600
          d.to_s + 'Days'
      end
      Time.at(self).utc.strftime(parse_string)
    end
end

class Bail
  def initialize
    @stack = []
    @last_hour = []
    @doc = nil
    @page = "https://www.indiegogo.com/private_api/campaigns/1343420/funds.json"
    @ua = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.130 Safari/537.36"
    @speed = 0
    @goal = 1000000
    @sofar = 0
    @data_json = "res/data.json"
    @data_bank = "res/data.txt"
    @graph_json = "res/graph.json"
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
    @last_hour.shift if @last_hour.size >= 2
    if download
      new_reading = read_funds
      @last_hour.push(new_reading)
      save = compute_date
      save << " - "
      save << @sofar.to_s
      save << "\n"
      File.open(@data_bank, 'a') { |file| file.write(save); }
      if @last_hour.size >= 2
        new_json
        new_graph
        git_push
      end
    end
    puts
  end
  
  def compute_speed
    hourly_speed = 0
    # are we really moving?
    if @last_hour.size > 1
      # compute the speed relative to the number of samples gathered
      relative_speed = (@last_hour.last - @last_hour.first) / @last_hour.size # (each 10 minutes speed)
      # compute the ratio only if needed
      hourly_speed = @last_hour.size < 2 ? relative_speed * 2 : relative_speed
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
          secs_left = (missing_funds / @speed * 3600).ceil.to_i
          left = secs_left.pretty_duration
          #hours_left = (missing_funds / @speed).ceil.to_i
          #if hours_left < 24
            #left = Duration.new(:hours => hours_left).format("%h%~h")
            #else
            #left = Duration.new(:hours => hours_left).format("%d%~d %hh")
            #end
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
    puts
  end
  
  def deliver(date, sum, count, last)
    if count != 0
      date = date
      value = sum / count * 2 * 24 # daily reached
      @stack.push([ date, value ])
      puts "processato giorno #{date} con #{count} elementi per un tot di #{sum} e media di #{value}"
      p @stack
    end
    if last
      whole = [] 
      @stack.each { |el|
        json = {
          "date" => el[0],
          "value" => el[1],
          "type" => "wt"
        }
        whole.push(json) 
      }
              
      pretty_json = JSON.pretty_generate(whole)
      puts "New JSON: #{whole}"
    
      File.open(@graph_json, 'w') { |file| file.write(pretty_json) }
      @stack = []
    end
  end


  def new_graph
    my_array = IO.readlines(@data_bank)

    last_date = 0
    last_sum = 0
    last_count = 0

    my_array.each_with_index { |new_el, i|
  
      new_el = new_el.split(" ")
  
      # read new date
      new_date = new_el[0]
  
      # deliver and reset on data change
      if new_date != last_date
        deliver(last_date, last_sum, last_count, false)
        last_count = 0
        last_sum = 0
      end
  
      # deliver last day
      if (i == my_array.size - 1)
        deliver(last_date, last_sum, last_count, true)
      else
        # simply increment, not deliver yet
        last_date = new_date
        last_count += 1
        last_sum += my_array[i+1].split(" ")[4].to_i - new_el[4].to_i
      end 
    }
  end
  
  def work
    half_hr = 60 * 30
    puts "#{compute_date}: Running..."
    puts
    every_half_hr = @timers.every(half_hr) { collect_update }
    loop { @timers.wait }
  end
end

b = Bail.new
b.work

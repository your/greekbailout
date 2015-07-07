@last_interval = 0
@time_unit = 2

readings_short_time = []
readings_long_time = []

def gather_reading
  @last_interval = 0
  last_reading = readings_short_time.last
  last_amount = last_reading[0]
  new_amount = ...
  if new_amount > last_amount
    new_reading = [new_amount, @last_interval]
    readings_short_time.push(new_reading)
    @last_interval = 0
  end
end 

@time_unit = 2
def average_speed(from_array)
  i = 0
  t = 0
  v_avg = 0
  previous_reading = [0, 0]
  readings = from_array.size
  readings.times {
    current_reading = from_array[i]
    x2 = current_reading[0]
    t2 = current_reading[1] * @time_unit + t
    x1 = previous_reading[0]
    t1 = previous_reading[1] * @time_unit + t
    p "--"
    p x2,x1,t2,t1
    p 
    t = t2
    v = (x2 - x1) / (t2 - t1)
    v_avg += v
    previous_reading = current_reading
    i += 1
    p v
  }
  v_avg = v_avg / readings if readings > 0
  v_avg
end

def compute_speed
  v_short = 0
  

  v_avg_short = average_speed(readings_short_time)
  v_short
  
  v_long = 
end

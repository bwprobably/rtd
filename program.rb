require 'protobuf'
require 'google/transit/gtfs-realtime.pb'
require 'net/http'
require 'uri'
require 'awesome_print'
require 'yaml'
require "./schedule"
require "./live_data"

schedule = Schedule.new
live_data = Live_Data.new

def time_to_str(time)
  time = time.split(':')
  hours = time[0].to_i
  min = time[1]
  am_pm = 'AM'

  if(hours > 12)
    am_pm = 'PM'
    hours -= 12
  end

  return "#{hours}:#{min}#{am_pm}"

end

def print_vehicle_info(v, count)
  v.each{
      |p|



    if count == 2 #time
      printf "%-4s ", time_to_str(p)
    elsif count == 0 #trip_id
      # printf "(%-4s) ", p
    else
      printf "%-4s ", p
    end
    count += 1
  }
end

# load settings
fullPath = "./"
settings = YAML.load_file(fullPath+'settings.yml')
$favorite_routes = settings['favorites'].split(',')

prior_time = ''
settings['morning'].each{|s|

  # parse settings
  from = s[1]['from']
  to = s[1]['to']
  dir = s[1]['direction']
  time = s[1]['time']
  type = s[1]['type']

  # if !time.nil?
  #   time = current_time
  # end

  if time.nil?
    time_after = s[1]['time_after']
    time = prior_time + time_after*60 #time in minutes
    prior_time = time
  else
    prior_time = time
  end






  case dir
    when 'South'
      dir = '1'
    when 'North'
      dir = '0'
    when 'West'
      dir = '1'
    when 'East'
      dir = '0'
  end

  # checking...
  puts "'#{from}' to '#{to}' at ~#{time_to_str(time.strftime("%H:%M"))}"

  # next








  # get stop(s) for starting point
  # this is a really inefficient way to do this
  # I shouldn't be checking all stops, but only stops involved in my trip's destination
  # Little tricky to ask
  stops = schedule.get_stop_info_by_name(from, dir)

  vehicles = []

  stops.each{|s|
    stop_id = s[0]

    # get trips near time
    trips = schedule.get_trips_near_time(stop_id, time, type)

    trips.each{ |t|

      trip_id = t[0]
      arrival_time = t[1]

      trip_info = schedule.get_trip_info(trip_id)
      route_id = trip_info[0]

      if dir == trip_info[4] and $favorite_routes.include?(route_id)

        result = schedule.heading_to_destination?(trip_id, to, dir)

        if !result[0].nil?
          # trip_info = schedule.get_trip_info(trip_id)
          # route_id = trip_info[0]
          day = trip_info[1];

          if day != 'SA' and day != 'SU' and day != 'FR'
            # printf "(#{trip_id}) %-5s %s #{day}\n", route_id, arrival_time[0..-4]
            vehicles.append([trip_id, route_id, arrival_time[0..-4], day])
          end

        end

      end
    }
  }

  vehicles = vehicles.sort_by{|v| v[2]}

  vehicles.each{|v|
    trip_id = v[0]
    count = 0

    if type == 'train' or type == 'bus'
      print_vehicle_info(v, count)
      puts
    end


    if type == 'bus' and !live_data.trip_updates[trip_id].nil?
      v_id = live_data.trip_updates[trip_id][0]['vehicle']['label']
      time_stamp = live_data.trip_updates[trip_id][0]['vehicle']['timestamp']

      count = live_data.vehicle_updates[trip_id][0]['trip_update']['stop_time_update'].size
      sequence = live_data.vehicle_updates[trip_id][0]['trip_update']['stop_time_update'][0]['stop_sequence']
      last_sequnce = live_data.vehicle_updates[trip_id][0]['trip_update']['stop_time_update'][count-1]['stop_sequence']


      stop_id = live_data.vehicle_updates[trip_id][0]['trip_update']['stop_time_update'][0]['stop_id']
      stop_info = schedule.get_stop_info_by_id(stop_id)
      stop_name = stop_info[1]

      if stop_name.include?(to)
        next
        # puts "\n    PAST STOP"
      end


      print_vehicle_info(v, count)


      # v.each{
      #     |p|
      #
      #   if count == 2
      #     printf "%-4s ", p
      #   elsif count == 0
      #     printf "(%-4s) ", p
      #   else
      #     printf "%-4s ", p
      #   end
      #   count += 1
      # }
      print "\n    LIVE: #{Time.at(time_stamp).strftime("%l:%M%p")} "
      print "(#{sequence}/#{last_sequnce}) "
      print stop_name

      if stop_name.include?(from)
        print "\n    CURRENTLY AT STOP"
      end
      puts








    end



    # exit
    # puts
  }

  puts
}









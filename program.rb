require 'protobuf'
require 'google/transit/gtfs-realtime.pb'
require 'net/http'
require 'uri'
require 'awesome_print'
require 'yaml'
require "./schedule"
require "./live_data"
require "./settings"

# convert time to readable format
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

# print vehicle information
def print_vehicle_info(v)
  count = 0
  v.each{ |p|
    if count == 2 #time
      printf "%-4s ", time_to_str(p)
    # elsif count == 0 #trip_id
    #   # printf "(%-4s) ", p
    #   printf ""
    elsif count != 0
      printf "%-4s ", p
    end
    count += 1
  }
end

schedule = Schedule.new
live_data = Live_Data.new
settings = Settings.new

prior_time = ''
settings.list['morning'].each{|s|
  setting = settings.parse_setting(s, prior_time)
  prior_time = setting.time

  # checking...
  puts "'#{setting.from}' to '#{setting.to}' at ~#{time_to_str(setting.time.strftime("%H:%M"))}"

  # get stop(s) for starting point
  # this is a really inefficient way to do this
  # I shouldn't be checking all stops, but only stops involved in my trip's destination
  # Little tricky to ask
  stops = schedule.get_stop_info_by_name(setting.from, setting.dir)

  vehicles = []

  stops.each{|s|
    stop_id = s[0]

    # get trips near time
    trips = schedule.get_trips_near_time(stop_id, setting.time, setting.type)

    # for each tri[]
    trips.each{ |t|

      # get trip info
      trip_id = t[0]
      arrival_time = t[1]
      trip_info = schedule.get_trip_info(trip_id)
      route_id = trip_info[0]

      # if going the direction we're going and the route includes a favorited stop
      if setting.dir == trip_info[4] and settings.favorites.include?(route_id)

        # check if actually heading to destination
        result = schedule.heading_to_destination?(trip_id, setting.to, setting.dir)

        # trip is scheduled to our destination
        if !result[0].nil?
          day = trip_info[1];

          # add to vehicles found
          if day != 'SA' and day != 'SU' and day != 'FR'
            vehicles.append([trip_id, route_id, arrival_time[0..-4], day])
          end
        end
      end
    }
  }

  # sort vehicles sort by arrival time
  vehicles = vehicles.sort_by{|v| v[2]}

  # loop each vehcile
  vehicles.each{|v|
    trip_id = v[0]

    # print information
    if setting.type == 'train'
      print_vehicle_info(v)
      puts
    end

    # if bus has live data, append live data
    if setting.type == 'bus' and !live_data.trip_updates[trip_id].nil?
      v_id = live_data.trip_updates[trip_id][0]['vehicle']['label']
      time_stamp = live_data.trip_updates[trip_id][0]['vehicle']['timestamp']

      count = live_data.vehicle_updates[trip_id][0]['trip_update']['stop_time_update'].size
      sequence = live_data.vehicle_updates[trip_id][0]['trip_update']['stop_time_update'][0]['stop_sequence']
      last_sequence = live_data.vehicle_updates[trip_id][0]['trip_update']['stop_time_update'][count-1]['stop_sequence']

      stop_id = live_data.vehicle_updates[trip_id][0]['trip_update']['stop_time_update'][0]['stop_id']
      stop_info = schedule.get_stop_info_by_id(stop_id)
      stop_name = stop_info[1]

      # skip if live bus data has passed our destination
      if stop_name.include?(setting.to)
        next
        # puts "\n    PAST STOP"
      end

      print_vehicle_info(v)

      # live data found, print
      print "\n    LIVE: #{Time.at(time_stamp).strftime("%l:%M%p")} "
      print "(#{sequence}/#{last_sequence}) "
      print stop_name

      # bus is at stop
      if stop_name.include?(setting.from)
        print "\n    CURRENTLY AT STOP"
      end
      puts
    elsif setting.type == 'bus'
      print_vehicle_info(v)
      puts
    end
  }
  puts "\n"
}
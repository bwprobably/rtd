require 'protobuf'
require 'google/transit/gtfs-realtime.pb'
require 'net/http'
require 'uri'
require 'awesome_print'
require 'yaml'
require "./schedule"

schedule = Schedule.new

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

# get trip update if existing for vehicle
#   from live vehicle and trips
def get_updates(v, trips)
  vehicle_id = v.vehicle.vehicle.id
  route_id = v.vehicle.trip.route_id
  trip_id = v.vehicle.trip.trip_id

  trips[route_id].each { |t|
    if !t.trip_update.nil? && t.trip_update.vehicle && t.trip_update.vehicle.id == vehicle_id
      trip_count = 0

      t.trip_update.stop_time_update.each{|u|
        stop_id = u.stop_id
        puts "   Stop: #{schedule.get_stop_info_by_name(stop_id, "")[1]}"
        puts "     Arrival: #{Time.at(u.arrival.time).strftime("%l:%M%p %m-%e-%y ")}"
        trip_count += 1

        if trip_count >= 2
          break
        end
      }
    end
  }
end

$trip_live_data = ''
$trip_live_data_updates = ''

# parse live data into dictionaries
def parse_live_data()
  vehicleFile = 'realtime/VehiclePosition.pb'
  tripFile = 'realtime/TripUpdate.pb'

  # parse vehicle positioning
  $trip_live_data = Hash.new
  data = File.open(vehicleFile, 'rb') { |io| io.read }
  feed = Transit_realtime::FeedMessage.decode(data)
  for e in feed.entity do
    if defined?(e.vehicle.trip.trip_id)
      trip_id = e.vehicle.trip.trip_id
      if !$trip_live_data.has_key?(trip_id)
        $trip_live_data[trip_id] = []
      end
      $trip_live_data[trip_id].append(e)
    end

    # ap $trip_live_data
    # exit
  end

  # parse trip updates
  $trip_live_data_updates = Hash.new
  data = File.open(tripFile, 'rb') { |io| io.read }
  feed = Transit_realtime::FeedMessage.decode(data)
  for e in feed.entity do
    if defined?(e.trip_update.trip.trip_id)
      trip_id = e.trip_update.trip.trip_id
      if !$trip_live_data_updates.has_key?(trip_id)
        $trip_live_data_updates[trip_id] = []
      end
      $trip_live_data_updates[trip_id].append(e)
    end
  end



  # search_route = 'FF3'
  # if $trip_live_data.keys.include?(search_route) && trip_updates.keys.include?(search_route)
  #   puts "Found #{search_route}: Vehicles: #{$trip_live_data[search_route].count}, Trips: #{$trip_live_data_updates[search_route].count}"
  #   count = 0
  #   $trip_live_data[search_route].each { |v|
  #     stop_id = v.vehicle.stop_id
  #     print "[#{count}] "
  #     puts "vehicle id: #{v.id} (#{v.vehicle.vehicle.id})"
  #     puts "   trip_id: #{v.vehicle.trip.trip_id}"
  #     # puts "   direction_id: #{v.vehicle.trip.direction_id}"
  #     #puts "   Stop: #{schedule.get_stop_info_by_name(stop_id)[1]}"
  #     puts "   gps: #{v.vehicle.position.latitude},#{v.vehicle.position.longitude}"
  #     puts "   status: #{v.vehicle.current_status}"
  #     get_updates(v, $trip_live_data_updates)
  #     count += 1
  #   }
  # end
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

parse_live_data()


# current_time = Time.now



prior_time = ''
settings['evening'].each{|s|

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

    if type == 'bus' and !$trip_live_data[trip_id].nil?
      v_id = $trip_live_data[trip_id][0]['vehicle']['label']
      time_stamp = $trip_live_data[trip_id][0]['vehicle']['timestamp']

      count = $trip_live_data_updates[trip_id][0]['trip_update']['stop_time_update'].size
      sequence = $trip_live_data_updates[trip_id][0]['trip_update']['stop_time_update'][0]['stop_sequence']
      last_sequnce = $trip_live_data_updates[trip_id][0]['trip_update']['stop_time_update'][count-1]['stop_sequence']


      stop_id = $trip_live_data_updates[trip_id][0]['trip_update']['stop_time_update'][0]['stop_id']
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









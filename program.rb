require 'protobuf'
require 'google/transit/gtfs-realtime.pb'
require 'net/http'
require 'uri'
require 'ap'
require "sqlite3"
require 'yaml'

$db = SQLite3::Database.open 'schedule.db'

# get stop info from scheduling data
#   from stop_id
def get_stop_info(stop_id)
  return $db.execute("select * from stops where stop_id = #{stop_id}")[0]
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
        puts "   Stop: #{get_stop_info(stop_id)[1]}"
        puts "     Arrival: #{Time.at(u.arrival.time).strftime("%l:%M%p %m-%e-%y ")}"
        trip_count += 1

        if trip_count >= 2
          break
        end
      }
    end
  }
end

# parse live data into dictionaries
def parse_live_data()
  vehicleFile = 'realtime/VehiclePosition.pb'
  tripFile = 'realtime/TripUpdate.pb'

  # parse vehicle positioning
  vehicles = Hash.new
  data = File.read(vehicleFile)
  feed = Transit_realtime::FeedMessage.decode(data)
  for e in feed.entity do
    if defined?(e.vehicle.trip.route_id)
      route_id = e.vehicle.trip.route_id
      if !vehicles.has_key?(route_id)
        vehicles[route_id] = []
      end
      vehicles[route_id].append(e)
    end
  end

  # parse trip updates
  trip_updates = Hash.new
  data = File.read(tripFile)
  feed = Transit_realtime::FeedMessage.decode(data)
  for e in feed.entity do
    if defined?(e.trip_update.trip.route_id)
      route_id = e.trip_update.trip.route_id
      if !trip_updates.has_key?(route_id)
        trip_updates[route_id] = []
      end
      trip_updates[route_id].append(e)
    end
  end


  search_route = 'FF3'
  if vehicles.keys.include?(search_route) && trip_updates.keys.include?(search_route)
    puts "Found #{search_route}: Vehicles: #{vehicles[search_route].count}, Trips: #{trip_updates[search_route].count}"
    count = 0
    vehicles[search_route].each { |v|
      stop_id = v.vehicle.stop_id
      print "[#{count}] "
      puts "vehicle id: #{v.id} (#{v.vehicle.vehicle.id})"
      puts "   trip_id: #{v.vehicle.trip.trip_id}"
      # puts "   direction_id: #{v.vehicle.trip.direction_id}"
      #puts "   Stop: #{get_stop_info(stop_id)[1]}"
      puts "   gps: #{v.vehicle.position.latitude},#{v.vehicle.position.longitude}"
      puts "   status: #{v.vehicle.current_status}"
      get_updates(v, trip_updates)
      count += 1
    }
  end
end

# get stop info
#   like name and direction
def get_stop_info(name, direction)
  sql = "select stop_id from stops where stop_name like '%#{name}%' and stop_desc like '%#{direction}%' "
  return $db.execute(sql)
end

# get trips at stop_id near time
#   buffer before/after a few minutes
def get_trips_near_time(stop_id, time)
  time = Time.at(time)
  buffer = 600
  earlyTimeBuffer = (time-buffer).strftime("%H:%M:%S")
  lateTimeBuffer = (time+buffer).strftime("%H:%M:%S")

  sql = "select trip_id, arrival_time from stop_times where stop_id = '#{stop_id}' "
  sql += "and arrival_time >= '#{earlyTimeBuffer}' and arrival_time <= '#{lateTimeBuffer}'"
  sql += " order by arrival_time"
  return $db.execute(sql)

end

# get trip info
#   from trip_id
def get_trip_info(trip_id)
  sql = "select * from trips where trip_id = #{trip_id}"
  return $db.execute(sql)[0]
end

# check if trip is heading to destination
# NEEDS IMPROVEMENT. STOP MAY NOT BE HEADSIGN BUT MID-STEP during trip
#   must check all stops not just final stop
def heading_to_destination?(trip_id, destination)
  sql = "select trip_headsign from trips where trip_id = #{trip_id}"
  sql += " and service_id = 'WK'"
  result = $db.execute(sql)

  if result[0].nil?
    return false
  end

  return result[0][0].include?(destination) #cleanup
end

# load settings
fullPath = "./"
settings = YAML.load_file(fullPath+'settings.yml')

settings['morning'].each{|s|
  # parse settings
  from = s[1]['from']
  to = s[1]['to']
  dir = s[1]['direction']
  time = s[1]['time']

  # checking...
  puts "'#{from}' to '#{to}' at ~#{time.strftime("%H:%M")}"

  # get stop(s) for starting point
  stops = get_stop_info(from, dir)

  stops.each{|s|
    stop_id = s[0]

    # get trips near time
    trips = get_trips_near_time(stop_id, time)
    trips.each{ |t|
      trip_id = t[0]
      arrival_time = t[1]

      # pay attention to trips heading to destination
      if heading_to_destination?(trip_id, to) #or true
        info = get_trip_info(trip_id)
        route_id = info[0]
        printf "%-5s %s\n", route_id, arrival_time[0..-4]
      end
    }
  }
  puts
}









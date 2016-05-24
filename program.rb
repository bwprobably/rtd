require 'protobuf'
require 'google/transit/gtfs-realtime.pb'
require 'net/http'
require 'uri'
require 'ap'
require "sqlite3"

$db = SQLite3::Database.open 'schedule.db'

# get stop info from scheduling data
def get_stop_info(stop_id)
  return $db.execute("select * from stops where stop_id = #{stop_id}")[0]
end

# get trip update if existing for vehicle
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














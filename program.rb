require 'protobuf'
require 'google/transit/gtfs-realtime.pb'
require 'net/http'
require 'uri'
require 'ap'
require "sqlite3"

$db = SQLite3::Database.open 'schedule.db'



# trips = "select trips.trip_id from routes
# 	inner join trips on trips.route_id = routes.route_id
# 	where routes.route_id = 'FF3'
# 	and (trips.service_id = 'MT' or trips.service_id = 'FR' or trips.service_id = 'WK')
# 	order by trips.trip_id;"
# trips = db.execute(trips)

def stop_info(stop_id)
  return $db.execute("select * from stops where stop_id = #{stop_id}")[0]
end

vehicleFile = 'realtime/VehiclePosition.pb'
tripFile = 'realtime/TripUpdate.pb'

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

# ap vehicles.keys.sort_by(&:downcase)

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
    puts "   Stop: #{stop_info(stop_id)[1]}"
    puts "   gps: #{v.vehicle.position.latitude},#{v.vehicle.position.longitude}"
    puts "   status: #{v.vehicle.current_status}"
    count += 1
    exit
  }
end














require 'protobuf'
require 'google/transit/gtfs-realtime.pb'
require 'net/http'
require 'uri'
require 'ap'
require "sqlite3"

db = SQLite3::Database.open 'schedule.db'

# trips = "select trips.trip_id from routes
# 	inner join trips on trips.route_id = routes.route_id
# 	where routes.route_id = 'FF3'
# 	and (trips.service_id = 'MT' or trips.service_id = 'FR' or trips.service_id = 'WK')
# 	order by trips.trip_id;"
# trips = db.execute(trips)

def stop_info(stop_id, db)
  return db.execute("select * from stops where stop_id = #{stop_id}")
end

routes = Hash.new
data = File.read('realtime/VehiclePosition.pb')
feed = Transit_realtime::FeedMessage.decode(data)
for e in feed.entity do
  if !defined?(e.vehicle.trip.route_id).nil?
    route_id = e.vehicle.trip.route_id
    if routes.has_key?(route_id)
      routes[route_id].append(e)
    else
      routes[route_id] = []
      routes[route_id].append(e)
    end
  end
end

updates = Hash.new
data = File.read('realtime/TripUpdate.pb')
feed = Transit_realtime::FeedMessage.decode(data)
for e in feed.entity do
  updates[e.trip_update.trip.trip_id] = e
end

route_id = '92'
routes[route_id].select{|r| r.vehicle.trip.direction_id = 0}.each do |r|
  trip_id = r.vehicle.trip.trip_id
  puts "route_id:\t#{route_id}"
  puts "trip_id:\t#{trip_id}"
  if !updates[trip_id].nil?
    vehicle_id = r.vehicle.vehicle.id
    stop_id = updates[trip_id].trip_update.stop_time_update[0].stop_id
    arrival = Time.at(updates[trip_id].trip_update.stop_time_update[0].arrival.time)
    stop_info = stop_info(stop_id, db)

    puts "vehicle_id:\t#{vehicle_id}"
    puts "stop:\t\t#{stop_info[0][1]}"
    puts "arrival:\t#{arrival.strftime("%m-%e-%y %l:%M%p")}"
    puts '~~~~~~~~~~~~~~~~~~~~~~'
  end
end


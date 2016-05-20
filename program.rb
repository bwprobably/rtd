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

routes = Hash.new
data = File.read('realtime/VehiclePosition.pb')
feed = Transit_realtime::FeedMessage.decode(data)
for e in feed.entity do
  if !defined?(e.vehicle.trip.route_id).nil?
    route_id = e.vehicle.trip.route_id
    if routes.has_key?(route_id)
      routes[route_id].append(e.vehicle.trip)
    else
      routes[route_id] = []
      routes[route_id].append(e.vehicle.trip)
    end
  end

end

routes['FF1'].select{|trip| trip.direction_id = 0}.each do |trip|
  puts trip.trip_id
end


# data = File.read('realtime2/TripUpdate.pb')
# feed = Transit_realtime::FeedMessage.decode(data)
#
# routes = Hash.new
# for e in feed.entity do
#   route_id = e.trip_update.trip.route_id
#
#   if routes.has_key?(route_id)
# 		routes[route_id] += 1
# 	else
#     routes[route_id] = 1
#   end
#
#
#
#   #
#   # if route_id == '101'
#   #   trip_id = e.trip_update.trip.trip_id
# 		# print 'route_id: ', route_id, "\n"
#   #   print 'trip_id: ', trip_id, "\n"
# 		# stop_id = e.trip_update.stop_time_update[0].stop_id
#   #   arrival = Time.at(e.trip_update.stop_time_update[0].arrival.time)
#   #   print 'stop_id: ', stop_id, "\n"
# 		# print 'arrival: ', arrival, "\n"
#   #   break
#   # end
# end
# ap routes
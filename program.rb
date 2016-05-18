require 'protobuf'
require 'google/transit/gtfs-realtime.pb'
require 'net/http'
require 'uri'
require 'ap'

def print_separator
	puts '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
end

def find_in_data (data, search_string, contains=true)
	lines = []

	data.each_line do |line|
		if contains && line.include?(search_string)
			lines.push(line)
		elsif line.start_with?(search_string)
			lines.push(line)
		end
	end
	return lines
end

class DynamicDataList
	attr_accessor :list
	def initialize(data, schema)
		@list = []
		schema = schema.delete!("\r\n")
		data.each do |route|		
			route = route.split(',')	
			hash = Hash.new
			count = 0
			schema.split(',').each do |property|
				hash[property] = route[count]
				count += 1
			end
			@list.append(hash)	
		end
	end
	def to_s
		ap @list
	end
end

search_route = 'FF3'
search_stop = 'US 36 & Sheridan Station Gate C'
search_destination = 'Union Station'

# find route information
data = File.read('schedule/routes.txt')
route_data = find_in_data(data, search_route, false)
routes = DynamicDataList.new(route_data, data.lines.first)
ap routes.list

# find stop information
data = File.read('schedule/stops.txt')
stop_data = find_in_data(data, search_stop)
stops = DynamicDataList.new(stop_data, data.lines.first)
ap stops.list

# find trip information to destination
data = File.read('schedule/trips.txt')
trip_data = find_in_data(data, search_route)
trips = DynamicDataList.new(trip_data, data.lines.first)
trips.list.delete_if do |trip|
	if trip['trip_headsign'] != search_destination
		true
	end
end

trip_ids = [] 
trips.list.each{ |t| trip_ids.push(t['trip_id'])}

# find stop_time information
data = File.read('schedule/stop_times.txt')
stop_time_data = find_in_data(data, trip_ids.first, false)
stop_times = DynamicDataList.new(stop_time_data, data.lines.first)

print 'trip_id: ', trip_ids.first, "\n"
stop_times.list.each{|s| 
	print 'stop_id: ', s['stop_id'], "\n  "
	print s['arrival_time'], '-', s['departure_time'], "\n" 
}
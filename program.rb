require 'protobuf'
require 'google/transit/gtfs-realtime.pb'
require 'net/http'
require 'uri'
require 'ap'

#id = 0
#
#data = File.read('VehiclePosition.pb')
#feed = Transit_realtime::FeedMessage.decode(data)
#for e in feed.entity do
#	#ap e
#	print 'id: '
#	puts e.vehicle.vehicle.id
#	puts Time.at(e.vehicle.timestamp).strftime("%I:%M %p")
#	ap e.id
#	ap e.vehicle.position
#	id = e.id 
#	break
#end
#
#data = File.read('TripUpdate.pb')
#feed = Transit_realtime::FeedMessage.decode(data)
#for entity in feed.entity do
#	if entity.id = id
#		print 'trip: '
#		ap entity.trip_update.trip.trip_id
#		entity.trip_update.stop_time_update.each do |trip|
#			print 'stop_id: '
#			print trip.stop_id
#			print ' arrival: '
#			print Time.at(trip.arrival.time).strftime("%I:%M %p")
#			print ' departure: '
#			puts Time.at(trip.departure.time).strftime("%I:%M %p")
#			
#		end
#		
#		break
#	end
#end

puts '~~~~~~~~'
require 'protobuf'
require 'google/transit/gtfs-realtime.pb'
require 'net/http'
require 'uri'

data = File.read("TripUpdate.pb")
feed = Transit_realtime::FeedMessage.decode(data)
for entity in feed.entity do
  if entity.field?(:trip_update)
    p entity.inspect
	abort
  end
end
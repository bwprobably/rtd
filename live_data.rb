class Live_Data
  
  attr_accessor :trip_updates, :vehicle_updates, :vehicle_file, :trip_file
  
  # parse live data into dictionaries
  def initialize
    @vehicle_file = 'realtime/VehiclePosition.pb'
    @trip_file = 'realtime/TripUpdate.pb'

    download_data

    # parse vehicle positioning

    @trip_updates = Hash.new
    data = File.open(@vehicle_file, 'rb') { |io| io.read }
    feed = Transit_realtime::FeedMessage.decode(data)
    for e in feed.entity do
      if defined?(e.vehicle.trip.trip_id)
        trip_id = e.vehicle.trip.trip_id
        if !@trip_updates.has_key?(trip_id)
          @trip_updates[trip_id] = []
        end
        @trip_updates[trip_id].append(e)
      end

      # ap @trip_updates
      # exit
    end

    # parse trip updates
    @vehicle_updates = Hash.new
    data = File.open(@trip_file, 'rb') { |io| io.read }
    feed = Transit_realtime::FeedMessage.decode(data)
    for e in feed.entity do
      if defined?(e.trip_update.trip.trip_id)
        trip_id = e.trip_update.trip.trip_id
        if !@vehicle_updates.has_key?(trip_id)
          @vehicle_updates[trip_id] = []
        end
        @vehicle_updates[trip_id].append(e)
      end
    end
  end

  def download_data

    # delete *.pb in directory

    # authenticate credentials to google_sync

    # download VehiclePosition.pb
    # download TripUpdate.pb

    puts '(skip download of live data)'

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
end
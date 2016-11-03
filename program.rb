#!/usr/bin/env ruby
require 'protobuf'
require 'google/transit/gtfs-realtime.pb'
require 'net/http'
require 'uri'
require 'awesome_print'
require 'yaml'
require "./schedule"
require "./live_data"
require "./settings"

# convert time to readable format
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

# print vehicle information
def print_vehicle_info(v)
  count = 0
  v.each{ |p|
    if count == 2 #time
      printf "%-4s ", time_to_str(p)
    # elsif count == 0 #trip_id
    #   # printf "(%-4s) ", p
    #   printf ""
    elsif count != 0 and count != 3
      printf "%-4s ", p
    end
    count += 1
  }
end

def print_trip_info(from, to, time, dir, type, schedule, live_data, favorites)
  # checking...
  puts "'#{from}' to '#{to}' at ~#{time_to_str(time.strftime("%H:%M"))}"

  # get stop(s) for starting point
  # this is a really inefficient way to do this
  # I shouldn't be checking all stops, but only stops involved in my trip's destination
  # Little tricky to ask
  stops = schedule.get_stop_info_by_name(from, dir)

  vehicles = []

  # until I figure out why the fuck I'm getting duplicates (on same day)
  #   I'm skipping every other match. The 2nd hit matches with live data.
  #   would be nice to remove this for performance ~C 
  skip_add_every_other = true

  stops.each{|s|
    stop_id = s[0]

    # get trips near time
    trips = schedule.get_trips_near_time(stop_id, time, type)

    # for each tri[]
    trips.each{ |t|

      # get trip info
      trip_id = t[0]
      arrival_time = t[1]
      
      trip_info = schedule.get_trip_info(trip_id)
      
      if !trip_info.nil?
        route_id = trip_info[1]
        
        # if going the direction we're going and the route includes a favorited stop
        if (dir.nil? or dir == trip_info[2]) and (favorites.nil? or favorites.include?(route_id))

            # check if actually heading to destination
            result = schedule.heading_to_destination?(trip_id, to, dir)

            # trip is scheduled to our destination
            if !result[0].nil?
              day = trip_info[5];
              # add to vehicles found
              if day.start_with?('WK') || day.start_with?('MT') #|| day.start_with?('FR')
                if skip_add_every_other
                  skip_add_every_other = false
                elsif
                  vehicles.append([trip_id, route_id, arrival_time[0..-4], day])
                  skip_add_every_other = true
                end
              end
            end
        end 
      end
    }
  }

  # sort vehicles sort by arrival time
  vehicles = vehicles.sort_by{|v| v[2]}

  count = 1

  # loop each vehicle
  vehicles.each{|v|
    trip_id = v[0]

    print "(#{count}) "
    count += 1

    # print information
    # currently trains do not have live data
    if type == 'train'
      print_vehicle_info(v)
      puts
    end

    # if bus has live data, append live data
    if type == 'bus' and !live_data.vehicle_updates.nil? and !live_data.trip_updates.nil?  and !live_data.trip_updates[trip_id].nil?
      v_id = live_data.trip_updates[trip_id][0]['vehicle']['label']
      time_stamp = live_data.trip_updates[trip_id][0]['vehicle']['timestamp']

      size = live_data.vehicle_updates[trip_id][0]['trip_update']['stop_time_update'].size
      sequence = live_data.vehicle_updates[trip_id][0]['trip_update']['stop_time_update'][0]['stop_sequence']
      last_sequence = live_data.vehicle_updates[trip_id][0]['trip_update']['stop_time_update'][size-1]['stop_sequence']

      stop_id = live_data.vehicle_updates[trip_id][0]['trip_update']['stop_time_update'][0]['stop_id']
      stop_info = schedule.get_stop_info_by_id(stop_id)
      stop_name = stop_info[8]

      # skip if live bus data has passed our destination
      if stop_name.include?(to)
        next
        # puts "\n    PAST STOP"
      end

      print_vehicle_info(v)

      if dir.nil?
        # unknown direction
      end


      # bus is at stop
      if stop_name.include?(from)
        print "AT STOP NOW"
      else
        # live data found, print
        print "\LIVE: #{Time.at(time_stamp).strftime("%l:%M%p")} "
        print "(#{sequence}/#{last_sequence}) "
        print stop_name
      end


      puts
    elsif type == 'bus'
      print_vehicle_info(v)
      puts
    end
  }
  puts "\n"
end

schedule = Schedule.new
settings = Settings.new
live_data = Live_Data.new(settings.list['api']['user'], settings.list['api']['password'])

# use current time by default
use_current_time = true

# use morning or evening trip based on time of day
set_trip = 'work'
if Time.now.strftime("%H").to_i > 12
  set_trip = 'home'
end

override_time = false
override_time_value = ''

if ARGV.count() == 1
  # specify saved route
  set_trip = ARGV[0]
elsif ARGV.count() == 2
  # specify saved route and time
  set_trip = ARGV[0]

  begin
    override_time = true
    override_time_value = Time.parse(ARGV[1])
  rescue
    override_time = false
  end

  if not override_time
    from = ARGV[0]
    to = ARGV[1]

    print_trip_info(from, to, Time.now, nil, 'bus', schedule, live_data, nil)
    exit
  end

end

# first stop in trip uses current time
#   subsequent stops use time_after setting
first = true
prior_time = ''

if settings.list[set_trip].nil?
  puts 'Saved route not found.'
  exit
end

# for each stop in trip setting
settings.list[set_trip].each{|s|

  setting = settings.parse_setting(s, prior_time)
  prior_time = setting.time

  if override_time and first
    first = false
    setting.time = override_time_value
    prior_time = setting.time
  elsif (first and use_current_time) or setting.time.nil?
    first = false
    setting.time = Time.now
    prior_time = setting.time
  end

  print_trip_info(setting.from, setting.to, setting.time, setting.dir, setting.type, schedule, live_data, settings.list['favorites'])
}

# remove live data for next run
live_data.delete_live_data
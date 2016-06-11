require 'sqlite3'
require 'fileutils'

class Schedule

  # load database from file
  def initialize
    sql_file = '/home/christopher/rtd/schedule.db'
    sql_ram = '/mnt/ramdisk/schedule.db'
    
    if !File.exists?(sql_ram) and File.exists?(sql_file)
      FileUtils.cp(sql_file, sql_ram)
    elsif !File.exists?(sql_file)
      puts 'Cannot find scheduling data'
      exit
    end

    @db = SQLite3::Database.open sql_ram
    @buffer_bus = 400
    @buffer_train = 1000
  end

  # get stop info from scheduling data
  #   from stop_id
  def get_stop_info_by_id(stop_id)
    return @db.execute("select * from stops where stop_id = #{stop_id}")[0]
  end

  # get stop info
  #   like name and direction
  def get_stop_info_by_name(name, direction)
    sql = "select stop_id from stops where stop_name like '%#{name}%'"
    return @db.execute(sql)
  end

  # get trips at stop_id near time
  #   buffer before/after a few minutes
  def get_trips_near_time(stop_id, time, type)
    time = Time.at(time)
    buffer = @buffer_train

    case type
      when 'bus'
        buffer = @buffer_bus
        lateTimeBuffer = (time+buffer*4).strftime("%H:%M:%S")

      when 'train'
        buffer = @buffer_train
        lateTimeBuffer = (time+buffer*2).strftime("%H:%M:%S")
    end

    earlyTimeBuffer = (time-buffer).strftime("%H:%M:%S")

    sql = "select trip_id, arrival_time from stop_times where stop_id = '#{stop_id}' "
    sql += "and arrival_time >= '#{earlyTimeBuffer}' and arrival_time <= '#{lateTimeBuffer}'"
    sql += " order by arrival_time"
    return @db.execute(sql)

  end

  # get trip info
  #   from trip_id
  def get_trip_info(trip_id)
    sql = "select * from trips where trip_id = #{trip_id}"
    return @db.execute(sql)[0]
  end

  # check if trip stops at destination
  #   must check all stops not just final stop
  def heading_to_destination?(trip_id, destination, dir)
    sql = "select * from stop_times INNER JOIN stops on stop_times.stop_id = stops.stop_id";
    sql += " where stop_times.trip_id = '#{trip_id}' and stops.stop_name like '%#{destination}%'";
    result = @db.execute(sql)
    return result
  end


end
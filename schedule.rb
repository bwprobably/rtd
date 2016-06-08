require 'sqlite3'

class Schedule

  db = SQLite3::Database.open 'schedule.db'

  # get stop info from scheduling data
  #   from stop_id
  def get_stop_info_all(stop_id)
    return db.execute("select * from stops where stop_id = #{stop_id}")[0]
  end



end
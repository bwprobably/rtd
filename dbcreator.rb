require "sqlite3"

if File.exist?('schedule.db')
  puts 'database exists, aborting'
  return
end

db = SQLite3::Database.new 'schedule.db'

def create_table(file_name, db)
  # read in file
  data = File.read('schedule/'+file_name)
  file_name = file_name.chomp('.txt')

  puts 'creating table: ' + file_name

  # create table schema from first line of file
  schema = data.lines.first.chomp("\r\n").split(',')
  sql = 'create table '+file_name + '('
  schema.each do |property|
    sql += property
    sql += ' nvarchar(64),'
  end
  sql = sql.chomp(',')+');'
  db.execute sql

  initial = 'insert into '+ file_name + ' values '
  sql = initial
  count = 0
  totalCount = 0

  # insert each row from file into database
  data.lines[1..-1].each do |line|

    sql += '('

    line.chomp("\r\n").split(',').each do |value|
      value.sub! "'", "''"
      sql += "'" + value + "',"
    end

    sql = sql.chomp(',')+'),'
    count += 1

    if count == 5000
      totalCount += count
      puts "inserting: #{count}, total: #{totalCount}"
      sql = sql[0..-2]
      sql += ';'
      db.execute sql
      sql = initial

      count = 0
    end

    #break
  end

  sql = sql[0..-2]
  sql += ';'
  totalCount += count
  puts "inserting: #{count}, total: #{totalCount}"
  db.execute sql

end

Dir.foreach('schedule') do |file|
  next if file == '.' or file == '..' or file == 'schedule.db' or file == 'shapes.txt' #or file != 'routes.txt'
  create_table(file, db)
end



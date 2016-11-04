class Settings

  attr_accessor :favorites, :list

  def initialize
    fullPath = "/home/christopher/repo/rtd/"
    settings = YAML.load_file(fullPath+'settings.yml')
    @favorites = settings['favorites'].split(',')
    @list = settings
  end

  def parse_setting(s, prior_time)
    # parse settings
    from = s[1]['from']
    to = s[1]['to']
    dir = s[1]['direction']
    time = s[1]['time']
    type = s[1]['type']

    if time.nil?
      time_after = s[1]['time_after']
      time = prior_time + time_after*60 #time in minutes
      prior_time = time
    else
      prior_time = time
    end

    case dir
      when 'South'
        dir = '1'
      when 'North'
        dir = '0'
      when 'West'
        dir = '1'
      when 'East'
        dir = '0'
    end

    return Setting.new(to, from, dir, time, type)

  end
end

class Setting
  attr_accessor :to, :from, :dir, :time, :type

  def initialize(to, from, dir, time, type)
    @to = to
    @from = from
    @dir = dir
    @time = time
    @type = type

  end

end

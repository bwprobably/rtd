class Settings

  attr_accessor :favorites

  def initialize
    fullPath = "./"
    settings = YAML.load_file(fullPath+'settings.yml')
    @favorites = settings['favorites'].split(',')

    ap settings
  end
end
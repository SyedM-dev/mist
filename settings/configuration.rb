# Global constants

SCREEN_SIZE = [720, 480].freeze
N, S, W, E = 1, 2, 4, 8

# Config module to hold global settings that can be toggled in the settings scene, and accessed anywhere else in the code via the event bus
module Config
  @config = {
    debug: ARGV.include?("--debug"),
    fog: true,
    torches_lightup: true,
  }
  
  if File.exist?("config.json")
    data = JSON.parse(File.read("config.json"))
    @config.merge!(data.transform_keys(&:to_sym))
  end

  $bus.on(:settings, :master) { |k| @config[k] }

  module_function

  def toggle(key)
    @config[key] = !@config[key]
  end

  def persist!
    File.open("config.json", "w") do |f|
      f.write(JSON.pretty_generate(@config))
    end
  end
end

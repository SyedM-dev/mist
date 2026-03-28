# Global constants

SCREEN_SIZE = [720, 480].freeze
N, S, W, E = 1, 2, 4, 8

# Config module to hold global settings that can be toggled in the settings scene, and accessed anywhere else in the code via the event bus
module Config
  @config = {
    debug: ARGV.include?("--debug"),
    fog: true,
    torches_lightup: false
  }

  $bus.on(:settings) do |k|
    next @config[k]
  end

  module_function

  def toggle(key)
    @config[key] = !@config[key]
  end
end

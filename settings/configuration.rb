# Global constants

SCREEN_SIZE = [720, 480].freeze
N, S, W, E = 1, 2, 4, 8

# Config module to hold global settings that can be toggled in the settings scene, and accessed anywhere else in the code via the event bus
module Config
  @debug = false

  @keybinds = {
    forward: Gosu::KB_W,
    backward: Gosu::KB_S,
    leftward: Gosu::KB_A,
    rightward: Gosu::KB_D,
    break: Gosu::KB_X,
    attack: Gosu::KB_SPACE,
    place: Gosu::KB_P,
    "inventory up": Gosu::KB_UP,
    "inventory down": Gosu::KB_DOWN,
    "inventory right": Gosu::KB_RIGHT,
    "inventory left": Gosu::KB_LEFT,
    craft: Gosu::KB_RETURN,
  }

  if File.exist?("config.json")
    data = JSON.parse(File.read("config.json"))
    @debug = data["debug"] || false
    @keybinds.merge!(data["keybinds"]&.transform_keys(&:to_sym) || {})
  end

  $bus.on(:settings, :master) { |k| k == :debug ? @debug : @keybinds[k] }

  module_function

  def bindings
    @keybinds
  end

  def debug
    @debug
  end

  def debug=(value)
    @debug = value
  end

  def set_key(action, key)
    @keybinds[action] = key
  end

  def persist!
    File.open("config.json", "w") do |f|
      f.write(JSON.pretty_generate({
        keybinds: @keybinds,
        debug: @debug
      }))
    end
  end
end
require 'gosu'

require_relative 'utils/bus'
$bus = EventBus.new

require_relative 'settings/configuration'
require_relative 'utils/utils'
require_relative 'utils/scene'
require_relative 'settings/scene'
require_relative 'menu/scene'
require_relative 'game/scene'

# Main window
class Window < Gosu::Window
  def initialize
    super *SCREEN_SIZE, resizable: true
    self.caption = "Mist"

    @scene = Menu.new
    @last_time = Gosu.milliseconds

    $bus.on(:quit_game) { close! }

    $bus.on(:mouse_pos) do
      next mouse_relative(mouse_x, mouse_y)
    end

    $bus.on(:change_scene) do |new_scene|
      @scene.close
      @scene = new_scene
    end
  end

  def button_down(id)
    @scene.button_down(id, mouse_relative(mouse_x, mouse_y))
  end

  def update
    now = Gosu.milliseconds
    dt = (now - @last_time) / 1000.0
    @last_time = now

    @scene.update(dt)
  end

  def compute_transform
    scale_x = width.to_f / SCREEN_SIZE[0]
    scale_y = height.to_f / SCREEN_SIZE[1]

    scale = [scale_x, scale_y].min

    if scale_x < scale_y
      offset_x = 0
      offset_y = (height - SCREEN_SIZE[1] * scale) / 2
    else
      offset_x = (width - SCREEN_SIZE[0] * scale) / 2
      offset_y = 0
    end

    [scale, offset_x, offset_y]
  end

  def mouse_relative(sx, sy)
    scale, offset_x, offset_y = compute_transform

    virtual_x = (sx - offset_x) / scale
    virtual_y = (sy - offset_y) / scale

    return nil if virtual_x < 0 || virtual_x > SCREEN_SIZE[0] ||
                  virtual_y < 0 || virtual_y > SCREEN_SIZE[1]

    return [virtual_x, virtual_y]
  end

  def draw
    scale, offset_x, offset_y = compute_transform
    
    Gosu.translate(offset_x, offset_y) do
      Gosu.scale(scale) do
        @scene.draw
      end
    end

    padding_color = Gosu::Color::BLACK
    if offset_y > 0
      # Letterbox: top and bottom
      Gosu.draw_rect(0, 0, width, offset_y, padding_color, Float::INFINITY)
      Gosu.draw_rect(0, height - offset_y, width, offset_y, padding_color, Float::INFINITY)
    else
      # Pillarbox: left and right
      Gosu.draw_rect(0, 0, offset_x, height, padding_color, Float::INFINITY)
      Gosu.draw_rect(width - offset_x, 0, offset_x, height, padding_color, Float::INFINITY)
    end
  end
end

Window.new.show
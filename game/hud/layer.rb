require_relative "inventory"
require_relative "health"
require_relative "logs"
require_relative "minimap"

class HUDLayer
  def initialize
    @hud_bg = Gosu::Image.new("assets/images/hud.png", retro: true)
    @hud_fg = Gosu::Image.new("assets/images/hud_fg.png", retro: true)
    @inventory = Inventory.new
    @health = HealthBar.new(100)
    @logs = GameLogger.new
    @minimap = Minimap.new

    @direction_sprite = Gosu::Image.new("assets/images/direction.png", retro: true)

    $bus.on(:enemy_attack) do |damage|
      @health.take_damage(damage)
    end
  end

  def update(dt)
    @logs.update(dt)
  end

  def draw
    @hud_bg.draw(0, 0, Float::INFINITY)

    @inventory.draw
    @health.draw
    @logs.draw

    player_x, player_y = $bus.get(:player_position) || [0, 0]
    tile_x = ((player_x - 90) / 120).round
    tile_y = ((player_y - 90) / 120).round
    center_x = tile_x * 2 + 1
    center_y = tile_y * 2 + 1
    @minimap.draw(center_x, center_y)

    if $bus.get(:radar_triangulation?, player_x, player_y)
      exit_x, exit_y = $bus.get(:exit_room_coords) || [0, 0]
      angle_to_exit = Math.atan2(exit_y - tile_x, exit_x - tile_y) * 180 / Math::PI
      @direction_sprite.draw_rot(SCREEN_SIZE[0] / 2, SCREEN_SIZE[1] / 2, Float::INFINITY, angle_to_exit, 0.5, 0.5, 5, 5)
    end

    @hud_fg.draw(0, 0, Float::INFINITY)
  end

  def button_down(id, pos)
    @inventory.button_down(id, pos)
  end
end
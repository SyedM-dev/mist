require_relative 'maze'
require_relative 'hud/layer'
require_relative 'props/handler'
require_relative 'enemy/handler'
require_relative 'character'

require 'perlin'

class Game < Scene
  def initialize
    super
    @font = Gosu::Font.new(24)
    @noise = Perlin::Generator.new(rand(1...1000), 1.0, 1)
    @floor_image = Gosu::Image.new("assets/images/floor.png", retro: true)

    @maze = Maze.new
    @character = Character.new
    @enemies = EnemyHandler.new
    @props = PropsHandler.new

    @hud = HUDLayer.new

    @camera = [0, 0]

    $bus.on(:player_move) do |pos|
      @camera = pos
    end

    $bus.on(:camera_pos) do
      next @camera
    end
  end

  def draw
    draw_floor
    @maze.draw
    @character.draw
    @enemies.draw
    @props.draw
    draw_fog! if $bus.get(:settings, :fog)
    @hud.draw
    draw_debug! if $bus.get(:settings, :debug)
  end

  def draw_debug!
    @font.draw_text("FPS: #{Gosu.fps}", 5, 5, Float::INFINITY, 1, 1, Gosu::Color::YELLOW)
    world_x, world_y = $bus.get(:player_position)&.map(&:round) || [0, 0]
    @font.draw_text("Player: [#{world_x}, #{world_y}]", 5, 30, Float::INFINITY, 1, 1, Gosu::Color::YELLOW)
  end

  def draw_fog!
    $bus.emit(:shade)
    return

    
  end

  def draw_floor
    cam_x, cam_y = @camera
    tile_size = 60

    offset_x = cam_x % tile_size
    offset_y = cam_y % tile_size

    tiles_x = (SCREEN_SIZE[0] / tile_size) + 2
    tiles_y = (SCREEN_SIZE[1] / tile_size) + 2

    (0...tiles_y).each do |j|
      (0...tiles_x).each do |i|
        sx = i * tile_size - offset_x
        sy = j * tile_size - offset_y
        @floor_image.draw(sx, sy, -Float::INFINITY, 3, 3)
      end
    end
  end

  def update(dt)
    @character.update(dt)
    @enemies.update(dt)
    @props.update(dt)
  end

  def button_down(id, pos)
    return $bus.emit(:change_scene, Menu.new) if id == Gosu::KB_ESCAPE

    return if @hud.button_down(id, pos)
    return if @props.button_down(id, pos)
  end
end
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
    @hud.draw
    draw_fog! if $bus.get(:settings, :fog)
    draw_debug! if $bus.get(:settings, :debug)
  end

  def draw_debug!
    @font.draw_text("FPS: #{Gosu.fps}", 5, 5, Float::INFINITY, 1, 1, Gosu::Color::YELLOW)
    world_x, world_y = $bus.get(:player_position)&.map(&:round) || [0, 0]
    @font.draw_text("Player: [#{world_x}, #{world_y}]", 5, 30, Float::INFINITY, 1, 1, Gosu::Color::YELLOW)
  end

  def draw_fog!
    cam_x, cam_y = @camera
    cell = 10
    p_i_radius = 80.0
    p_o_radius = 350.0
    t_i_radius = 10.0
    o_radius = 160.0

    # Player screen position
    px = SCREEN_SIZE[0] / 2.0
    py = SCREEN_SIZE[1] / 2.0
    
    # Collect torch positions relative to camera
    torch_lights = []
    # Only calculate torch lights if the setting is enabled, to save performance
    if $bus.get(:settings, :torches_lightup)
      torches = $bus.get(:nearby_torches,
      [cam_x - SCREEN_SIZE[0] / 2, cam_y - SCREEN_SIZE[1] / 2, SCREEN_SIZE[0] * 2, SCREEN_SIZE[1] * 2]
      ) || []
      torch_lights = torches.map { |t| [t[0] - cam_x, t[1] - cam_y] }
    end

    tiles_x = (SCREEN_SIZE[0] / cell) + 2
    tiles_y = (SCREEN_SIZE[1] / cell) + 2

    # This part is a shader but due to time constraints, I'm doing it on the CPU.
    # If done on the GPU, we could have much better performance.
    # and also make it more fine-grained and smoother gradients.
    # doing it on the GPU would require better knowledge of the ruby openGL bindings and shader programming,
    # which I don't have right now. 
    
    tiles_y.times do |j|
      tiles_x.times do |i|
        sx = i * cell
        sy = j * cell

        light_strength = 0.0

        d = Math.sqrt((px - sx)**2 + (py - sy)**2)
        if d < p_i_radius
          light_strength = 1.0
        elsif d < p_o_radius
          t = (d - p_i_radius) / (p_o_radius - p_i_radius) # 0..1
          light_strength = 1.0 - t
        end

        torch_lights.each do |lx, ly|
          d = Math.sqrt((sx - lx)**2 + (sy - ly)**2)

          if d < t_i_radius
            strength = 1.0
          elsif d < o_radius
            t = (d - t_i_radius) / (o_radius - t_i_radius) # 0..1
            strength = 1.0 - t
          else
            strength = 0.0
          end

          light_strength += strength
        end

        light_strength = light_strength.clamp(0.0, 1.0)

        t = 1.0 - light_strength

        world_x = (sx + cam_x) * 0.005
        world_y = (sy + cam_y) * 0.005

        noise = (@noise[
          world_x + Gosu.milliseconds / 5000.0,
          world_y + Gosu.milliseconds / 6000.0
        ] + 1.0) / 2.0

        alpha = (t * (1.0 + noise) * 255).to_i.clamp(0, 255)

        Gosu.draw_rect(sx, sy, cell, cell, Gosu::Color.new(alpha, 0, 0, 0), 10000 + sy)
      end
    end
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
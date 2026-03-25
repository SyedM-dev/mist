require_relative 'state'
require_relative 'maze'
require_relative 'character'

require 'perlin'

class Game < Scene
  def initialize
    super
    @font = Gosu::Font.new(24)
    @noise = Perlin::Generator.new(rand(1000), 1.0, 1)
    @floor_image = Gosu::Image.new("assets/images/floor.png", retro: true)

    @maze = Maze.new
    @character = Character.new

    @camera = [0, 0]

    $bus.on(:player_move) do |pos|
      @camera = pos
    end

    $bus.on_retrievable(:collides?) do |rect|
      collisions = []
      collisions << :wall if @maze.collides?(rect)
      collisions << :character if @character.collides?(rect)
      next collisions
    end
  end

  def draw
    draw_floor
    @maze.draw(@camera)
    @character.draw
    draw_fog(@camera)
    draw_debug! if DEBUG
  end

  def draw_debug!
    now = Gosu.milliseconds
    @last_draw_time ||= now
    @draw_count ||= 0
    @fps ||= 0

    @draw_count += 1

    if now - @last_draw_time >= 1000
      @fps = @draw_count
      @draw_count = 0
      @last_draw_time = now
    end

    @font.draw_text("FPS: #{@fps}", 5, 5, Float::INFINITY, 1, 1, Gosu::Color::YELLOW)
    @font.draw_text("Player: [#{@character.world_x.round}, #{@character.world_y.round}]", 5, 30, Float::INFINITY, 1, 1, Gosu::Color::YELLOW)
  end

  def draw_fog(camera)
    cam_x, cam_y = camera
    cell = 10
    i_radius = 90.0
    o_radius = 400.0

    # Player screen position
    px = SCREEN_SIZE[0] / 2.0
    py = SCREEN_SIZE[1] / 2.0

    tiles_x = (SCREEN_SIZE[0] / cell) + 2
    tiles_y = (SCREEN_SIZE[1] / cell) + 2

    tiles_y.times do |j|
      tiles_x.times do |i|
        sx = i * cell
        sy = j * cell

        dist = Math.sqrt((sx - px)**2 + (sy - py)**2)

        if dist < i_radius
          next  # fully clear
        elsif dist > o_radius
          alpha = 255
        else
          t = (dist - i_radius) / (o_radius - i_radius)  # 0..1
          world_x = (sx + cam_x) * 0.005
          world_y = (sy + cam_y) * 0.005
          # Sample noise at world position so it scrolls with camera
          # Add time-based offsets for animation
          noise = (@noise[world_x + Gosu.milliseconds / 5000.0, world_y + Gosu.milliseconds / 6000.0] + 1.0) / 2.0
          alpha = (t * (1.0 + noise) * 255).to_i.clamp(0, 255)
        end

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
        @floor_image.draw(sx, sy, -1000, 3, 3)
      end
    end
  end

  def update
    @character.update
  end

  def button_down(id, _pos)
    return $bus.emit(:change_scene, Menu.new) if id == Gosu::KB_ESCAPE
  end
end
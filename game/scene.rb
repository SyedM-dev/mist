require_relative 'maze'
require_relative 'hud/layer'
require_relative 'props/handler'
require_relative 'enemy/handler'
require_relative 'weapons/handler'
require_relative 'traps/handler'
require_relative 'character'

class Game < Scene
  def initialize
    super
    $is_dead = false

    @font = Gosu::Font.new(24)
    @floor_image = Gosu::Image.new("assets/images/floor.png", retro: true)

    @blasted = 0

    @maze = Maze.new
    @character = Character.new
    @enemies = EnemyHandler.new
    @props = PropsHandler.new
    @weapons = WeaponHandler.new
    @traps = TrapHandler.new

    @hud = HUDLayer.new

    @camera = [0, 0]

    $bus.emit(:log, "Welcome to the Mist! Use WASD to move, SPACE or left-click to attack with your equipped weapon, and ESC to return to the menu.")

    $bus.on(:player_move) do |pos|
      @camera = pos
    end

    $bus.on(:camera_pos) do
      next @camera
    end

    $bus.on(:blast) do |_|
      @blasted = 10 # blast for 10 frames
    end
  end

  def draw
    if @blasted != 0
      # this is a terrible animation for blasting but that would require me to work on artwork and I don't have time for that, so let's just flash the screen white and fade it out
      Gosu.draw_rect(0, 0, *SCREEN_SIZE, Gosu::Color.new(@blasted * 255 / 10, 255, 255, 255), Float::INFINITY)
      @blasted -= 1
      return
    end
    draw_floor
    @maze.draw
    @character.draw
    @enemies.draw
    @props.draw
    @traps.draw
    $bus.emit(:shade) if $bus.get(:settings, :fog)
    @hud.draw
    @weapons.draw
    draw_debug! if $bus.get(:settings, :debug)
  end

  def draw_debug!
    @font.draw_text("FPS: #{Gosu.fps}", 5, 5, Float::INFINITY, 1, 1, Gosu::Color::YELLOW)
    world_x, world_y = $bus.get(:player_position)&.map(&:round) || [0, 0]
    @font.draw_text("Player: [#{world_x}, #{world_y}]", 5, 30, Float::INFINITY, 1, 1, Gosu::Color::YELLOW)
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
    @traps.update(dt)
    @weapons.update(dt)
    @hud.update(dt)
  end

  def button_down(id, pos)
    # Pressing ESC returns to the menu, this is bad but I don't have time to make a proper pause menu,
    # as the game has no persistent state outside of the current scene, just returning to the menu resets everything
    return $bus.emit(:change_scene, Menu.new) if id == Gosu::KB_ESCAPE

    return if @hud.button_down(id, pos)
    return if @props.button_down(id, pos)
    return if @weapons.button_down(id, pos)

    #@character.button_down(id)
  end
end
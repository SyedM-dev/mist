class Character
  attr_reader :world_x, :world_y

  SPEED = 180.0
  SIZE = [25, 30]

  def initialize
    @world_x = 60.0
    @world_y = 60.0

    start_room_coords = $bus.get(:start_room_coords)
    if start_room_coords
      @world_x, @world_y = [(start_room_coords[0] * 2 + 3) * 60 + 30, (start_room_coords[1] * 2 + 3) * 60 + 30]
    end

    # Load the full sheet as tiles
    sheet = Gosu::Image.load_tiles("assets/images/player.png", 20, 40, retro: true)

    rows = [
      :idle_front,
      :idle_back,
      :idle_right,
      :idle_left,
      :walk_front,
      :walk_back,
      :walk_right,
      :walk_left
    ]

    @animations = {}

    rows.each_with_index do |name, row|
      start_index = row * 6
      @animations[name] = sheet[start_index, 6] # slice 6 frames
    end

    @current_animation = :idle_front
    @facing = 0.0

    $bus.on(:player_position) do
      next [@world_x, @world_y]
    end

    $bus.on(:collides?) do |rect|
      next collides?(rect) ? :character : nil
    end

    $bus.on(:player_direction) do
      @facing
    end
  end

  def rect
    w, h = SIZE
    [@world_x - w / 2, @world_y - h / 2, w, h]
  end

  def collides?(rect)
    return true if intersects?(self.rect, rect)
    false
  end

  def angle_to_direction(angle)
    if angle >= -Math::PI / 4 && angle < Math::PI / 4
      :right
    elsif angle >= Math::PI / 4 && angle < 3 * Math::PI / 4
      :front   # down
    elsif angle >= -3 * Math::PI / 4 && angle < -Math::PI / 4
      :back    # up
    else
      :left
    end
  end

  def update(dt)
    dx = 0.0
    dy = 0.0

    dx -= 1 if Gosu.button_down?(Gosu::KB_A)
    dx += 1 if Gosu.button_down?(Gosu::KB_D)
    dy -= 1 if Gosu.button_down?(Gosu::KB_W)
    dy += 1 if Gosu.button_down?(Gosu::KB_S)

    moving = dx != 0 || dy != 0

    if moving
      @facing = Math.atan2(dy, dx)
    end

    direction = angle_to_direction(@facing)
    @current_animation = moving ? :"walk_#{direction}" : :"idle_#{direction}"

    # Normalize vector if moving diagonally
    if dx != 0 && dy != 0
      length = Math.sqrt(dx**2 + dy**2)
      dx /= length
      dy /= length
    end

    # Apply speed
    dx *= SPEED * dt
    dy *= SPEED * dt

    distance = Math.sqrt(dx * dx + dy * dy)
    steps = (distance / 3.0).ceil
    steps = 1 if steps < 1

    step_dx = dx / steps
    step_dy = dy / steps

    steps.times do
      # X axis
      @world_x += step_dx
      if ($bus.get_all(:collides?, rect) & [:wall, :prop])&.any?
        @world_x -= step_dx
      end

      # Y axis
      @world_y += step_dy
      if ($bus.get_all(:collides?, rect) & [:wall, :prop])&.any?
        @world_y -= step_dy
      end
    end

    if $bus.get_all(:collides?, rect).include?(:trap)
      $bus.emit(:trap_stepped_on, rect, :character)
    end

    # teleport to exit room for debug purposes
    if $bus.get(:settings, :debug) && Gosu.button_down?(Gosu::KB_T)
      room_coords = $bus.get(:exit_room_coords)
      if room_coords
        @world_x, @world_y = [room_coords[0] * 120 + 90, room_coords[1] * 120 + 90]
      end
    end

    # Camera follow
    cam_x = @world_x - SCREEN_SIZE[0] / 2.0
    cam_y = @world_y - SCREEN_SIZE[1] / 2.0
    $bus.emit(:player_move, [cam_x, cam_y])
  end

  def draw
    cx = SCREEN_SIZE[0] / 2.0 - SIZE[0] / 2.0
    cy = SCREEN_SIZE[1] / 2.0 - SIZE[1] / 2.0

    sprite_x = cx + SIZE[0] / 2.0 - 20 * 1.8 / 2
    sprite_y = cy + SIZE[1] / 2.0 - 50 * 1.8 / 2

    elapsed = Gosu.milliseconds / 1000.0
    frame_index = ((elapsed * 7).floor) % 6
    @animations[@current_animation][frame_index].draw(sprite_x, sprite_y, sprite_y + 30, 1.8, 1.8)

    return unless $bus.get(:settings, :debug)

    Gosu.draw_rect(cx, cy, SIZE[0], SIZE[1], Gosu::Color.new(0x8000FF00), cy)
  end
end
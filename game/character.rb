class Character
  attr_reader :world_x, :world_y

  SPEED = 2.5
  SIZE = [25, 30]

  def initialize
    @world_x = 60.0
    @world_y = 60.0

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
    @facing = :front
  end

  def rect
    w, h = SIZE
    [@world_x - w / 2, @world_y - h / 2, w, h]
  end

  def collides?(rect)
    return true if intersects?(self.rect, rect)
    false
  end

  def update
    dx = 0.0
    dy = 0.0

    dx -= 1 if Gosu.button_down?(Gosu::KB_A)
    dx += 1 if Gosu.button_down?(Gosu::KB_D)
    dy -= 1 if Gosu.button_down?(Gosu::KB_W)
    dy += 1 if Gosu.button_down?(Gosu::KB_S)

    moving = dx != 0 || dy != 0

    if moving
      if dy < 0
        @facing = :back
      elsif dy > 0
        @facing = :front
      elsif dx < 0
        @facing = :left
      elsif dx > 0
        @facing = :right
      end
    end

    @current_animation = moving ? :"walk_#{@facing}" : :"idle_#{@facing}"

    # Normalize vector if moving diagonally
    if dx != 0 && dy != 0
      length = Math.sqrt(dx**2 + dy**2)
      dx /= length
      dy /= length
    end

    # Apply speed
    dx *= SPEED
    dy *= SPEED

    # Horizontal
    @world_x += dx
    if $bus.get(:collides?, rect)&.include?(:wall)
      @world_x -= dx
    end

    # Vertical
    @world_y += dy
    if $bus.get(:collides?, rect)&.include?(:wall)
      @world_y -= dy
    end

    # teleport to boss room for debug purposes
    if DEBUG && Gosu.button_down?(Gosu::KB_T)
      room_coords = $bus.get(:boss_room_coords)
      if room_coords
        @world_x, @world_y = [room_coords[0] * 60 + 5, room_coords[1] * 60 + 5]
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
    @animations[@current_animation][frame_index].draw(sprite_x, sprite_y, sprite_y, 1.8, 1.8)

    return unless DEBUG

    Gosu.draw_rect(cx, cy, SIZE[0], SIZE[1], Gosu::Color.new(0x8000FF00), cy)
  end
end
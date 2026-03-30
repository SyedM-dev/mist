class EnemyAI
  AGGRO_RADIUS = 2000
  BASE_SPEED = 130.0
  CORNER_OFFSET = 35 # how far from tile center to place corner waypoint

  def initialize(enemy, type)
    @enemy = enemy
    @type = type
    @tile_path = []    # raw tile coords from solver
    @waypoints = []    # actual world positions to move through
    @last_player_tile = nil
    @avoiding_obstacle = false
    @speed = BASE_SPEED
    @lorentz_effect_active = false

    $bus.on(:lorentz_field) do
      @lorentz_effect_active = true
    end

    $bus.on(:lorentz_field_end) do
      @lorentz_effect_active = false
    end
  end

  def update(player_x, player_y, dt)
    distance = Math.sqrt((player_x - @enemy.x)**2 + (player_y - @enemy.y)**2)
    return unless distance < AGGRO_RADIUS

    if @lorentz_effect_active && distance < 230
      @speed = BASE_SPEED * 0.3
    else
      @speed = BASE_SPEED
    end

    player_tile = [(player_x - 90) / 120, (player_y - 90) / 120].map(&:round)
    enemy_tile  = [(@enemy.x - 90) / 120, (@enemy.y - 90) / 120].map(&:round)

    # Don't pathfind if both player and enemy are in the starting room to make sure the player has a safe space to learn the mechanics.
    start_room_tile = ($bus.get(:start_room_coords) || [0, 0])
    return if player_tile[0] > start_room_tile[0] - 1 && player_tile[0] < start_room_tile[0] + 3 &&
              player_tile[1] > start_room_tile[1] - 1 && player_tile[1] < start_room_tile[1] + 3 &&
              enemy_tile[0] > start_room_tile[0] - 1 && enemy_tile[0] < start_room_tile[0] + 3 &&
              enemy_tile[1] > start_room_tile[1] - 1 && enemy_tile[1] < start_room_tile[1] + 3

    return if $bus.get_all(:collides?, @enemy.rect)&.include?(:character)

    prop_in_tile = $bus.get(:prop_at, enemy_tile[0], enemy_tile[1])

    if player_tile == enemy_tile
      los_blocked = !prop_in_tile.nil? && !(
        line_of_sight?(@enemy.x - @enemy.w / 2, @enemy.y - @enemy.h / 2, player_x, player_y, prop_in_tile.collision_rect) &&
        line_of_sight?(@enemy.x + @enemy.w / 2, @enemy.y + @enemy.h / 2, player_x, player_y, prop_in_tile.collision_rect) &&
        line_of_sight?(@enemy.x - @enemy.w / 2, @enemy.y + @enemy.h / 2, player_x, player_y, prop_in_tile.collision_rect) &&
        line_of_sight?(@enemy.x + @enemy.w / 2, @enemy.y - @enemy.h / 2, player_x, player_y, prop_in_tile.collision_rect)
      )

      if los_blocked
        if !@avoiding_obstacle
          center_x = enemy_tile[0] * 120 + 90
          center_y = enemy_tile[1] * 120 + 90

          corners = [
            [center_x - CORNER_OFFSET, center_y - CORNER_OFFSET],
            [center_x + CORNER_OFFSET, center_y - CORNER_OFFSET],
            [center_x + CORNER_OFFSET, center_y + CORNER_OFFSET],
            [center_x - CORNER_OFFSET, center_y + CORNER_OFFSET]
          ]

          closest_idx = corners.each_with_index.min_by { |c, _| Gosu.distance(c[0], c[1], @enemy.x, @enemy.y) }[1]
          @waypoints = corners.rotate(closest_idx)
          @avoiding_obstacle = true
        end
      else
        move_towards(player_x, player_y, dt)
        return
      end
    end

    if @waypoints.empty? || @last_player_tile != player_tile
      @last_player_tile = player_tile
      @tile_path = $bus.get(:maze_solve, enemy_tile[0], enemy_tile[1], player_tile[0], player_tile[1]) || []
      if $bus.get(:prop_at, enemy_tile[0], enemy_tile[1]).nil?
        @tile_path.shift
      end
      @waypoints = build_waypoints(@tile_path)
    end

    return if @waypoints.empty?

    target_x, target_y = @waypoints.first

    if intersects?(@enemy.rect, [target_x - 5, target_y - 5, 10, 10])
      @waypoints.shift
      @avoiding_obstacle = false if @waypoints.empty?
      return
    end

    move_towards(target_x, target_y, dt)
  end

  def draw
    return unless $bus.get(:settings, :debug)
    cam_x, cam_y = $bus.get(:camera_pos) || [0, 0]
    @waypoints.each do |wx, wy|
      Gosu.draw_rect(wx - cam_x - 5, wy - cam_y - 5, 10, 10, Gosu::Color.new(0x88ffff00), Float::INFINITY)
    end
  end

  private

  def build_waypoints(tile_path)
    waypoints = []

    tile_path.each_with_index do |(tx, ty), i|
      center_x = tx * 120 + 90
      center_y = ty * 120 + 90

      unless $bus.get(:prop_at, tx, ty).nil?
        next_tile = tile_path[i + 1]
        prev_tile = i > 0 ? tile_path[i - 1] : nil

        next_cx = next_tile ? next_tile[0] * 120 + 90 : center_x
        next_cy = next_tile ? next_tile[1] * 120 + 90 : center_y
        prev_cx = prev_tile ? prev_tile[0] * 120 + 90 : @enemy.x
        prev_cy = prev_tile ? prev_tile[1] * 120 + 90 : @enemy.y

        corners = [
          [center_x - CORNER_OFFSET, center_y - CORNER_OFFSET],
          [center_x + CORNER_OFFSET, center_y - CORNER_OFFSET],
          [center_x - CORNER_OFFSET, center_y + CORNER_OFFSET],
          [center_x + CORNER_OFFSET, center_y + CORNER_OFFSET]
        ]

        # first waypoint: corner closest to where we're coming from
        first = corners.min_by { |cx, cy| Gosu.distance(cx, cy, prev_cx, prev_cy) }

        # second waypoint: closest to next tile but not opposite to first
        opposite = [center_x - (first[0] - center_x), center_y - (first[1] - center_y)]
        candidates = corners.reject { |c| c == first || c == opposite }
        second = candidates.min_by { |cx, cy| Gosu.distance(cx, cy, next_cx, next_cy) }

        waypoints << first
        waypoints << second
      else
        waypoints << [center_x, center_y]
      end
    end

    waypoints
  end

  def move_towards(target_x, target_y, dt)
    angle = Gosu.angle(@enemy.x, @enemy.y, target_x, target_y)
    dx = Gosu.offset_x(angle, @speed * dt)
    dy = Gosu.offset_y(angle, @speed * dt)

    @enemy.x += dx
    @enemy.y += dy

    if $bus.get_all(:collides?, @enemy.rect)&.include?(:character)
      # Attack player
    end
  end
end
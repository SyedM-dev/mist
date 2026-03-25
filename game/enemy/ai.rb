class EnemyAI
  AGGRO_RADIUS = 2000
  SPEED = 2
  CORNER_OFFSET = 35 # how far from tile center to place corner waypoint

  def initialize(enemy, type)
    @enemy = enemy
    @type = type
    @tile_path = []    # raw tile coords from solver
    @waypoints = []    # actual world positions to move through
    @last_player_tile = nil
    @avoiding_obstacle = false
  end

  def update(player_x, player_y)
    distance = Gosu.distance(@enemy.x, @enemy.y, player_x, player_y)
    return unless distance < AGGRO_RADIUS

    player_tile = [(player_x - 90) / 120, (player_y - 90) / 120].map(&:round)
    enemy_tile  = [(@enemy.x - 90) / 120, (@enemy.y - 90) / 120].map(&:round)

    return if $bus.get(:collides?, @enemy.rect)&.include?(:character)

    object_in_tile = $bus.get(:object_at, enemy_tile[0], enemy_tile[1])

    if player_tile == enemy_tile
      los_blocked = !object_in_tile.nil? && !(
        line_of_sight?(@enemy.x - @enemy.w / 2, @enemy.y - @enemy.h / 2, player_x, player_y, object_in_tile.rect) &&
        line_of_sight?(@enemy.x + @enemy.w / 2, @enemy.y + @enemy.h / 2, player_x, player_y, object_in_tile.rect) &&
        line_of_sight?(@enemy.x - @enemy.w / 2, @enemy.y + @enemy.h / 2, player_x, player_y, object_in_tile.rect) &&
        line_of_sight?(@enemy.x + @enemy.w / 2, @enemy.y - @enemy.h / 2, player_x, player_y, object_in_tile.rect)
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
        move_towards(player_x, player_y)
        return
      end
    end

    if @waypoints.empty? || @last_player_tile != player_tile
      @last_player_tile = player_tile
      @tile_path = $bus.get(:maze_solve, enemy_tile[0], enemy_tile[1], player_tile[0], player_tile[1]) || []
      if $bus.get(:object_at, enemy_tile[0], enemy_tile[1]).nil?
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

    move_towards(target_x, target_y)
  end

  def draw
    return unless DEBUG
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

      unless $bus.get(:object_at, tx, ty).nil?
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

  def move_towards(target_x, target_y)
    angle = Gosu.angle(@enemy.x, @enemy.y, target_x, target_y)
    dx = Gosu.offset_x(angle, SPEED)
    dy = Gosu.offset_y(angle, SPEED)

    steps = SPEED.ceil
    step_dx = dx / steps.to_f
    step_dy = dy / steps.to_f

    steps.times do
      moved_x = false
      moved_y = false

      # Try X
      @enemy.x += step_dx
      if ($bus.get(:collides?, @enemy.rect) & [:wall, :object])&.any?
        @enemy.x -= step_dx
      else
        moved_x = true
      end

      # Try Y (independent — keeps full intent)
      @enemy.y += step_dy
      if ($bus.get(:collides?, @enemy.rect) & [:wall, :object])&.any?
        @enemy.y -= step_dy
      else
        moved_y = true
      end

      # If both failed, stop early
      break unless moved_x || moved_y
    end

    if $bus.get(:collides?, @enemy.rect)&.include?(:character)
      # Attack player
    end
  end
end
class Minimap
  CELL_SIZE = 3       # pixels per minimap cell
  RADIUS = 10         # cells around torch to update

  # Please ignore my overuse of that stupid ruby conditional assignment operator

  def initialize
    @torches = []
    @grid_cache = {}

    $bus.on(:torch_placed) do |gx, gy|
      add_torch(gx, gy)
    end

    $bus.on(:torch_removed) do |gx, gy|
      remove_torch(gx, gy)
    end
  end

  def add_torch(x, y)
    x, y = x * 2 + 1, y * 2 + 1 # convert from room coords to grid coords
    @torches << [x, y]
    update_grid_area(x, y)
  end

  def remove_torch(x, y)
    x, y = x * 2 + 1, y * 2 + 1
    @torches.delete([x, y])
    update_grid_area(x, y)
  end

  # Update only cells in 10-cell box around given gx,gy
  def update_grid_area(cx, cy)
    (cx-RADIUS..cx+RADIUS).each do |gx|
      (cy-RADIUS..cy+RADIUS).each do |gy|
        if @torches.any? { |tx, ty| (gx - tx).abs <= RADIUS && (gy - ty).abs <= RADIUS }
          @grid_cache[[gx, gy]] = if @torches.include?([gx, gy])
                                    :torch
                                  elsif $bus.get(:maze_wall?, gx, gy)
                                    :wall
                                  else
                                    :empty
                                  end
        else
          @grid_cache.delete([gx, gy]) 
        end
      end
    end
  end

  def draw(center_x, center_y)
    half_size = 25  # 40 cells → 20 each side
    map_max = $bus.get(:maze_size).map { |s| s * 2 - 1 } || 0

    offset_x = SCREEN_SIZE[0] - CELL_SIZE * (half_size * 2 + 1) - 10
    offset_y = 10

    size_in_cells = 2 * half_size + 1
    width  = size_in_cells * CELL_SIZE
    height = size_in_cells * CELL_SIZE

    # border
    Gosu.draw_rect(offset_x - 3, offset_y - 3, width + 6, height + 6, Gosu::Color.new(0xFFa9b2a2), Float::INFINITY)

    (-half_size..half_size).each do |dx|
      (-half_size..half_size).each do |dy|
        gx = center_x + dx
        gy = center_y + dy

        type = if gx < 0 || gy < 0 || gx > map_max[0] || gy > map_max[1]
                :wall
              else
                @grid_cache[[gx, gy]] || :unrevealed
              end

        color = case type
                when :wall then Gosu::Color.new(0xFF28353e)
                when :empty then Gosu::Color.new(0xFFd6dad3)
                when :torch then Gosu::Color.new(0xFFfbb954)
                else Gosu::Color.new(0xFF576069)
                end

        color = Gosu::Color::RED if gx == center_x && gy == center_y

        x = (dx + half_size) * CELL_SIZE + offset_x
        y = (dy + half_size) * CELL_SIZE + offset_y

        Gosu.draw_rect(x, y, CELL_SIZE, CELL_SIZE, color, Float::INFINITY)
      end
    end
  end
end
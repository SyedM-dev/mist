class MazeData
  def initialize(width, height, standalone: false)
    @width = width
    @height = height

    @grid = Array.new(height) { Array.new(width, 0) }

    @boss_rooms = []
    @start_room = nil

    crate_rooms!
    carve_passages_from(0, 0)
    fix_room_entrances!
    delete_random_walls!

    return if standalone

    $bus.on(:start_room_coords) do
      next @start_room
    end

    $bus.on(:room?) do |gx, gy|
      ([@start_room] + @boss_rooms).any? do |rx, ry|
        gx.between?(rx, rx + BOSS_ROOM_SIZE) &&
        gy.between?(ry, ry + BOSS_ROOM_SIZE)
      end
    end

    $bus.on(:boss_rooms) do
      next @boss_rooms
    end

    return unless $bus.get(:settings, :debug)

    print_debug
  end
 
  def solve(x1, y1, x2, y2)
    # explain why dijkstra's is fine here: 
      # A* hueristics make it possible to chose a longer path through rooms instead of a shorter path through corridors, which is not what we want for enemy pathfinding
      # Dijkstra's is also simpler to implement since we don't need to worry about the heuristic function, and the maze is not large enough for performance to be a concern

    distances = Array.new(@height) { Array.new(@width, Float::INFINITY) }
    visited = Array.new(@height) { Array.new(@width, false) }
    previous = Array.new(@height) { Array.new(@width, nil) }
    distances[y1][x1] = 0

    queue = [[y1, x1]]

    while !queue.empty?
      cy, cx = queue.shift

      next if visited[cy][cx]
      visited[cy][cx] = true

      return build_path(previous, x1, y1, x2, y2) if cx == x2 && cy == y2

      # can check NSEW walls here to determine which neighbors to add to the queue (no need to check teh neighbors)
      [N, S, E, W].each do |direction|
        next if (@grid[cy][cx] & direction) == 0 # wall in this direction

        nx, ny = cx + DX[direction], cy + DY[direction]

        next unless ny.between?(0, @height - 1) && nx.between?(0, @width - 1)

        alt = distances[cy][cx] + 1
        if alt < distances[ny][nx]
          distances[ny][nx] = alt
          previous[ny][nx] = [cx, cy]
          queue << [ny, nx]
        end
      end
    end

    return nil
  end

  def build_path(previous, x1, y1, x2, y2)
    path = []
    cx, cy = x2, y2

    while cx != x1 || cy != y1
      return nil unless previous[cy][cx]
      path << [cx, cy]
      cx, cy = previous[cy][cx]
    end

    path << [x1, y1]
    path.reverse!
  end

  def width
    @width * 2 + 1
  end

  def height
    @height * 2 + 1
  end

  def wall_type(gx, gy)
    mask = 0
    
    return mask unless wall_at?(gx, gy)

    mask |= N if gy > 0          && wall_at?(gx,     gy - 1)
    mask |= S if gy < height - 1 && wall_at?(gx,     gy + 1)
    mask |= E if gx < width - 1  && wall_at?(gx + 1, gy    )
    mask |= W if gx > 0          && wall_at?(gx - 1, gy    )

    return mask
  end

  def wall_at?(gx, gy)
    return true if gx == 0 || gy == 0 || gx == width - 1 || gy == height - 1

    @boss_rooms.each do |rx, ry|
      display_x1 = rx * 2 + 1
      display_y1 = ry * 2 + 1
      display_x2 = display_x1 + (BOSS_ROOM_SIZE - 1) * 2
      display_y2 = display_y1 + (BOSS_ROOM_SIZE - 1) * 2
      return false if gx.between?(display_x1, display_x2) && gy.between?(display_y1, display_y2)
    end

    return false if gx.odd? && gy.odd?

    if gx.odd? && gy.even?
      cx = (gx - 1) / 2
      cy = (gy - 1) / 2
      return (@grid[cy][cx] & S) == 0
    end

    if gx.even? && gy.odd?
      cx = (gx - 1) / 2
      cy = (gy - 1) / 2
      return (@grid[cy][cx] & E) == 0
    end

    true
  end

  def print_debug
    wall_chars = {
      0   => " ",  # NONE
      1   => "╵",  # N
      2   => "╷",  # S
      3   => "│",  # NS
      4   => "╴",  # W
      5   => "┘",  # NW
      6   => "┐",  # WS
      7   => "┤",  # WNS
      8   => "╶",  # E
      9   => "└",  # NE
      10  => "┌",  # ES
      11  => "├",  # ENS
      12  => "─",  # EW
      13  => "┴",  # EWN
      14  => "┬",  # EWS
      15  => "┼"   # EWNS
    }
    (0...self.height).each do |y|
      (0...self.width).each do |x|
        print wall_chars[wall_type(x, y)]
      end
      print "\n"
    end
  end

  private

  BOSS_ROOM_SIZE = 3
  BOSS_ROOM = 16
  N, S, W, E = 1, 2, 4, 8
  DX         = { E => 1, W => -1, N =>  0, S => 0 }
  DY         = { E => 0, W =>  0, N => -1, S => 1 }
  OPPOSITE   = { E => W, W =>  E, N =>  S, S => N }

  def room_free?(x, y)
    (y - 2...(y + BOSS_ROOM_SIZE + 2)).each do |j|
      (x - 2...(x + BOSS_ROOM_SIZE + 2)).each do |i|
        return false if @grid[j][i] & BOSS_ROOM != 0
      end
    end
    true
  end

  def fix_room_entrances!
    (@boss_rooms + [@start_room]).each do |x, y|
      dir = [N, S, E, W].sample
      cx = x + BOSS_ROOM_SIZE / 2
      cy = y + BOSS_ROOM_SIZE / 2
      case dir
      when N
        @grid[y][cx] |= N
        @grid[y - 1][cx] |= S
      when S
        by = y + BOSS_ROOM_SIZE - 1
        @grid[by][cx] |= S
        @grid[by + 1][cx] |= N
      when W
        @grid[cy][x] |= W
        @grid[cy][x - 1] |= E
      when E
        bx = x + BOSS_ROOM_SIZE - 1
        @grid[cy][bx] |= E
        @grid[cy][bx + 1] |= W
      end
    end
  end

  def crate_rooms!
    base = Math.sqrt(@width * @height / 200.0).round
    num_rooms = rand((base - 1)..(base))
    num_rooms = (num_rooms < 1 ? 1 : num_rooms) + 1 # for start room
    attempts = 0
    rooms = []

    while rooms.size < num_rooms && attempts < 10
      attempts += 1

      x = rand(2..(@width - BOSS_ROOM_SIZE - 2))
      y = rand(2..(@height - BOSS_ROOM_SIZE - 2))

      next unless room_free?(x, y)

      (y...(y + BOSS_ROOM_SIZE)).each do |j|
        (x...(x + BOSS_ROOM_SIZE)).each do |i|
          cell = N | S | E | W
          cell |= BOSS_ROOM

          cell &= ~N if j == y
          cell &= ~S if j == y + BOSS_ROOM_SIZE - 1
          cell &= ~W if i == x
          cell &= ~E if i == x + BOSS_ROOM_SIZE - 1

          @grid[j][i] = cell
        end
      end

      rooms << [x, y]
    end

    @start_room = rooms.shift
    @boss_rooms = rooms
  end

  def carve_passages_from(cx, cy)
    directions = [N, S, E, W].shuffle

    directions.each do |direction|
      nx, ny = cx + DX[direction], cy + DY[direction]

      if ny.between?(0, @height - 1) && nx.between?(0, @width - 1) && @grid[ny][nx] == 0
        @grid[cy][cx] |= direction
        @grid[ny][nx] |= OPPOSITE[direction]
        carve_passages_from(nx, ny)
      end
    end
  end

  def delete_random_walls!
    (0...@height).each do |y|
      (0...@width).each do |x|
        next if rand > 0.05 # 5% chance to delete a wall

        # skip boss rooms
        next if (@grid[y][x] & BOSS_ROOM) != 0

        # pick random direction
        dir = [N, S, E, W].sample
        nx, ny = x + DX[dir], y + DY[dir]

        # bounds check
        next unless ny.between?(0, @height - 1) && nx.between?(0, @width - 1)

        # skip if neighbor is boss room
        next if (@grid[ny][nx] & BOSS_ROOM) != 0

        # remove wall both sides
        @grid[y][x] |= dir
        @grid[ny][nx] |= OPPOSITE[dir]
      end
    end
  end
end

if __FILE__ == $0
  maze = MazeData.new(80, 25, standalone: true)
  maze.print_debug
end
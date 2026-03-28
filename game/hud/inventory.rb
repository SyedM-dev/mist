class Inventory
  OFFSET = [27, 34]
  COLS = 3
  ROW_HEIGHT = 48
  COL_WIDTH = 40

  CRAFT_RECIPES = {
    lorentz_field: { wood: 16, metal: 8, science: 2 },
    torch: { wood: 8 },
    radar: { wood: 2, metal: 8, science: 2 },
    landmine: { wood: 16, metal: 8 },
    shrodingers_mine: { wood: 16, metal: 8, science: 1 },
    event_horizon: { metal: 16, science: 2 },
    occams_razor: { wood: 2, metal: 1 },
    quantum_bow: { wood: 32, metal: 16, science: 8 },
    blade_of_recursion: { wood: 32, metal: 8, science: 4 }
  }.freeze

  def initialize
    items = [
      :wood, :metal, :science,
      :lorentz_field, :torch, :radar,
      :landmine, :shrodingers_mine, :event_horizon,
      :occams_razor, :quantum_bow, :blade_of_recursion
    ]

    @grid = items.each_slice(COLS).map do |slice|
      slice.map do |type|
        [type, initial_amount_max(type)]
      end
    end

    @inventory_selected = :wood
    @font = Gosu::Font.new(8, name: "assets/fonts/tn.ttf")

    $bus.on(:obtain) do |type, amount|
      row, col = find_slot(type)
      next unless row
      @grid[row][col][1][0] += amount
      @grid[row][col][1][0] = @grid[row][col][1][1] if @grid[row][col][1][0] > @grid[row][col][1][1]
    end
  end

  # Draw the inventory
  def draw
    x_start, y_start = OFFSET
    y = y_start

    @grid.each do |row|
      x = x_start
      row.each do |type, (amount, max)|
        # Background highlighting
        if type == @inventory_selected
          Gosu.draw_rect(x + 2, y + 2, 32, 32, Gosu::Color.new(255 * 0.7, 249, 208, 64), Float::INFINITY)
        elsif amount == max
          Gosu.draw_rect(x + 2, y + 2, 32, 32, Gosu::Color.new(255 * 0.7, 128, 239, 128), Float::INFINITY)
        end

        # Empty overlay
        Gosu.draw_rect(x + 2, y + 2, 32, 32, Gosu::Color.new(255 * 0.6, 0, 0, 0), Float::INFINITY) if amount == 0

        # Amount text
        @font.draw_text("#{amount.to_s.rjust(3)}/#{max.to_s.ljust(3)}", x, y + 37, Float::INFINITY, 1, 1, Gosu::Color::WHITE)
        x += COL_WIDTH
      end
      y += ROW_HEIGHT
    end
  end

  # Handle input
  def button_down(id, pos)
    case id
    when Gosu::MS_LEFT, Gosu::MS_RIGHT
      mouse_click(*pos, id)
    when Gosu::KB_1 then @inventory_selected = :occams_razor
    when Gosu::KB_2 then @inventory_selected = :quantum_bow
    when Gosu::KB_3 then @inventory_selected = :blade_of_recursion
    when Gosu::KB_C
      row, col = find_slot(@inventory_selected)
      @inventory_selected = @grid[(row + 1) % @grid.size][col][0]
    when Gosu::KB_V
      row, col = find_slot(@inventory_selected)
      @inventory_selected = @grid[row][(col + 1) % @grid[row].size][0]
    end
  end

  # Mouse click detection
  def mouse_click(mx, my, id)
    x_start, y_start = OFFSET
    row_idx = ((my - y_start) / ROW_HEIGHT).floor
    col_idx = ((mx - x_start) / COL_WIDTH).floor

    return if row_idx < 0 || row_idx >= @grid.size
    return if col_idx < 0 || col_idx >= @grid[row_idx].size

    type, (amount, max) = @grid[row_idx][col_idx]

    if id == Gosu::MS_LEFT
      @inventory_selected = type
    elsif id == Gosu::MS_RIGHT
      if DEBUG && [:wood, :metal, :science].include?(type)
        @grid[row_idx][col_idx][1][0] = max
      else
        craft(type, ctrl: Gosu.button_down?(Gosu::KB_RIGHT_CONTROL) || Gosu.button_down?(Gosu::KB_LEFT_CONTROL))
      end
    end
  end

  private

  def craft(type, ctrl: false)
    return unless CRAFT_RECIPES.key?(type)

    recipe = CRAFT_RECIPES[type]

    # How many we can craft
    possible_counts = recipe.map { |res, req| grid_value(res) / req }
    max_possible = possible_counts.min
    return if max_possible == 0

    craft_amount = ctrl ? max_possible : 1

    # Subtract resources
    recipe.each do |res, req|
      row, col = find_slot(res)
      @grid[row][col][1][0] -= req * craft_amount
    end

    # Add crafted item
    row, col = find_slot(type)
    @grid[row][col][1][0] += craft_amount
    # Clamp to max
    @grid[row][col][1][0] = @grid[row][col][1][1] if @grid[row][col][1][0] > @grid[row][col][1][1]
  end

  # Helper to get amount of resource
  def grid_value(type)
    row, col = find_slot(type)
    return 0 unless row
    @grid[row][col][1][0]
  end

  # Initial amount/max mapping
  def initial_amount_max(type)
    case type
    when :wood, :metal then [0, 64]
    when :science then [0, 32]
    when :lorentz_field then [0, 4]
    when :torch then [0, 8]
    when :radar then [0, 4]
    when :landmine, :shrodingers_mine then [0, 8]
    when :event_horizon then [0, 4]
    when :occams_razor, :quantum_bow, :blade_of_recursion then [0, 1]
    else [0, 0]
    end
  end

  # Find slot in grid for a type
  def find_slot(type)
    @grid.each_with_index do |row, r|
      row.each_with_index do |(t, _), c|
        return [r, c] if t == type
      end
    end
    nil
  end
end
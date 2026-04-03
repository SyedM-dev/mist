class Inventory
  OFFSET = [27, 34]
  COLS = 3
  ROW_HEIGHT = 48
  COL_WIDTH = 40
  RECT = [22, 30, 126, 196]

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

    $bus.on(:consume) do |type, amount|
      row, col = find_slot(type)
      next false unless row
      next false if @grid[row][col][1][0] < amount
      @grid[row][col][1][0] -= amount
      next true
    end

    $bus.on(:count) do |type|
      row, col = find_slot(type)
      next 0 unless row
      next @grid[row][col][1][0]
    end

    $bus.on(:selected_item) do
      @inventory_selected
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
      return mouse_click(*pos, id)
    when Gosu::KB_1 then @inventory_selected = :occams_razor
    when Gosu::KB_2 then @inventory_selected = :quantum_bow
    when Gosu::KB_3 then @inventory_selected = :blade_of_recursion
    when $bus.get(:settings, :"inventory down")
      row, col = find_slot(@inventory_selected)
      @inventory_selected = @grid[(row + 1) % @grid.size][col][0]
    when $bus.get(:settings, :"inventory up")
      row, col = find_slot(@inventory_selected)
      @inventory_selected = @grid[(row - 1) % @grid.size][col][0]
    when $bus.get(:settings, :"inventory left")
      row, col = find_slot(@inventory_selected)
      @inventory_selected = @grid[row][(col - 1) % @grid[row].size][0]
    when $bus.get(:settings, :"inventory right")
      row, col = find_slot(@inventory_selected)
      @inventory_selected = @grid[row][(col + 1) % @grid[row].size][0]
    when $bus.get(:settings, :craft)
      craft(@inventory_selected, ctrl: Gosu.button_down?(Gosu::KB_RIGHT_CONTROL) || Gosu.button_down?(Gosu::KB_LEFT_CONTROL))
    else
      return false
    end
    true
  end

  # Mouse click detection
  def mouse_click(mx, my, id)
    return false unless intersects?([mx, my, 1, 1], RECT)

    x_start, y_start = OFFSET
    row_idx = ((my - y_start) / ROW_HEIGHT).floor
    col_idx = ((mx - x_start) / COL_WIDTH).floor

    return true if row_idx < 0 || row_idx >= @grid.size
    return true if col_idx < 0 || col_idx >= @grid[row_idx].size

    type, (amount, max) = @grid[row_idx][col_idx]

    if id == Gosu::MS_LEFT
      @inventory_selected = type
    elsif id == Gosu::MS_RIGHT
      if $bus.get(:settings, :debug) && [:wood, :metal, :science].include?(type)
        @grid[row_idx][col_idx][1][0] = max
      else
        craft(type, ctrl: Gosu.button_down?(Gosu::KB_RIGHT_CONTROL) || Gosu.button_down?(Gosu::KB_LEFT_CONTROL))
      end
    end

    true
  end

  private

  def craft(type, ctrl: false)
    return unless CRAFT_RECIPES.key?(type)

    recipe = CRAFT_RECIPES[type]

    # How many we can craft based on resources
    resource_max = recipe.map { |res, req| grid_value(res) / req }.min
    return if resource_max == 0

    # How many we can fit in inventory slot
    row, col = find_slot(type)
    return unless row  # sanity check

    slot_amount, slot_max = @grid[row][col][1]
    fit_max = slot_max - slot_amount
    return if fit_max == 0  # can't fit anything

    # Determine craft amount (1 or as many as possible)
    craft_amount = ctrl ? [resource_max, fit_max].min : 1
    return if craft_amount == 0  # nothing to craft

    # Subtract resources
    recipe.each do |res, req|
      r, c = find_slot(res)
      @grid[r][c][1][0] -= req * craft_amount
    end

    # Add crafted items
    @grid[row][col][1][0] += craft_amount
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
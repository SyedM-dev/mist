require_relative "radar"
require_relative "torch"
require_relative "chest"

class PropsHandler
  attr_reader :props

  def initialize
    @props = []
    @grid = {}

    spawn_chests!

    $bus.on(:collides?) do |rect|
      nearby_props(rect).any? { |p| p.collides?(rect) } ? :prop : nil
    end

    $bus.on(:prop_at) do |x, y|
      @grid[[x, y]]
    end

    $bus.on(:nearby_torches) do |rect|
      nearby_props(rect).select { |p| p.is_a?(Torch) }.map { |t| t.rect }
    end
  end

  def spawn_chests!
    world_size = $bus.get(:maze_size) || [0, 0]

    cell_size = 8

    (0...world_size[0]).step(cell_size) do |cx|
      (0...world_size[1]).step(cell_size) do |cy|

        # Random position inside this cell
        x = cx + rand(cell_size)
        y = cy + rand(cell_size)

        next if x >= world_size[0] || y >= world_size[1]

        # Keep your spawn exclusion
        next if (x - 2).abs <= 1 && (y - 2).abs <= 1

        next if $bus.get(:room?, x, y)

        chest = Chest.new(x, y)
        @props << chest
        @grid[[x, y]] = chest
      end
    end

    # Add one in the start room for players to have something to interact with right away
    start_room_x, start_room_y = $bus.get(:start_room_coords) || [0, 0]
    x, y = [
      [start_room_x, start_room_y],
      [start_room_x + 2, start_room_y],
      [start_room_x, start_room_y + 2],
      [start_room_x + 2, start_room_y + 2]
    ].sample
    chest = Chest.new(x, y)
    @props << chest
    @grid[[x, y]] = chest
  end

  def nearby_props(rect)
    x, y, w, h = rect

    min_tx = ((x) / 120).floor
    max_tx = ((x + w) / 120).floor
    min_ty = ((y) / 120).floor
    max_ty = ((y + h) / 120).floor

    results = []

    (min_tx..max_tx).each do |tx|
      (min_ty..max_ty).each do |ty|
        p = @grid[[tx, ty]]
        results << p if p
      end
    end

    results
  end

  def add(prop)
    @props << prop

    key = [prop.x, prop.y]
    @grid[key] = prop
  end

  def update(dt)
    cam = $bus.get(:camera_pos) || [0, 0]
    nearby_props([*cam, *SCREEN_SIZE]).each do |prop|
      if prop.update(dt)
        @props.delete(prop)
        @grid.delete([prop.x, prop.y])
      end
    end
  end

  def draw
    cam = $bus.get(:camera_pos) || [0, 0]
    nearby_props([*cam, *SCREEN_SIZE]).each(&:draw)
  end
end
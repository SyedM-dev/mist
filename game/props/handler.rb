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
      nearby_props(rect).select { |p| p.is_a?(Torch) }.map(&:rect).map { |t| [t[0] + t[2] / 2, t[1] + t[3] / 2] }
    end

    $bus.on(:radar_triangulation?) do |player_x, player_y|
      radar_triangulation?(player_x, player_y)
    end
  end

  def radar_triangulation?(player_x, player_y)
    # small rect around player to find the first radar
    small_rect = [player_x - 60, player_y - 60, 120, 120] # 1 block radius
    first_radar = nearby_props(small_rect).find { |p| p.is_a?(Radar) }
    return false unless first_radar

    # larger rect to find other radars (max 15 blocks away, 15*120 pixels)
    large_rect = [first_radar.x * 120 - 15 * 120, first_radar.y * 120 - 15 * 120, 30 * 120, 30 * 120]
    nearby_radars = nearby_props(large_rect).select { |p| p.is_a?(Radar) }

    # need at least 3 radars total
    return false if nearby_radars.size < 3

    nearby_radars.combination(3).any? do |r1, r2, r3|
      next unless r1 == first_radar || r2 == first_radar || r3 == first_radar

      d1 = Math.hypot((r1.x - r2.x), (r1.y - r2.y))
      d2 = Math.hypot((r1.x - r3.x), (r1.y - r3.y))
      d3 = Math.hypot((r2.x - r3.x), (r2.y - r3.y))

      [d1, d2, d3].all? { |d| d >= 3 && d <= 15 }
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

    # Add one in the start room for players to have something right away
    start_room_x, start_room_y = $bus.get(:start_room_coords) || [0, 0]
    x, y = [
      [start_room_x, start_room_y],
      [start_room_x + 2, start_room_y],
      [start_room_x, start_room_y + 2],
      [start_room_x + 2, start_room_y + 2]
    ].sample
    chest = Chest.new(x, y)
    add(chest)
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
    @grid[[prop.x, prop.y]] = prop
  end

  def update(dt)
    cam = $bus.get(:camera_pos) || [0, 0]
    nearby_props([*cam, *SCREEN_SIZE]).each do |prop|
      if prop.update(dt)
        @props.delete(prop)
        @grid.delete([prop.x, prop.y])
      end
    end
    if Gosu.button_down?($bus.get(:settings, :place))
      selected_item = $bus.get(:selected_item)
      if selected_item == :torch
        player_x, player_y = $bus.get(:player_position) || [0, 0]
        tile = [(player_x - 90) / 120, (player_y - 90) / 120].map(&:round)
        torch = Torch.new(*tile)
        return if @grid[[tile[0], tile[1]]] # can't place if something is already there
        return if $bus.get_all(:collides?, torch.collision_rect).include?(:character) # can't place if colliding with player
        return unless $bus.get(:consume, :torch, 1)
        $bus.emit(:torch_placed, torch.x, torch.y)
        add(torch)
      elsif selected_item == :radar
        player_x, player_y = $bus.get(:player_position) || [0, 0]
        tile = [(player_x - 90) / 120, (player_y - 90) / 120].map(&:round)
        radar = Radar.new(*tile)
        return if @grid[[tile[0], tile[1]]]
        return if $bus.get_all(:collides?, radar.collision_rect).include?(:character)
        return unless $bus.get(:consume, :radar, 1)
        add(radar)
      end
    end
  end

  def button_down(id, pos)
    #
  end

  def draw
    cam = $bus.get(:camera_pos) || [0, 0]
    nearby_props([*cam, *SCREEN_SIZE]).each(&:draw)
    draw_ghost_prop!
  end

  def draw_ghost_prop!
    # draw a ghost of the prop that would be placed if the player presses the place button,
    # to give them a preview of where it would go, also tint it red if it can't be placed there for any reason
    # or green if it can
    selected_item = $bus.get(:selected_item)
    return unless [:torch, :radar].include?(selected_item)
    cam_x, cam_y = $bus.get(:camera_pos) || [0, 0]
    player_x, player_y = $bus.get(:player_position) || [0, 0]
    x, y = [(player_x - 90) / 120, (player_y - 90) / 120].map(&:round)
    return if @grid[[x, y]]
    return if $bus.get(:count, selected_item) < 1
    world_x = x * 120 + 90
    world_y = y * 120 + 90
    screen_x = world_x - cam_x
    screen_y = world_y - cam_y
    possible = !$bus.get_all(:collides?, [world_x - Prop::SIZE[0] / 2, world_y - Prop::SIZE[1], *Prop::SIZE]).include?(:character)
    color = possible ? Gosu::Color.new(255 * 0.7, 128, 239, 128) : Gosu::Color.new(255 * 0.7, 255, 116, 108)
    if selected_item == :torch
      Torch.ghost.draw(screen_x - 20, screen_y - 20, screen_y, 2, 2, color)
    elsif selected_item == :radar
      Radar.ghost.draw(screen_x - 20, screen_y - 20, screen_y, 2, 2, color)
    end
  end
end
require_relative 'landmine'
require_relative 'shrodingers_mine'
require_relative 'event_horizon'

class TrapHandler
  def initialize
    # traps are stored in a grid for efficient collision checking
    # can write in report about trying to use an array and how it was too slow to check every trap for collisions, so we switched to a grid where each cell is 120x120, blah blah
    @grid = {}

    $bus.on(:collides?) do |rect|
      nearby_traps(rect).any? { |t| t.collides?(rect) } ? :trap : nil
    end

    $bus.on(:trap_stepped_on) do |rect, entity|
      nearby_traps(rect).each do |t|
        t.collides?(rect) && t.stepped_on(entity) && @grid[[(t.x / 120).floor, (t.y / 120).floor]].delete(t) # remove the trap if stepped on
      end
    end

    $bus.on(:closest_event_horizon) do |x, y, range|
      # this abomination is to find the closest event horizon within range, we can optimize this later if needed but for now it works
      nearby_traps([x - range, y - range, range * 2, range * 2])
        .select { |t| t.is_a?(EventHorizon) }
        .map { |t| [t, Math.hypot(t.x - x, t.y - y)] }
        .select { |_, d| d <= range }
        .min_by { |_, d| d }
        &.first&.then { |e| [e.x, e.y] }
    end
  end

  def add(trap)
    tx = (trap.x / 120).floor
    ty = (trap.y / 120).floor

    @grid[[tx, ty]] ||= []
    @grid[[tx, ty]] << trap
  end

  def update dt
    # allow placing traps by the player
    if Gosu.button_down?(Gosu::MS_LEFT)
      selected_item = $bus.get(:selected_item)
      if selected_item == :landmine
        mouse_x, mouse_y = $bus.get(:mouse_pos) || [0, 0]
        player_x, player_y = $bus.get(:player_position) || [0, 0]
        cam_x, cam_y = $bus.get(:camera_pos) || [0, 0]
        world_x = mouse_x + cam_x
        world_y = mouse_y + cam_y
        landmine = Landmine.new(world_x, world_y)
        return if Math.hypot(landmine.x - player_x, landmine.y - player_y) > 200 # can't place if too far from player
        return if ($bus.get_all(:collides?, landmine.collision_rect) & [:character, :prop, :trap, :wall]).any?
        return unless $bus.get(:consume, :landmine, 1)
        add(landmine)
      elsif selected_item == :shrodingers_mine
        mouse_x, mouse_y = $bus.get(:mouse_pos) || [0, 0]
        player_x, player_y = $bus.get(:player_position) || [0, 0]
        cam_x, cam_y = $bus.get(:camera_pos) || [0, 0]
        world_x = mouse_x + cam_x
        world_y = mouse_y + cam_y
        mine = ShrodingersMine.new(world_x, world_y)
        return if Math.hypot(mine.x - player_x, mine.y - player_y) > 200
        return if ($bus.get_all(:collides?, mine.collision_rect) & [:character, :prop, :trap, :wall]).any?
        return unless $bus.get(:consume, :shrodingers_mine, 1)
        add(mine)
      elsif selected_item == :event_horizon
        mouse_x, mouse_y = $bus.get(:mouse_pos) || [0, 0]
        player_x, player_y = $bus.get(:player_position) || [0, 0]
        cam_x, cam_y = $bus.get(:camera_pos) || [0, 0]
        world_x = mouse_x + cam_x
        world_y = mouse_y + cam_y
        event_horizon = EventHorizon.new(world_x, world_y)
        return if Math.hypot(world_x - player_x, world_y - player_y) > 200
        return if ($bus.get_all(:collides?, event_horizon.collision_rect) & [:character, :prop, :trap, :wall]).any?
        return unless $bus.get(:consume, :event_horizon, 1)
        add(event_horizon)
      end
    end
  end

  def nearby_traps(rect)
    x, y, w, h = rect

    min_tx = ((x) / 120).floor
    max_tx = ((x + w) / 120).floor
    min_ty = ((y) / 120).floor
    max_ty = ((y + h) / 120).floor

    results = []

    (min_tx..max_tx).each do |tx|
      (min_ty..max_ty).each do |ty|
        t = @grid[[tx, ty]]
        results.concat(t) if t
      end
    end

    results
  end

  def draw
    cam = $bus.get(:camera_pos) || [0, 0]
    nearby_traps([*cam, *SCREEN_SIZE]).each(&:draw)
    draw_ghost_traps!
  end

  def draw_ghost_traps!
    selected_item = $bus.get(:selected_item)
    return unless [:landmine, :shrodingers_mine, :event_horizon].include?(selected_item) # only draw if selected item is a placeable trap
    return unless $bus.get(:count, selected_item) > 0 # only draw if player has at least 1 landmine

    mouse_x, mouse_y = $bus.get(:mouse_pos) || [0, 0]
    cam_x, cam_y = $bus.get(:camera_pos) || [0, 0]
    world_x = mouse_x + cam_x
    world_y = mouse_y + cam_y

    color = Gosu::Color.new(128, 255, 255, 255)
    player_x, player_y = $bus.get(:player_position) || [0, 0]
    if Math.hypot(world_x - player_x, world_y - player_y) > 100 ||
       ($bus.get_all(:collides?, [world_x - 20, world_y - 20, 40, 40]) & [:character, :prop, :trap, :wall]).any?
      color = Gosu::Color.new(128, 255, 0, 0) # red if too far
    elsif nearby_traps([world_x - 20, world_y - 20, 40, 40]).any? { |t| t.collides?([world_x - 20, world_y - 20, 40, 40]) }
      color = Gosu::Color.new(128, 255, 255, 0) # yellow if colliding with another trap
    end

    ghost_sprite = Gosu::Image.new("assets/images/#{selected_item}.png", retro: true)
    ghost_sprite.draw(world_x - 20 - cam_x, world_y - 20 - cam_y, 0, 2, 2, color)
  end
end
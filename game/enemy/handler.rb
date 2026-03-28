require_relative 'base'

class EnemyHandler
  def initialize
    @enemies = []
  end

  def update(dt)
    spawn!
    @enemies.each { |enemy| enemy.update(dt) }
  end

  def spawn!
    # For now, just spawn a single enemy at a fixed location
    #start_room_coords = $bus.get(:start_room_coords)
    #if @enemies.empty?
    #  @enemies << Enemy.new((start_room_coords[0] * 2 + 1 + 4) * 60 + 30, (start_room_coords[1] * 2 + 1 + 4) * 60 + 30)
    #end
  end

  def draw
    @enemies.each(&:draw)
  end

  def collides?(rect)
    @enemies.any? { |enemy| enemy.collides?(rect) }
  end
end

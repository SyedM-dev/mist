require_relative 'force'
require_relative 'komodo'

class EnemyHandler
  def initialize
    @enemies = []

    $bus.on(:enemy_died) do |enemy|
      $bus.remove_owner(enemy)
      @enemies.delete(enemy)
    end
  end

  def update(dt)
    spawn!
    @enemies.each { |enemy| enemy.update(dt) }
  end

  def spawn!
    boss_rooms = $bus.get(:boss_rooms) || []
    if @enemies.count < 4 && rand < (1.0 / (60 * 10))
      boss_room = boss_rooms.sample
      type = rand < 0.1 ? Komodo : Force
      @enemies << (type).new((boss_room[0] * 2 + 4) * 60 + 30, (boss_room[1] * 2 + 4) * 60 + 30)
    end
  end

  def draw
    @enemies.each(&:draw)
  end

  def collides?(rect)
    @enemies.any? { |enemy| enemy.collides?(rect) }
  end
end

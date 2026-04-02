class QuantumBow
  ARROW_SPEED = 700
  LOW_DAMAGE  = 10
  HIGH_DAMAGE = 50
  FACING_THRESHOLD = Math::PI / 2.0  # 90° in radians

  def initialize
    @arrows = []
    #@sprite = Gosu::Image.new('assets/images/quantum_bow.png', retro: true)
    @arrow_sprite = Gosu::Image.new('assets/images/arrow.png', retro: true)
  end

  def clamp_angle(intended, player)
    # it takes the direction from the attack function and only allows attacks facing forwards from the player,
    # and if it is not in 90 deg from players direction then it will return the extreme angle possible else the intended angle
    angle_diff = ((intended - player + Math::PI) % (2 * Math::PI)) - Math::PI
    if angle_diff > FACING_THRESHOLD
      return player + FACING_THRESHOLD
    elsif angle_diff < -FACING_THRESHOLD
      return player - FACING_THRESHOLD
    else
      return intended
    end
  end

  def attack(direction)
    player_x, player_y = $bus.get(:player_position)
    return unless $bus.get(:consume, :wood, 3) && $bus.get(:consume, :metal, 1)

    @arrows << { x: player_x, y: player_y, direction: clamp_angle(direction, $bus.get(:player_direction)) }
  end

  def update(dt)
    player_x, player_y = $bus.get(:player_position)
    player_dir = $bus.get(:player_direction)

    @arrows.each do |arrow|
      arrow[:x] += Math.cos(arrow[:direction]) * ARROW_SPEED * dt
      arrow[:y] += Math.sin(arrow[:direction]) * ARROW_SPEED * dt

      rect = [arrow[:x] - 5, arrow[:y] - 2, 10, 4]
      collides = $bus.get_all(:collides?, rect)

      if collides.include?(:enemy)
        # compute if player is facing the arrow
        vec_x = arrow[:x] - player_x
        vec_y = arrow[:y] - player_y
        angle_to_arrow = Math.atan2(vec_y, vec_x)
        angle_diff = ((angle_to_arrow - player_dir + Math::PI) % (2 * Math::PI)) - Math::PI
        angle_diff = angle_diff.abs

        if angle_diff > FACING_THRESHOLD
          $bus.emit(:blast, arrow[:x], arrow[:y], 30, HIGH_DAMAGE, :safe)
        else
          $bus.emit(:attack, arrow[:x], arrow[:y], 30, LOW_DAMAGE)
        end

        arrow[:hit] = true
      elsif collides.include?(:wall)
        arrow[:hit] = true
      end
    end

    @arrows.reject! { |a| a[:hit] }
  end

  def draw
    cam_x, cam_y = $bus.get(:camera_pos) || [0, 0]

    @arrows.each do |arrow|
      angle_deg = arrow[:direction] * 180 / Math::PI
      angle_deg -= 45 + 180
      @arrow_sprite.draw_rot(arrow[:x] - cam_x, arrow[:y] - cam_y, 1, angle_deg, 0.5, 0.5, 2, 2, Gosu::Color::WHITE)
    end

    #player_x, player_y = $bus.get(:player_position)
    #@sprite.draw(player_x - cam_x - 16, player_y - cam_y - 16, 1)
  end
end
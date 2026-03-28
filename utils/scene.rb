class Scene
  # Base class for all scenes.

  def initialize
  end

  def update(_dt)
  end

  def draw
  end

  def button_down(id, pos)
  end

  def close
    $bus.remove_owner(self)
  end
end
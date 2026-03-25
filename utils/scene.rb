class Scene
  # Base class for all scenes.

  def initialize
  end

  def update
  end

  def draw
  end

  def button_down(id, pos)
  end

  def close
    $bus.unlisten_owner(self)
  end
end
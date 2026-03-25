class Settings < Scene
  def initialize
    super
    @font = Gosu::Font.new(24)
  end

  def draw
    Gosu.draw_rect(0, 0, SCREEN_SIZE[0], SCREEN_SIZE[1], Gosu::Color::BLACK)
    @font.draw_text("Settings Scene - Press ESC to return to Menu", 50, 50, 1, 1, 1, Gosu::Color::WHITE)
  end

  def button_down(id, _pos)
    $bus.emit(:change_scene, Menu.new) if id == Gosu::KB_ESCAPE
  end
end
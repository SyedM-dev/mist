class Credits < Scene
  def initialize
    super
    @font = Gosu::Font.new(32, name: "assets/fonts/tn.ttf")
    @small_font = Gosu::Font.new(20, name: "assets/fonts/tn.ttf")
  end

  def update(_dt)
    # nothing needed
  end

  def draw
    Gosu.draw_rect(0, 0, *SCREEN_SIZE, Gosu::Color.new(0xFF131313))

    # title (centered)
    title = "Credits"
    tx = (720 - @font.text_width(title)) / 2
    @font.draw_text(title, tx, 80, 1, 1, 1, Gosu::Color::YELLOW)

    # main content
    # this is kinda useless and i could just hardcode the positions, or even the image itself but yeah
    lines = [
      "Developer: Syed Daanish",
      "Artist: Syed Daanish"
    ]

    lines.each_with_index do |line, i|
      x = (720 - @small_font.text_width(line)) / 2
      y = 180 + i * 40
      @small_font.draw_text(line, x, y, 1, 1, 1, Gosu::Color::WHITE)
    end

    # hint at bottom
    hint = "Press ESC to return"
    hx = (720 - @small_font.text_width(hint)) / 2
    @small_font.draw_text(hint, hx, 420, 1, 1, 1, Gosu::Color::GRAY)
  end

  def button_down(id, _pos)
    if id == Gosu::KB_ESCAPE || id == Gosu::KB_RETURN
      $bus.emit(:change_scene, Menu)
    end
  end
end
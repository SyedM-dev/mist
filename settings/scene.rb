class Settings < Scene
  def initialize
    super
    @font_title = Gosu::Font.new(28, name: "assets/fonts/tn.ttf")
    @font = Gosu::Font.new(20, name: "assets/fonts/tn.ttf")
    @selected = 0
    @waiting_for_key = nil
  end

  def draw
    Gosu.draw_rect(0, 0, *SCREEN_SIZE, Gosu::Color.new(0xFF131313))

    title = "Settings"
    @font_title.draw_text(title, center_x(title), 40, 1, 1, 1, Gosu::Color::YELLOW)

    debug_option = "Debug Mode".ljust(15) + " : " + "#{Config.debug ? 'ON' : 'OFF'}".rjust(12)
    debug_option = "> #{debug_option} <" if @selected == 0
    @font.draw_text(debug_option, center_x(debug_option), 90, 1, 1, 1, @selected == 0 ? Gosu::Color::YELLOW : Gosu::Color::WHITE)

    Config.bindings.each_with_index do |opt, i|
      y = 120 + i * 25
      selected = (i == @selected - 1)

      text = "#{opt[0].to_s.ljust(15)} : #{Gosu.button_name(opt[1]).rjust(12)}"
      text = "> #{text} <" if selected

      color = selected ? Gosu::Color::YELLOW : Gosu::Color::WHITE
      @font.draw_text(text, center_x(text), y, 1, 1, 1, color)
    end

    if @waiting_for_key
      msg = "Press a key... (ESC to cancel)"
      @font.draw_text(msg, center_x(msg), 430, 1, 1, 1, Gosu::Color::GRAY)
    else
      hint = "Enter: Select | ESC: Back"
      @font.draw_text(hint, center_x(hint), 430, 1, 1, 1, Gosu::Color::GRAY)
    end
  end

  def button_down(id, _pos)
    # waiting for keybind input
    if @waiting_for_key
      if [Gosu::KB_ESCAPE].include?(id)
        @waiting_for_key = nil
        return
      end
      Config.set_key(@waiting_for_key, id)
      Config.persist!
      @waiting_for_key = nil
      return
    end

    case id
    when Gosu::KB_UP
      @selected = (@selected - 1) % (Config.bindings.size + 1)
    when Gosu::KB_DOWN
      @selected = (@selected + 1) % (Config.bindings.size + 1)
    when Gosu::KB_RETURN
      if @selected == 0
        Config.debug = !Config.debug
        Config.persist!
      else
        @waiting_for_key = Config.bindings.keys[@selected]
      end
    when Gosu::KB_ESCAPE
      Config.persist!
      $bus.emit(:change_scene, Menu)
    end
  end

  private

  def center_x(text)
    (SCREEN_SIZE[0] - @font.text_width(text)) / 2
  end
end
class GameOver < Scene
  OPTIONS = {
    "Retry" => -> { $bus.emit(:change_scene, Game) },
    "Main Menu" => -> { $bus.emit(:change_scene, Menu) }
  }.freeze

  def initialize
    super
    @font = Gosu::Font.new(32, name: "assets/fonts/tn.ttf")
    @selected_index = 0
    @bg_image = Gosu::Image.new("assets/images/game_over_#{$is_dead ? 'dead' : 'victory'}_bg.png", retro: true)
    @last_mouse_pos = nil
  end

  def update(_dt)
    pos = $bus.get(:mouse_pos)
    return unless pos

    if @last_mouse_pos.nil? || ( (pos[0] - @last_mouse_pos[0]).abs > 2 || (pos[1] - @last_mouse_pos[1]).abs > 2 )
      hovered_option = item_at(pos)
      @selected_index = hovered_option[0] if hovered_option
      @last_mouse_pos = pos.dup
    end
  end

  def draw
    @bg_image.draw(0, 0, 1)

    OPTIONS.each_with_index do |(text, _), index|
      y = 360 + index * 50
      if index == @selected_index
        @font.draw_text("[ #{text.ljust(10)} ]", 50, y, 1, 1, 1, Gosu::Color::YELLOW)
      else
        @font.draw_text("  #{text.ljust(10)}  ", 50, y, 1, 1, 1, Gosu::Color::WHITE)
      end
    end
  end

  def button_down(id, pos)
    case id
    when Gosu::KB_UP
      @selected_index = (@selected_index - 1) % OPTIONS.size
    when Gosu::KB_DOWN
      @selected_index = (@selected_index + 1) % OPTIONS.size
    when Gosu::KB_RETURN
      OPTIONS.values[@selected_index].call
    end

    return unless id == Gosu::MS_LEFT && pos

    selected_option = item_at(pos)
    selected_option[1].call if selected_option
  end

  private

  def item_at(pos)
    OPTIONS.each_with_index do |(_, action), index|
      y = 360 + index * 50
      if pos[1].between?(y, y + 32) && pos[0].between?(50, 50 + @font.text_width(" " * 14))
        return [index, action]
      end
    end
    nil
  end
end
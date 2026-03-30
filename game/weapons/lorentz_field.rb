class LorentzField
  BASE_TIME = 25 # Base time for the field to be active in seconds

  def initialize
    @time = 0
    @active = false
    @font = Gosu::Font.new(24, name: "assets/fonts/tn.ttf")

    $bus.on(:lorentz_field) do
      if @active
        t = @time
        remaining = BASE_TIME - t

        if t < 4
          # fade in
          next t / 4.0
        elsif remaining < 4
          # fade out
          next remaining / 4.0
        else
          # fully active
          next 1.0
        end
      else
        next 0.0
      end
    end
  end

  def attack
    return if @active
    $bus.emit(:consume, :lorentz_field, 1)
    @active = true
    @time = 0
    $bus.emit(:lorentz_field)
  end

  def update(dt)
    return unless @active

    @time += dt
    if @time >= BASE_TIME
      @time = 0
      @active = false
      $bus.emit(:lorentz_field_end)
    end
  end

  def draw
    # for now draw the time
    return unless @active

    remaining = BASE_TIME - @time
    text = "Lorentz Field: #{remaining.round(1)}s"

    @font.draw_text(text, SCREEN_SIZE[0] / 2 - @font.text_width(text) / 2, 10, Float::INFINITY, 1, 1, Gosu::Color::CYAN)
  end
end
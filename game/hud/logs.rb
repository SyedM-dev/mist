class GameLogger
  MAX_ENTRIES = 5          # max messages to show
  DURATION = 3.0           # seconds each message stays

  Entry = Struct.new(:text, :time)

  def initialize
    @entries = []
    @font = Gosu::Font.new(10, name: 'assets/fonts/tn.ttf')

    $bus.on(:log) do |msg|
      log(msg)
    end
  end

  # add a message
  def log(msg)
    @entries << Entry.new(msg, DURATION)
    @entries.shift if @entries.size > MAX_ENTRIES
  end

  def update(dt)
    @entries.each { |e| e.time -= dt }
    @entries.reject! { |e| e.time <= 0 }
  end

  def draw
    padding_x = 10
    padding_y = 10
    line_height = 24

    # bottom-left start
    base_x = padding_x
    base_y = SCREEN_SIZE[1] - padding_y - line_height * @entries.size

    @entries.each_with_index do |e, i|
      @font.draw_text(
        e.text,
        base_x,
        base_y + i * line_height,
        Float::INFINITY,
        1, 1,
        Gosu::Color::YELLOW
      )
    end
  end
end
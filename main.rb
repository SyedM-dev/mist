require_relative 'utils/bus'
$bus = EventBus.new

require_relative 'window'

# Main window
Window.new.show
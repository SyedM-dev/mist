class EventBus
  def initialize
    # store callbacks with owner: {event => [ {callback:, owner:} ] }
    @events = Hash.new { |h, k| h[k] = [] }
  end

  # Emit an event
  def emit(event, *args)
    @events[event].dup.each do |h|
      h[:callback].call(*args)
    end
  end

  # Subscribe to an event
  def on(event, owner = nil, &callback)
    owner ||= callback.binding.eval("self")
    @events[event] << { callback: callback, owner: owner }
  end

  # For events that return a value (e.g. queries), get the first non-nil response
  def get(event, *args)
    @events[event].dup.each do |h|
      result = h[:callback].call(*args)
      return result unless result.nil?
    end
    nil
  end

  # For events that return multiple values (e.g. queries), get all non-nil responses
  def get_all(event, *args)
    results = []
    @events[event].dup.each do |h|
      result = h[:callback].call(*args)
      results << result unless result.nil?
    end
    results
  end

  def reset
    @events.each do |_, handlers|
      handlers.reject! { |h| h[:owner] != :master }
    end
  end

  def remove_owner(owner)
    @events.each do |_, handlers|
      handlers.reject! { |h| h[:owner] == owner }
    end
  end
end
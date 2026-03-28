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
  def on(event, owner: nil, &callback)
    owner ||= callback.binding.eval("self")
    @events[event] << { callback: callback, owner: owner }
  end

  # Subscribe to an event that should only be called once
  def once(event, owner = nil, &callback)
    wrapper = nil
    wrapper = proc do |*args|
      callback.call(*args)
      off(event, &wrapper)
    end
    on(event, owner: owner, &wrapper)
  end

  # Unsubscribe from an event
  def off(event, &callback)
    @events[event].reject! { |h| h[:callback] == callback }
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

  # Unsubscribe all events for a given owner (e.g. when an object is destroyed)
  def remove_owner(owner)
    @events.each do |event, handlers|
      handlers.reject! { |h| h[:owner] == owner }
    end
  end
end
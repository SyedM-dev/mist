class EventBus
  def initialize
    # store callbacks with owner: {event => [ {callback:, owner:} ] }
    @events = Hash.new { |h, k| h[k] = [] }
    @retrievable_events = {}
  end

  # Emit an event
  def emit(event, *args)
    @events[event].each do |h|
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

  def off(event, &callback)
    @events[event].reject! { |h| h[:callback] == callback }
  end

  # Register a retrievable event (only one allowed)
  def on_retrievable(event, owner = nil, &callback)
    owner ||= callback.binding.eval("self")
    @retrievable_events[event] = { callback: callback, owner: owner }
  end

  # Get data from a retrievable event
  def get(event, *args)
    if @retrievable_events[event]
      @retrievable_events[event][:callback].call(*args)
    else
      nil
    end
  end

  # Unsubscribe from an object's events
  def unlisten_owner(owner)
    @events.each do |event, handlers|
      handlers.reject! { |h| h[:owner] == owner }
    end
    @retrievable_events.delete_if { |_, h| h[:owner] == owner }
  end
end
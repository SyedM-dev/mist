class State
  # This class holds state information
  # for example the player inventory / items
  # also their health, stealth, and memory bars
  # it can handle mouse input for inventory management and item usage
  # it can also handle keyboard input for quick item usage

  def initialize
    @inventory = {
      # basic resources
      :wood => 0,
      :metal => 0,
      :science => 0,

      # nuetrals
      :torch => 0,
      :radar => 0,

      # placeable weapons
      :landmine => 0,
      :shrodingers_mine => 0,
      :event_horizon => 0,

      # attack weapons
      :occams_razor => 0,
      :quantum_bow => 0,
      :blade_of_recursion => 0,

      # utility weapon
      :lorentz_field => 0
    }
    @inventory_selected = :wood
    @upgrades = []
    @health = 100
    @stealth = 100
    @memory = 256

    $bus.on(:obtain) do |type, amount|
      @inventory[type] += amount if @inventory.key?(type)
    end
  end
end
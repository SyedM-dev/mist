class LorentzField < Weapon
  def initialize
    super(
      name: "Lorentz Field",
      description: "A defensive weapon that creates a time distortion field around the user. While active, the field slows down incoming projectiles and enemies, giving the user a chance to react and evade. The field lasts for a short duration and has a cooldown period before it can be used again.",
      image_path: "assets/images/lorentz_field.png",
      cooldown: 5.0,
      damage: 0,
      range: 0,
      area_of_effect: 0
    )
  end

  def activate(user)
  end
end
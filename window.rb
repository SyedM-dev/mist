require 'opengl'
require 'glu'
require 'gosu'

require_relative 'settings/configuration'
require_relative 'utils/utils'
require_relative 'utils/scene'
require_relative 'settings/scene'
require_relative 'menu/scene'
require_relative 'game/scene'

class Window < Gosu::Window
  def initialize
    super *SCREEN_SIZE, resizable: true

    GL.load_lib()
    GLU.load_lib()

    @shader = create_shader

    self.caption = "Mist"

    @scene = Menu.new
    @last_time = Gosu.milliseconds

    $bus.on(:quit_game) { close! }

    $bus.on(:mouse_pos) do
      next mouse_relative(mouse_x, mouse_y)
    end

    $bus.on(:change_scene) do |new_scene|
      @scene.close
      @scene = new_scene
    end

    $bus.on(:shade) do
      shade!
    end
  end

  def create_shader
    vertex_src = File.read("assets/shaders/fog.vert")
    fragment_src = File.read("assets/shaders/fog.frag")

    vs = GL.CreateShader(GL::VERTEX_SHADER)
    GL.ShaderSource(vs, 1, [vertex_src].pack("p"), [vertex_src.size].pack("L"))
    GL.CompileShader(vs)

    fs = GL.CreateShader(GL::FRAGMENT_SHADER)
    GL.ShaderSource(fs, 1, [fragment_src].pack("p"), [fragment_src.size].pack("L"))
    GL.CompileShader(fs)

    program = GL.CreateProgram()
    GL.AttachShader(program, vs)
    GL.AttachShader(program, fs)
    GL.LinkProgram(program)

    program
  end

  def shade!
    scale, offset_x, offset_y = compute_transform

    # As the gl object only works in the Window class we need to use the bus to bring all the data here.
    # This should otherwise be a shader object on (and controlled by) the game scene.

    cam_x, cam_y = $bus.get(:camera_pos) || [0, 0]
    torch_lights = []
    # Only calculate torch lights if the setting is enabled, to save performance
    if $bus.get(:settings, :torches_lightup)
      torches = $bus.get(:nearby_torches,
      [cam_x - SCREEN_SIZE[0], cam_y - SCREEN_SIZE[1], SCREEN_SIZE[0] * 4, SCREEN_SIZE[1] * 4]
      ) || []
      torch_lights = torches.map { |t| [t[0] - cam_x, SCREEN_SIZE[1] - (t[1] - cam_y)] }.flatten
    end

    lorentz_field = $bus.get(:lorentz_field) || 0.0

    torch_lights = torch_lights.first(32)
    torch_count = torch_lights.size / 2
    torch_lights += [0.0] * (32 - torch_lights.size)

    gl do
      GL.UseProgram(@shader)
      GL.Enable(GL::BLEND)
      GL.BlendFunc(GL::SRC_ALPHA, GL::ONE_MINUS_SRC_ALPHA)

      # Pass virtual resolution
      res_loc = GL.GetUniformLocation(@shader, "resolution")
      GL.Uniform2f(res_loc, SCREEN_SIZE[0], SCREEN_SIZE[1])

      # Pass padding offset and scale
      offset_loc = GL.GetUniformLocation(@shader, "offset")
      GL.Uniform2f(offset_loc, offset_x, offset_y)

      scale_loc = GL.GetUniformLocation(@shader, "scale")
      GL.Uniform1f(scale_loc, scale)

      torches_loc = GL.GetUniformLocation(@shader, "torch_lights")
      GL.Uniform2fv(torches_loc, torch_lights.size / 2, torch_lights.pack("f*"))

      num_torches_loc = GL.GetUniformLocation(@shader, "num_torches")
      GL.Uniform1i(num_torches_loc, torch_count)

      time_loc = GL.GetUniformLocation(@shader, "time_sec")
      GL.Uniform1f(time_loc, Gosu.milliseconds / 1000.0)

      lorentz_loc = GL.GetUniformLocation(@shader, "lorentz_field")
      GL.Uniform1f(lorentz_loc, lorentz_field)

      GL.Begin(GL::QUADS)
        GL.Vertex2f(-1, -1)
        GL.Vertex2f( 1, -1)
        GL.Vertex2f( 1,  1)
        GL.Vertex2f(-1,  1)
      GL.End

      GL.UseProgram(0)
    end
  end

  def button_down(id)
    @scene.button_down(id, mouse_relative(mouse_x, mouse_y))
  end

  def update
    now = Gosu.milliseconds
    dt = (now - @last_time) / 1000.0
    @last_time = now

    @scene.update(dt)
  end

  def compute_transform
    scale_x = width.to_f / SCREEN_SIZE[0]
    scale_y = height.to_f / SCREEN_SIZE[1]

    scale = [scale_x, scale_y].min

    if scale_x < scale_y
      offset_x = 0
      offset_y = (height - SCREEN_SIZE[1] * scale) / 2
    else
      offset_x = (width - SCREEN_SIZE[0] * scale) / 2
      offset_y = 0
    end

    [scale, offset_x, offset_y]
  end

  def mouse_relative(sx, sy)
    scale, offset_x, offset_y = compute_transform

    virtual_x = (sx - offset_x) / scale
    virtual_y = (sy - offset_y) / scale

    return nil if virtual_x < 0 || virtual_x > SCREEN_SIZE[0] ||
                  virtual_y < 0 || virtual_y > SCREEN_SIZE[1]

    return [virtual_x, virtual_y]
  end

  def draw
    scale, offset_x, offset_y = compute_transform
    
    Gosu.translate(offset_x, offset_y) do
      Gosu.scale(scale) do
        @scene.draw
      end
    end

    padding_color = Gosu::Color::BLACK
    if offset_y > 0
      # Letterbox: top and bottom
      Gosu.draw_rect(0, 0, width, offset_y, padding_color, Float::INFINITY)
      Gosu.draw_rect(0, height - offset_y, width, offset_y, padding_color, Float::INFINITY)
    else
      # Pillarbox: left and right
      Gosu.draw_rect(0, 0, offset_x, height, padding_color, Float::INFINITY)
      Gosu.draw_rect(width - offset_x, 0, offset_x, height, padding_color, Float::INFINITY)
    end
  end
end
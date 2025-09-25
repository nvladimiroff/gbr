require 'imgui_impl_raylib'

class App

  attr_accessor(:paused)
  attr_writer(:ppu)

  SCALE = 5
  CLOCK_SPEED = 4_194_304
  FPS = 60
  CYCLES_PER_FRAME = CLOCK_SPEED / FPS


  def initialize(**opts)
    @rom = opts[:rom]
    @gb = Gameboy.new(@rom, lcd: self)
    @gb.load
    @debugger = Debugger.new(@gb, self) if opts[:debug]
    @last_frame_time = Time.at(0)
    @paused = false

    # Raylib init
    Raylib.load_lib('libraylib')
    # Dear ImGui Init
    s = Gem::Specification.find_by_name('imgui-bindings')
    shared_lib_path = s.full_gem_path + '/lib/'

    ImGui.load_lib(shared_lib_path + 'imgui.arm64.dylib')

    Raylib.InitWindow(PPU::WIDTH*SCALE, PPU::HEIGHT*SCALE, "GBR - #{@gb.cartridge.title}")
    Raylib.SetWindowState(Raylib::FLAG_VSYNC_HINT)
    image = Raylib.GenImageColor(PPU::WIDTH, PPU::HEIGHT, Raylib::RAYWHITE)
    image.format = Raylib::PIXELFORMAT_UNCOMPRESSED_R8G8B8A8
    @texture = Raylib.LoadTextureFromImage(image)

    ImGui::CreateContext()
    ImGui::StyleColorsDark()

    # Link Raylib and Dear ImGui together.
    ImGui.ImplRaylib_Init()

    io = ImGuiIO.new(ImGui.GetIO())
    io[:Fonts].AddFontDefault()

    # Build texture atlas
    pixels = FFI::MemoryPointer.new :pointer
    width = FFI::MemoryPointer.new :int
    height = FFI::MemoryPointer.new :int
    io[:Fonts].GetTexDataAsRGBA32(pixels, width, height, nil)

    # Upload texture to graphics system
    # [TODO] find standard and safe way to convert RGBA32 array into texture
    image = Raylib.GenImageColor(width.read_int, height.read_int, Raylib::BLUE)
    original_data = image[:data]
    image[:data] = pixels.read_pointer

    texture = Raylib.LoadTextureFromImage(image)
    image[:data] = original_data
    Raylib.UnloadImage(image)

    # Store our identifier
    texture_ptr = FFI::MemoryPointer.new(:uint32)
    texture_ptr.write(:uint32, texture[:id])
    io[:Fonts].SetTexID(texture_ptr.read_int)
  end


  def run
    delta = 0

    StackProf.run(mode: :cpu, out: 'gb.dump', raw: true) do
      loop do
        break if Raylib.WindowShouldClose

        unless @paused
          while delta < CYCLES_PER_FRAME
            @gb.step
            delta += @gb.cycles
          end
          delta -= CYCLES_PER_FRAME
        end

        handle_input
        draw_frame
      end
    end

    ImGui::ImplRaylib_Shutdown()
    ImGui::DestroyContext(nil)

    Raylib.CloseWindow

    @gb.save
  end


  private

    def draw_frame
      Raylib.BeginDrawing()
        # Render the emulator
        Raylib.UpdateTexture(@texture, @ppu.pixels.pack('N*'))
        Raylib.DrawTextureEx(@texture, Raylib::Vector2.create(0, 0), 0.0, SCALE, Raylib::RAYWHITE)

        ImGui::ImplRaylib_NewFrame()
        ImGui::NewFrame()

        @debugger&.draw

        ImGui::Render()
        # Render Dear ImGui to Raylib.
        ImGui::ImplRaylib_RenderDrawData(ImGui::GetDrawData())
      Raylib.EndDrawing()
    end


    def handle_input
      @gb.joypad.press(:right) if Raylib.IsKeyPressed(Raylib::KEY_RIGHT)
      @gb.joypad.press(:left) if Raylib.IsKeyPressed(Raylib::KEY_LEFT)
      @gb.joypad.press(:up) if Raylib.IsKeyPressed(Raylib::KEY_UP)
      @gb.joypad.press(:down) if Raylib.IsKeyPressed(Raylib::KEY_DOWN)

      @gb.joypad.press(:a) if Raylib.IsKeyPressed(Raylib::KEY_Z)
      @gb.joypad.press(:b) if Raylib.IsKeyPressed(Raylib::KEY_X)
      @gb.joypad.press(:start) if Raylib.IsKeyPressed(Raylib::KEY_C)
      @gb.joypad.press(:select) if Raylib.IsKeyPressed(Raylib::KEY_V)

      @gb.joypad.release(:right) if Raylib.IsKeyReleased(Raylib::KEY_RIGHT)
      @gb.joypad.release(:left) if Raylib.IsKeyReleased(Raylib::KEY_LEFT)
      @gb.joypad.release(:up) if Raylib.IsKeyReleased(Raylib::KEY_UP)
      @gb.joypad.release(:down) if Raylib.IsKeyReleased(Raylib::KEY_DOWN)

      @gb.joypad.release(:a) if Raylib.IsKeyReleased(Raylib::KEY_Z)
      @gb.joypad.release(:b) if Raylib.IsKeyReleased(Raylib::KEY_X)
      @gb.joypad.release(:start) if Raylib.IsKeyReleased(Raylib::KEY_C)
      @gb.joypad.release(:select) if Raylib.IsKeyReleased(Raylib::KEY_V)
    end

end

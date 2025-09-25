class Debugger

  attr_reader(:debug_ppu)


  def initialize(gb, app)
    @gb = gb
    @app = app

    @debug_ppu = false
  end


  def draw
    ImGui::SetNextWindowSize(ImVec2.create(300, 400), 2)
    ImGui::Begin('Debugger')

    if ImGui::Button(@app.paused ? 'Resume' : 'Pause')
      @app.paused = !@app.paused
    end
    ImGui::SameLine()
    ImGui::Text("FPS: #{Raylib.GetFPS()}")

    ImGui::Spacing()

    if ImGui::BeginTabBar('Debugger', 0)
      if ImGui::BeginTabItem('CPU')
        draw_cpu_info
        ImGui::EndTabItem()
      end
      if ImGui::BeginTabItem('Interrupts')
        draw_interrupt_info
        ImGui::EndTabItem()
      end
      if ImGui::BeginTabItem('PPU')
        draw_ppu_info
        ImGui::EndTabItem()
      end
      if ImGui::BeginTabItem('OAM')
        draw_oam_info
        ImGui::EndTabItem()
      end
      if ImGui::BeginTabItem('Eval')
        draw_eval_widget
        ImGui::EndTabItem()
      end

      ImGui::EndTabBar();
    end

    ImGui::End()

    draw_ppu_tile_lines if @debug_ppu
  end


  private

    def draw_cpu_info
      instruction = CPU::Opcodes::MAPPING[@gb.cpu.op].join(' ')
      ImGui::Text("OP: #{instruction} (#{@gb.cpu.op.to_hex})")
      ImGui::Spacing()
      ImGui::Text("PC: #{@gb.cpu.pc.to_hex}")
      ImGui::Text("SP: #{@gb.cpu.sp.to_hex}")

      %i(a b c d e h l f).each do |reg|
        ImGui::Text("#{reg}: #{@gb.cpu.send(reg).to_hex}")
      end
    end


    def draw_interrupt_info
      enabled = []
      enabled << :vblank if @gb.cpu.ie[0] == 1
      enabled << :lcd_stat if @gb.cpu.ie[1] == 1
      enabled << :timer if @gb.cpu.ie[2] == 1
      enabled << :serial if @gb.cpu.ie[3] == 1
      enabled << :joypad if @gb.cpu.ie[4] == 1

      pending = []
      pending << :vblank if @gb.cpu.if[0] == 1
      pending << :lcd_stat if @gb.cpu.if[1] == 1
      pending << :timer if @gb.cpu.if[2] == 1
      pending << :serial if @gb.cpu.if[3] == 1
      pending << :joypad if @gb.cpu.if[4] == 1

      ImGui::Text("Enabled: #{enabled.join(' ')}")
      ImGui::Text("Pending: #{pending.join(' ')}")
    end


    def draw_ppu_info
      ImGui::Text('Debug mode')
      ImGui::SameLine()
      if ImGui::Button(@debug_ppu ? 'Disable' : 'Enable')
        @debug_ppu = !@debug_ppu
      end

      ImGui::Spacing()
      ImGui::Text("LY: #{@gb.ppu.ly}")
      ImGui::Text("SCY: #{@gb.ppu.scy}")
      ImGui::Text("SCX: #{@gb.ppu.scx}")
      ImGui::Text("WY: #{@gb.ppu.wy}")
      ImGui::Text("WX: #{@gb.ppu.wx}")
      ImGui::Spacing()
      ImGui::Text("LCD enabled: #{@gb.ppu.lcdc[7] == 1}")
      ImGui::Text("BG/window enabled: #{@gb.ppu.lcdc[0] == 1}")
      ImGui::Text("Window enabled: #{@gb.ppu.lcdc[5] == 1}")
      ImGui::Text("Sprites enabled: #{@gb.ppu.lcdc[1] == 1}")
      ImGui::Spacing()
      ImGui::Text("BG tilemap start: #{@gb.ppu.lcdc[3] == 1 ? 0x9800.to_hex : 0x9C00.to_hex}")
      ImGui::Text("Window tilemap start: #{@gb.ppu.lcdc[6] == 1 ? 0x9800.to_hex : 0x9C00.to_hex}")
      ImGui::Text("BG/Window tile data mode: #{@gb.ppu.lcdc[4] == 1 ? 'unsigned' : 'signed'}")
      ImGui::Spacing()
      ImGui::Text("Sprite size: #{@gb.ppu.lcdc[2] == 0 ? '8x8' : '8x16'}")
    end


    def draw_oam_info
      40.times do |sprite_index|
        sprite = @gb.ppu.send(:read_sprite, sprite_index) # TODO: don't call a private method.

        ImGui::Text("Sprite #{sprite_index}")
        ImGui::Text("X, Y: #{sprite[:x]}, #{sprite[:y]}")
        ImGui::Text("Tile: #{sprite[:tile]}")
        ImGui::Text("Attributes: #{sprite[:attributes].to_s(2)}")
        ImGui::Spacing()
      end
    end


    def draw_eval_widget
      @expr = FFI::MemoryPointer.new(:char, 128)
      if ImGui::InputText('Code', @expr, @expr.size, ImGuiInputTextFlags_EnterReturnsTrue)
        begin
          @result = @gb.instance_eval(@expr.read_string)
        rescue => e
          @result = e
        end
      end

      ImGui::Text("Result: #{@result}")
    end


    def draw_ppu_tile_lines
      (PPU::WIDTH*App::SCALE / 8*App::SCALE).times.map { |x| x*8*App::SCALE }.each do |x|
        Raylib.DrawLine(x, 0, x, PPU::HEIGHT * App::SCALE, Raylib::RED)
      end

      (PPU::HEIGHT*App::SCALE / 8*App::SCALE).times.map { |y| y*8*App::SCALE }.each do |y|
        Raylib.DrawLine(0, y, PPU::WIDTH * App::SCALE, y, Raylib::RED)
      end
    end

end

class Debugger


  def initialize(gb, app)
    @gb = gb
    @app = app
  end


  def draw
    ImGui::SetNextWindowSize(ImVec2.create(300, 400), 2)
    ImGui::Begin('Debugger')

    if ImGui::Button(@app.paused ? 'Resume' : 'Pause')
      @app.paused = !@app.paused
    end

    ImGui::Spacing()

    if ImGui::BeginTabBar('Debugger', 0)
      if ImGui::BeginTabItem('CPU')
        instruction = CPU::Opcodes::MAPPING[@gb.cpu.op].join(' ')
        ImGui::Text("OP: #{instruction} (#{@gb.cpu.op.to_hex})")
        ImGui::Spacing()

        %i(a b c d e h l f).each do |reg|
          ImGui::Text("#{reg}: #{@gb.cpu.send(reg).to_hex}")
        end
        ImGui::EndTabItem()
      end
      if ImGui::BeginTabItem('PPU')
        ImGui::Text("LY: #{@gb.ppu.ly}")
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
        ImGui::EndTabItem()
      end

      ImGui::EndTabBar();
    end

    ImGui::End()
  end

end

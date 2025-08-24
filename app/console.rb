class Console

  attr_reader(:out)


  def initialize
    @out = $stdout
  end


  def display_until_quit
    in_alternate_screen {
      yield(self)
    }
  end


  def write(text)
    @out.write(text)
  end


  def line(text)
    write(text + "\n")
  end


  def row(*cells)
    @out.write(cells.join("\t")+"\n")
  end


  def section(title=nil)
    @out.write(bold(title) + "\n\n") if title
    yield
    @out.write("\n\n")
  end


  private

    def escape(t)
      "\x1b#{t}"
    end


    def csi(t)
      escape("[#{t}")
    end


    def osc(t)
      escape("]#{t}")
    end


    def in_alternate_screen
      enable_alternate_screen
      hide_cursor
      reset_cursor
      yield
      $stdin.getch
      restore_cursor
      restore_original_screen
    end


    def reset_cursor
      @out.write(csi('1;1H'))
    end


    def hide_cursor
      @out.write(csi('?1049h'))
    end


    def restore_cursor
      @out.write(csi('?25h'))
    end


    def enable_alternate_screen
      @out.write(csi('?25l'))
    end


    def restore_original_screen
      @out.write(csi('?1049l'))
    end


    def bold(text)
      csi('1m') + text + csi('0m')
    end

end

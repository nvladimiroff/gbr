class Profiler

  INSTRUCTIONS = 10_000_000


  def initialize(**opts)
    @rom = opts[:rom]
    @gb = Gameboy.new(@rom, lcd: HeadlessLCD.new)
  end


  def run
    start = Time.now
    StackProf.run(mode: :cpu, out: 'gb.dump', raw: true) do
      INSTRUCTIONS.times do
        @gb.step
      end
    end
    duration = Time.now - start

    puts "Ran at #{INSTRUCTIONS/duration} inst/s"
  end

end

# silence warnings from gems
old = $VERBOSE
$VERBOSE = nil
require 'bundler/setup'
Bundler.require(:default)
$VERBOSE = old


$ROOT = Pathname.new(__dir__ + '/..')
loader = Zeitwerk::Loader.new
loader.push_dir($ROOT.join('app').to_s)
loader.inflector.inflect(
  'cpu' => "CPU",
  'mmu' => "MMU",
  'ppu' => 'PPU',
  'raylib_ppu' => 'RaylibPPU'
)
loader.setup
SemanticLogger.add_appender(io: $stdout, level: :trace, formatter: :color)
SemanticLogger.default_level = :warn
$logger = SemanticLogger['Gameboy']

module ToHex
  def to_hex
    "0x#{to_s(16)}"
  end
end

Integer.include(ToHex)

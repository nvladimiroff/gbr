require 'bundler/setup'

Bundler.require(:default)

$ROOT = Pathname.new(__dir__)
loader = Zeitwerk::Loader.new
loader.push_dir($ROOT.join('../app').to_s)
loader.setup


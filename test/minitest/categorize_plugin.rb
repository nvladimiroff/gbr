module Minitest

  class CategoryReporter < AbstractReporter

    def initialize(options)
      @groups = {}
    end


    def record(result)
      instruction = result.name[/test_(.*)_[0-9A-F]*/, 1]
      @groups[instruction] ||= {}
      @groups[instruction][:passed] ||= 0
      @groups[instruction][:failed] ||= 0

      if result.passed?
        @groups[instruction][:passed] += 1
      else
        @groups[instruction][:failed] += 1
      end
    end


    def report
      @groups.sort_by { |k, v| k }.each do |instruction, result|
        percentage = result[:passed] / (result[:passed] + result[:failed]).to_f
        puts "#{instruction}: #{percentage*100}%"
      end

      failed_total = @groups.sum { |k, v| v[:failed] }
      passed_total = @groups.sum { |k, v| v[:passed] }
      total_percentage = passed_total / (passed_total + failed_total).to_f
      puts "TOTAL: #{total_percentage*100}% "
    end

  end


  def self.plugin_categorize_options(opts, options)
    opts.on('--categorize', 'Categorize single step tests') do
      options[:single_step] = true
    end
  end


  def self.plugin_categorize_init(options)
    self.reporter << CategoryReporter.new(options) if options[:single_step]
  end

end

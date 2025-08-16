#!/usr/bin/env ruby

require 'json'

class OpcodeGenerator

  def run
    opcodes = JSON.load_file('Opcodes.json')
    opcodes['unprefixed'].each do |key, value|
      args = value['operands']
      op = format_op(value['mnemonic'])
      case args.length
      when 0
        puts "#{key} => (#{op}),"
      when 1
        arg = format_arg(args.first)
        puts "#{key} => (#{op} #{arg}),"
      when 2
        arg1 = format_arg(args.first)
        arg2 = format_arg(args.last)
        puts "#{key} => (#{op} #{arg1}, #{arg2}),"
      end
    end
  end

  private

    def format_arg(arg)
      name = arg['name'].downcase
      name = case name
      when 'a8', 'e8'
        'n8'
      when 'a16', 'e16'
        'n16'
      else
        name
      end

      if arg['immediate']
        "#{name}"
      else
        "[#{name}]"
      end
    end


    def format_op(op)
      case op
      when 'AND'
        # Reserved word :(
        'and_'
      when 'OR'
        # Reserved word :(
        'or_'
      else
        op.downcase
      end
    end

end

OpcodeGenerator.new.run

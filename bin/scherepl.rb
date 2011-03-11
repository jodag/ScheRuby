#!/usr/bin/env ruby

require 'readline'
require 'lib/scheruby'

env_frame = EnvFrame.new

# For tab completion
SPECIAL_FORMS = ['let', 'if', 'define', 'lambda', 'set!', 'quote', 'self']

# This provides tab completion for symbols currently defined, as well as SPECIAL_FORMS
Readline.completion_proc = proc do |begins_with|
  (env_frame.defined_symbols.map { |k| k.to_s } + SPECIAL_FORMS).select { |abbrev| abbrev[0..(begins_with.length - 1)] == begins_with}
end

loop do
  code = Readline.readline('> ', true)
  # Exit on Ctrl-Z (Ctrl-D on Windows)
  break if code.nil?
  
  while ! ScheRuby.well_formed?(code)
    # code is not well formed, so most likely they still need to type
    next_line = Readline.readline('', true)
    # Stop the multiline parse on Ctrl-Z (Ctrl-D on Windows)
    break if next_line.nil?
    code += next_line
  end
  
  begin
    puts ScheRuby.scheme!(code, env_frame).inspect
  rescue
    puts $!.inspect
    puts $!.backtrace[0..50]
  end
end
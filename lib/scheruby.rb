$:.unshift File.dirname(__FILE__)

require 'scheruby/ScheRubyGrammarLexer'
require 'scheruby/ScheRubyGrammarParser'
require 'scheruby/cons'
require 'scheruby/env_frame'
require 'scheruby/evaluator'

include ScheRuby

module ScheRuby

  # Parses +code+ and evaluates it at the top-level
  def self.scheme!(code, env_frame = EnvFrame.new)
    scheme_parse(code).evaleach!(binding, env_frame)
  end

  # Parses +code+ and returns a Cons list of its datums
  def self.scheme_parse(code)
    ScheRubyGrammarParser.new(code).datums
  end
  
  def self.well_formed?(code)
    begin
      ScheRubyGrammarParser.new(code).datums
      return true
    rescue
      return false
    end
  end

end
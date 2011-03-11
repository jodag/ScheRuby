#!/usr/bin/env ruby

require 'lib/scheruby'
env_frame = EnvFrame.new
ScheRuby.scheme!(ARGF.read, env_frame)
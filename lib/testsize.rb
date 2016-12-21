#!/usr/bin/env ruby

require_relative 'file_sizes'
require 'filemagic'

mime = FileMagic.open(:mime_type, :mime_encoding).file(ARGV[0])
fail 'Unrecognized file' if not $file_size_functions.include?(mime)
puts send($file_size_functions[mime], File.binread(ARGV[0]))


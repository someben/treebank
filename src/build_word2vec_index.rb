#!/usr/bin/env ruby
<<'EOF_LICENSE'
Copyright 2013 Ben Gimpert (ben@somethingmodern.com)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
EOF_LICENSE

require 'matrix'
require 'scanf'

require 'rubygems'
require 'gsl'

require '_logger'

def build_random_projections(rng, n, num_dims)
  proj_vs = []
  n.times do
    rand_a = []
    num_dims.times { rand_a << rng.gaussian }
    proj_vs << Vector.elements(rand_a)
  end
  proj_vs
end

def build_binary_word2vec_index(io, proj_vs)
  idx = {}
  header_line = io.gets
  num_words, layer1_size = header_line.scanf("%i %i")
  Logger.debug("word2vec database has #{num_words.to_comma_s} words & #{layer1_size.to_comma_s} layer size.") if Logger.debug?
  num_words.times do |i|
    word_pos = io.pos
    word = ''
    until io.eof?
      word_ch = io.read(1)
      break if word_ch =~ /\s/
      word += word_ch
    end
    vals_bin = io.read(4 * layer1_size)
    vals = vals_bin.unpack("f#{layer1_size}")
    v = Vector.elements(vals)

    hash_s = "0b"
    proj_vs.each_index do |i|
      proj_v = proj_vs[i]
      proj_bit = ((proj_v.inner_product(v) >= 0) ? 1 : 0)
      hash_s += proj_bit.to_s
    end
    hash = eval(hash_s)

    Logger.debug("Word ##{(i+1).to_comma_s} of #{num_words.to_comma_s} \"#{word}\" at #{word_pos} position in database w/ #{hash} hash.") if Logger.debug?
    idx[word] = {
      "pos" => word_pos,
      "lsh" => hash,
    }
  end
  idx
end

rng = GSL::Rng.alloc
rng.gaussian

num_hashes = 10  # about 1,400 vectors per bucket
proj_vs = build_random_projections(rng, num_hashes, 1_000)

path = File.expand_path(ARGV.first)
File.open(path, "r") do |in_f|
  idx = build_binary_word2vec_index(in_f, proj_vs)
  File.open(path + ".idx", "w+") { |out_f| out_f.puts(idx.to_json) }
end


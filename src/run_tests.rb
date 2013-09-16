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

require 'test/unit'

require 'rubygems'
require 'graphviz'

require '_logger'
require '_stanford_sentiment_treebank'

class StanfordSentimentTreebankTests <Test::Unit::TestCase
  include Test::Unit::Assertions

  def test_phrases
    treebank = StanfordSentimentTreebank::StanfordSentimentTreebank.new
    treebank.each_phrase_map do |phrase_map|
      Logger.verbose("Phrase map #{phrase_map.inspect} found.") #if Logger.verbose?
      assert_equal(69, phrase_map.length)
      assert_equal(phrase_map["The Rock is destined to be the 21st Century 's new `` Conan '' and that he 's going to make a splash even greater than Arnold Schwarzenegger , Jean-Claud Van Damme or Steven Segal ."], 0.69444)
      assert_equal(phrase_map["even greater"], 0.54167)
      assert_equal(phrase_map["destined"], 0.58333)
      break
    end
  end

end


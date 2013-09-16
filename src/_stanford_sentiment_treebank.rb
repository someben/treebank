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

module StanfordSentimentTreebank

  class StanfordSentimentTreebank

    DATA_DIR = File.expand_path("~/stanfordSentimentTreebank")
    IS_GRAPHING = true
    IS_GRAPHING_NODES_NUMBERED = true

    def initialize(init_max_num = nil)
      @max_num = init_max_num
      @sent_map = read_sentiment_map
    end

    def build_phrase_node_nums(node_map, phrase_toks, parent_node_num)
      return [parent_node_num] if node_map[parent_node_num].nil? || node_map[parent_node_num].empty?
      Logger.verbose("Building the leaf node numbers in #{parent_node_num} node phrase.") if Logger.verbose?
      phrase_node_nums = []
      node_map[parent_node_num].sort.each do |child_node_num|
        if child_node_num <= phrase_toks.length
          phrase_node_nums << child_node_num
        else
          phrase_node_nums += build_phrase_node_nums(node_map, phrase_toks, child_node_num)
        end
      end
      phrase_node_nums
    end

    def build_phrase(node_map, phrase_toks, parent_node_num)
      phrase_node_nums = build_phrase_node_nums(node_map, phrase_toks, parent_node_num)
      raise "Duplicate token nodes in \"#{phrase_toks}\" phrase" unless phrase_node_nums.length == phrase_node_nums.uniq.length
      phrase_node_nums.sort.uniq.map { |node_num| phrase_toks[node_num-1] }.join(" ")
    end

    def confirm_graph_node(gv, gv_node_map, node_map, phrase_toks, node_num)
      return gv_node_map[node_num] if gv_node_map[node_num]

      phrase = build_phrase(node_map, phrase_toks, node_num)
      raise "Could not find sentiment for \"#{phrase}\" phrase" unless @sent_map.has_key?(phrase)
      sent = @sent_map[phrase]
      sent_shade = (sent * 255).to_i
      sent_color = sprintf("#%02x%02x%02x", sent_shade, sent_shade, sent_shade)
      Logger.debug("Using \"#{sent_color}\" sentiment color for \"#{phrase}\" phrase.") if Logger.debug?

      gv_node = gv.add_node("id#{node_num}")
      gv_node_label = if node_num.zero?
        "(root)"
      elsif (1..phrase_toks.length).member?(node_num)
        phrase_toks[node_num-1]
      else
        ""
      end
      gv_node_label += " ##{node_num}" if IS_GRAPHING_NODES_NUMBERED
      gv_node[:label] = gv_node_label
      gv_node[:style] = "filled"
      gv_node[:fillcolor] = sent_color
      gv_node_map[node_num] = gv_node

      if node_map[node_num] && (! node_map[node_num].empty?)
        Logger.verbose("Adding #{node_map[node_num].length.to_comma_s} children under #{node_num} new node.") if Logger.verbose?
        gv_node[:group] = "parent"
        node_map[node_num].sort.each do |child_node_num|
          child_gv_node = confirm_graph_node(gv, gv_node_map, node_map, phrase_toks, child_node_num)
          gv.add_edge(gv_node, child_gv_node)
        end
      elsif (2..phrase_toks.length).member?(node_num)
        Logger.debug("Added token leaf #{node_num} new node.") if Logger.debug?
        gv_node[:group] = "leaf"
        prev_tok_gv_node = confirm_graph_node(gv, gv_node_map, node_map, phrase_toks, node_num-1)
        invis_edge = gv.add_edge(prev_tok_gv_node, gv_node)
        invis_edge[:style] = "invis"
      end
      gv_node
    end

    def write_graph(node_map, phrase_toks, desc, svg_path)
      gv = GraphViz.new(:G, :type => :graph)
      gv[:rankdir] = "LR"
      gv[:label] = desc

      Logger.debug("Saving #{node_map.inspect} as a graph.") if Logger.debug?
      gv_node_map = {}
      node_map.keys.sort.each { |node_num| confirm_graph_node(gv, gv_node_map, node_map, phrase_toks, node_num) }
      gv.output(:svg => svg_path)
    end

    def read_sentiment_map
      dict_map = {}
      File.open("#{DATA_DIR}/dictionary.txt", "r") do |dict_io|
        until dict_io.eof?
          dict_line = dict_io.gets.strip
          dict_phrase, dict_id = dict_line.split("|")
          dict_id = dict_id.to_i
          dict_map[dict_id] = dict_phrase
        end
      end
      Logger.debug("Read #{dict_map.length.to_comma_s} entries from the dictionary file.") if Logger.debug?

      sent_map = {}
      File.open("#{DATA_DIR}/sentiment_labels.txt", "r") do |sent_io|
        until sent_io.eof?
          sent_line = sent_io.gets.strip
          next if sent_line == "phrase ids|sentiment values"
          dict_id, sent = sent_line.split("|")
          dict_id = dict_id.to_i
          sent = sent.to_f

          raise "No phrase for #{dict_id} dictionary ID" unless dict_map.has_key?(dict_id)
          dict_phrase = dict_map[dict_id]
          sent_map[dict_phrase] = sent
        end
      end
      Logger.debug("Read #{sent_map.length.to_comma_s} sentiment values from the sentiment file.") if Logger.debug?
      sent_map
    end

    def each_node_map
      result = nil
      Logger.debug("Reading the parse trees.") if Logger.debug?
      File.open("#{DATA_DIR}/SOStr.txt", "r") do |tok_io|
        File.open("#{DATA_DIR}/STree.txt", "r") do |tree_io|
          doc_i, phrase_i = 0, 0
          until tok_io.eof?
            tok_line = tok_io.gets.strip
            raise "End of tree file reached early" if tree_io.eof?
            tree_line = tree_io.gets.strip

            phrase_toks = tok_line.split("|")
            tree_els = tree_line.split("|")
            Logger.debug("For ##{(doc_i+1).to_comma_s} document, found #{phrase_toks.length.to_comma_s} tokens & #{tree_els.length.to_comma_s} nodes.") if Logger.debug?

            node_map = {}
            tree_els.each_index do |node_i|
              child_node_num = node_i+1
              node_map[child_node_num] = [] unless node_map.has_key?(child_node_num)
              parent_node_num = tree_els[node_i].to_i
              node_map[parent_node_num] = [] unless node_map.has_key?(parent_node_num)
              node_map[parent_node_num] << child_node_num
              Logger.verbose("Child node ##{child_node_num} now has #{parent_node_num} parent & #{node_map[parent_node_num].inspect} siblings.") if Logger.verbose?
            end

            if IS_GRAPHING
              svg_path_i_s = sprintf("%08i", doc_i+1)
              desc = "Stanford Treebank Phrase ##{(doc_i+1).to_comma_s},\n\"#{tok_line}\""
              write_graph(node_map, phrase_toks, desc, Dir.tmpdir + File::SEPARATOR + "/stanford_treebank_phrase#{svg_path_i_s}.svg")
            end

            result = yield(node_map, phrase_toks)
            doc_i += 1
            break if (! @max_num.nil?) && (doc_i >= @max_num)
          end
        end
      end
      result
    end

    def each_phrase_map
      phrase_i = 0
      each_node_map do |node_map, phrase_toks|
        phrase_map = {}
        node_map.keys.sort.each do |parent_node_num|
          phrase = build_phrase(node_map, phrase_toks, parent_node_num)
          raise "Could not find sentiment for \"#{phrase}\" phrase" unless @sent_map.has_key?(phrase)
          sent = @sent_map[phrase]
          Logger.verbose("Phrase #{(phrase_i+1).to_comma_s} \"#{phrase}\" has #{sent} sentiment.") if Logger.verbose?
          phrase_map[phrase] = sent
          phrase_i += 1
        end
        yield(phrase_map)
      end
    end

    def each_node_map_split(node_map, phrase_toks, from_node_num = 0, &block) 
      return nil if node_map[from_node_num].nil? || node_map[from_node_num].empty?
      child_node_nums = node_map[from_node_num]
      child_node_nums.each { |child_node_num| each_node_map_split(node_map, phrase_toks, child_node_num, &block) }
      block.call(from_node_num, child_node_nums)
    end

    def each_node_map_leaf_trigram(node_map, phrase_toks, from_node_num = 0)
      each_node_map_split(node_map, phrase_toks, from_node_num) do |node_num, child_node_nums|
        next unless child_node_nums.length == 2
        child1_node_num, child2_node_num = child_node_nums
        child1_children = node_map[child1_node_num]
        child2_children = node_map[child2_node_num]
        next unless (child1_children.nil? || child1_children.empty?) && (child2_children.nil? || child2_children.empty?)
        yield(node_num, child1_node_num, child2_node_num)
      end
    end

  end

end


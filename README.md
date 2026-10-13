# treebank

Ruby tools for the [Stanford Sentiment Treebank](https://nlp.stanford.edu/sentiment/)
(SST, Socher et al. 2013) and for indexing binary word2vec models. Written in 2013,
the year both came out.

The SST labels every phrase in 11,855 movie-review sentences with a sentiment
score between 0 (very negative) and 1 (very positive). It ships as five
pipe-delimited files plus a parent-pointer encoding of each parse tree. This
library joins those files back into trees you can walk.

## What's here

| File | What it does |
|---|---|
| `src/_stanford_sentiment_treebank.rb` | Loads the SST, rebuilds each sentence's parse tree, and yields phrase-to-sentiment maps. Optionally renders every tree to SVG with nodes shaded by sentiment. |
| `src/build_word2vec_index.rb` | Reads a binary word2vec `.bin` file and writes a JSON index of each word's byte offset and a 10-bit locality-sensitive hash (random hyperplane projections), so you can seek to one vector or find near neighbours without loading the model into memory. |
| `src/run_tests.rb` | Test::Unit checks against the first SST sentence. |

## Setup

```sh
gem install ruby-graphviz gsl     # gsl needs the GNU Scientific Library: apt install libgsl-dev
curl -LO https://nlp.stanford.edu/~socherr/stanfordSentimentTreebank.zip
unzip stanfordSentimentTreebank.zip -d ~
```

The loader expects the data in `~/stanfordSentimentTreebank/` (`dictionary.txt`,
`sentiment_labels.txt`, `SOStr.txt`, `STree.txt`). Change `DATA_DIR` to move it.

## Usage

```ruby
$LOAD_PATH.unshift "src"
require "_logger"
require "_stanford_sentiment_treebank"

tb = StanfordSentimentTreebank::StanfordSentimentTreebank.new(10)  # first 10 sentences

tb.each_phrase_map do |phrases|
  phrases.each { |phrase, score| puts format("%.3f  %s", score, phrase) }
end
```

For the first sentence this prints 69 phrases, including
`0.583  destined` and `0.542  even greater`.

To walk the trees yourself, `each_node_map` yields `(node_map, tokens)`, where
`node_map` maps each node number to its children and node 0 is the root.
`each_node_map_leaf_trigram` yields every parent whose two children are both
words, which is the smallest unit where composition changes sentiment.

With `IS_GRAPHING = true` (the default), each tree is also written to your temp
directory as `stanford_treebank_phraseNNNNNNNN.svg`, grey-shaded from black
(negative) to white (positive). Set it to `false` for bulk runs.

### word2vec index

```sh
ruby -I src src/build_word2vec_index.rb GoogleNews-vectors-negative300.bin
# writes GoogleNews-vectors-negative300.bin.idx
```

The projection dimension is set to 1,000 in the script; change it to the
model's layer size (300 for the GoogleNews vectors) before running.

## Tests

```sh
ruby -I src src/run_tests.rb
```

## License

Apache 2.0. Ben Gimpert, [Something Modern](https://somethingmodern.com).
More at [blog.someben.com](https://blog.someben.com/).

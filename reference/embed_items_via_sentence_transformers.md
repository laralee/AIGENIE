# Embed Items Using Sentence-Transformers Library

Embed Items Using Sentence-Transformers Library

## Usage

``` r
embed_items_via_sentence_transformers(
  embedding.model,
  items,
  hf.token = NULL,
  silently = FALSE
)
```

## Arguments

- embedding.model:

  HuggingFace / sentence-transformers model name

- items:

  Data frame with 'statement' and 'ID' columns

- hf.token:

  Optional HuggingFace API token (used to log in for gated models)

- silently:

  Logical. Suppress progress messages?

## Value

A list with 'embeddings' matrix and 'success' flag

# Embed Items Using HuggingFace Inference API

Embed Items Using HuggingFace Inference API

## Usage

``` r
embed_items_huggingface_api(embedding.model, hf.token, items, silently = FALSE)
```

## Arguments

- embedding.model:

  HuggingFace model name

- hf.token:

  Optional HuggingFace API token

- items:

  Data frame with 'statement' and 'ID' columns

- silently:

  Logical. Suppress progress messages?

## Value

A list with 'embeddings' matrix and 'success' flag

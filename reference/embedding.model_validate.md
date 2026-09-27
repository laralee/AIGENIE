# Validate Embedding Model

Validates that the embedding model is one of the supported OpenAI, Jina
AI, or HuggingFace models.

## Usage

``` r
embedding.model_validate(embedding.model, provider = "auto", hf.token = NULL)
```

## Arguments

- embedding.model:

  A string.

- provider:

  One of "auto", "openai", "jina", "huggingface", or "local". With
  "auto" (default), the provider is detected from the model name.

- hf.token:

  Optional HuggingFace token. Required for gated models such as
  google/embeddinggemma.

## Value

Character string naming the provider: "openai", "jina", or "huggingface"
when auto-detected.

## Details

Allowed OpenAI models:

- "text-embedding-3-small"

- "text-embedding-3-large"

- "text-embedding-ada-002"

Allowed Jina AI models:

- jina-embeddings-v4, jina-embeddings-v3, jina-clip-v2

- jina-code-embeddings-1.5b, jina-code-embeddings-0.5b

- jina-embeddings-v2-base-en/zh/de/es/code, jina-embeddings-v2-small-en

Confirmed HuggingFace models (other HuggingFace models are allowed with
a warning):

- BAAI/bge series (bge-small-en-v1.5, bge-base-en-v1.5,
  bge-large-en-v1.5)

- thenlper/gte series (gte-small, gte-base, gte-large)

- google/embeddinggemma series (requires `hf.token`)

- sentence-transformers/all-MiniLM-L6-v2

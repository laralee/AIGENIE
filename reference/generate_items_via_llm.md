# Generate Items via LLM

Generates scale items using the specified LLM provider. Supports OpenAI,
Groq, and Anthropic models (local GGUF models are handled by
[`generate_items_via_local_llm()`](https://laralee.github.io/AIGENIE/reference/generate_items_via_local_llm.md)).

## Usage

``` r
generate_items_via_llm(
  main.prompts,
  system.role,
  model,
  top.p,
  temperature,
  adaptive,
  silently,
  groq.API,
  openai.API,
  anthropic.API = NULL,
  target.N
)
```

## Arguments

- main.prompts:

  Named list of prompts for each item type

- system.role:

  Character string defining the system role

- model:

  Character string specifying the model

- top.p:

  Numeric or NULL. Nucleus sampling parameter (not sent when NULL)

- temperature:

  Numeric or NULL. Sampling temperature (not sent when NULL)

- adaptive:

  Logical. Use adaptive generation with previous items?

- silently:

  Logical. Suppress progress messages?

- groq.API:

  Optional Groq API key

- openai.API:

  Optional OpenAI API key

- anthropic.API:

  Optional Anthropic API key

- target.N:

  Named list of target item counts per type

## Value

A list with 'items' data frame and 'successful' flag. Generation stops
with an error on the first API error that mentions `temperature` or
`top_p`, since retrying such a request cannot succeed.

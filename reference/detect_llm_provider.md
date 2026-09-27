# Detect LLM Provider from Model Name

Determines which API provider to use based on the model name.

## Usage

``` r
detect_llm_provider(
  model,
  groq.API = NULL,
  openai.API = NULL,
  hf.token = NULL,
  anthropic.API = NULL
)
```

## Arguments

- model:

  Character string specifying the model name

- groq.API:

  Optional Groq API key (if provided, prefers Groq for compatible
  models)

- openai.API:

  Optional OpenAI API key

- hf.token:

  Optional HuggingFace token

- anthropic.API:

  Optional Anthropic API key

## Value

A list with `provider` (`"openai"`, `"anthropic"`, `"groq"`, or
`"huggingface"`) and `model` (the model name without a provider prefix)

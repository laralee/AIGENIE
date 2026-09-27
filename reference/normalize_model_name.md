# Normalize and Validate Model Names with Provider Prefixes

Converts model names to the standardized format: Provider/model-name
Maintains backward compatibility with existing model names.

## Usage

``` r
normalize_model_name(
  model,
  groq.API = NULL,
  openai.API = NULL,
  anthropic.API = NULL,
  silently = FALSE
)
```

## Arguments

- model:

  Character string of the model name

- groq.API:

  Optional Groq API key

- openai.API:

  Optional OpenAI API key

- anthropic.API:

  Optional Anthropic API key

- silently:

  Logical, suppress messages and warnings

## Value

List with `model` (the normalized, provider-prefixed model name) and
`provider` (`"openai"`, `"groq"`, or `"anthropic"`)

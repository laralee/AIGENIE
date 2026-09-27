# Generate Text Using Anthropic Messages API

Generates text using Anthropic's Claude models via the /v1/messages
endpoint. Uses the requests library directly (no extra SDK dependency).

## Usage

``` r
generate_text_anthropic(
  prompt,
  system.role = NULL,
  model = "claude-sonnet-4-5-20250929",
  temperature = NULL,
  top.p = NULL,
  max_tokens = 2048,
  api_key
)
```

## Arguments

- prompt:

  Character string with the user prompt

- system.role:

  Character string with the system prompt

- model:

  Character string specifying the Claude model

- temperature:

  Numeric or NULL. Sampling temperature (0-1; not sent when NULL)

- top.p:

  Numeric or NULL. Nucleus sampling parameter (0-1; not sent when NULL)

- max_tokens:

  Integer. Maximum tokens to generate

- api_key:

  Anthropic API key

## Value

Character string with the generated text

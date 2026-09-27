# Generate Text Using Any Supported LLM Provider

Unified interface for text generation that automatically routes to the
appropriate provider (OpenAI, Groq, Anthropic, or HuggingFace).

## Usage

``` r
generate_text_llm(
  prompt,
  system.role = NULL,
  model = "gpt-4o",
  temperature = NULL,
  top.p = NULL,
  max_tokens = 2048,
  openai.API = NULL,
  groq.API = NULL,
  anthropic.API = NULL,
  hf.token = NULL
)
```

## Arguments

- prompt:

  Character string with the user prompt

- system.role:

  Character string with the system prompt

- model:

  Character string specifying the model

- temperature:

  Numeric or NULL. Sampling temperature (0-2). Not sent when NULL.

- top.p:

  Numeric or NULL. Nucleus sampling parameter (0-1). Not sent when NULL.

- max_tokens:

  Integer. Maximum tokens to generate

- openai.API:

  Optional OpenAI API key

- groq.API:

  Optional Groq API key

- anthropic.API:

  Optional Anthropic API key

- hf.token:

  Optional HuggingFace token

## Value

Character string with the generated text. If the provider returns an
error that mentions `temperature` or `top_p`, the error message is
extended with a hint to leave these parameters as NULL.

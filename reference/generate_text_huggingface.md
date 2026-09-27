# Generate Text Using HuggingFace Inference API

Generate Text Using HuggingFace Inference API

## Usage

``` r
generate_text_huggingface(
  prompt,
  system.role = NULL,
  model,
  temperature = NULL,
  top.p = NULL,
  max_tokens = 2048,
  hf_token = NULL
)
```

## Arguments

- prompt:

  Character string with the user prompt

- system.role:

  Character string with the system prompt

- model:

  Character string specifying the HuggingFace model ID

- temperature:

  Numeric or NULL. Sampling temperature (not sent when NULL)

- top.p:

  Numeric or NULL. Nucleus sampling parameter (not sent when NULL)

- max_tokens:

  Integer. Maximum tokens to generate

- hf_token:

  Optional HuggingFace token

## Value

Character string with the generated text

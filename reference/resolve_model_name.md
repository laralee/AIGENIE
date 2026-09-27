# Resolve and Normalize Model Name

Accepts a free-form model name and returns a standardized string. Known
aliases are resolved to canonical model names. If the model is not
recognized, a warning is issued and the cleaned original input is
returned.

## Usage

``` r
resolve_model_name(model, silently)
```

## Arguments

- model:

  A single string, the user-supplied model name.

- silently:

  Currently unused.

## Value

A standardized model name. Known aliases are returned with a provider
prefix (e.g., `"OpenAI/gpt-4o"`); other inputs are returned trimmed.

# Build Optional Sampling Arguments for an LLM Request

Many recent models reject `temperature` and/or `top_p`, so these are
only sent when explicitly set. Returns the API-style arguments for the
values that are not `NULL`.

## Usage

``` r
sampling_args(temperature = NULL, top.p = NULL)
```

## Arguments

- temperature:

  Numeric or NULL. Sampling temperature.

- top.p:

  Numeric or NULL. Nucleus sampling parameter.

## Value

A named list containing `temperature` and/or `top_p` for the non-`NULL`
inputs (an empty list if both are `NULL`).

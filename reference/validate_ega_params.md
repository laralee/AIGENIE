# Validate EGA Parameters

Validates and normalizes the EGA algorithm, unidimensionality method,
and model parameters. Trims whitespace and performs case-insensitive
matching. Returns canonical-cased values.

## Usage

``` r
validate_ega_params(EGA.algorithm, EGA.uni.method, EGA_model)
```

## Arguments

- EGA.algorithm:

  A string: one of "leiden", "louvain", "walktrap" (NULL defaults to
  "walktrap")

- EGA.uni.method:

  A string: one of "expand", "LE", "louvain" (NULL defaults to
  "louvain")

- EGA_model:

  A string or NULL: one of "glasso", "TMFG". NULL leaves the model unset
  so both are compared downstream.

## Value

A named list with elements `EGA.algorithm`, `EGA.uni.method`, and
`EGA_model`, each a list with cleaned and correctly-cased `type` and
`overall` values.

## Details

Each parameter may be NULL, a single string (applied to both the
type-level and overall analyses), or a named list with `type` and/or
`overall` elements.

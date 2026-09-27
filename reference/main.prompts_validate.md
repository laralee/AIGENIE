# Validate and Normalize `main.prompts`

Validates that `main.prompts` is a named list of non-empty strings, one
for each item type in `items.attributes`, matched by normalized name.

## Usage

``` r
main.prompts_validate(main.prompts, items.attributes, silently)
```

## Arguments

- main.prompts:

  A named list of prompt strings, one per item type.

- items.attributes:

  A cleaned list from
  [`items.attributes_validate()`](https://laralee.github.io/AIGENIE/reference/items.attributes_validate.md).

- silently:

  A flag determining wheter a warning message should be printed

## Value

A cleaned and ordered named list of trimmed prompt strings. Also returns
the appropriate 'custom' flag (TRUE if custom ok, FALSE if not)

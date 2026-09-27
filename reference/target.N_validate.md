# Validate and Expand `target.N` for Each Item Type

Ensures that `target.N` is either:

- NULL -\> defaults to 60 per item type

- A single integer -\> repeated for each item type

- A named list/vector of integers -\> names must match the item types

## Usage

``` r
target.N_validate(
  target.N,
  items.attributes,
  items.only,
  embeddings.only,
  silently
)
```

## Arguments

- target.N:

  An integer, list/vector of integers, or NULL.

- items.attributes:

  A cleaned list returned from
  [`items.attributes_validate()`](https://laralee.github.io/AIGENIE/reference/items.attributes_validate.md).

- items.only:

  A flag used to determine if only items need to be generated

- embeddings.only:

  A flag used to determine if only embeddings need to be generated

- silently:

  A flag used to determine if warnings should be printed

## Value

A named list of integers, one per item type.

## Details

Warns when fewer than 15 items per attribute would be generated (unless
only items or embeddings are requested).

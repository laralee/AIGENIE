# Validate and Clean `item.attribute.definitions`

Validates that `item.attribute.definitions` is a named list where:

- Names are unique (after trim + case-fold)

- Names exist among the attributes listed in `items.attributes` (i.e.,
  the values of its sublists, not `names(items.attributes)`)

- Values are non-empty strings

## Usage

``` r
item.attribute.definitions_validate(
  item.attribute.definitions,
  items.attributes
)
```

## Arguments

- item.attribute.definitions:

  A named list of strings, where each name must correspond to an
  attribute in one of the `items.attributes` sublists and each value
  must be a non-empty string.

- items.attributes:

  A cleaned list from
  [`items.attributes_validate()`](https://laralee.github.io/AIGENIE/reference/items.attributes_validate.md).

## Value

A cleaned version of `item.attribute.definitions`.

## Details

Not every attribute needs a definition; users may define only a subset.

Returns a cleaned version with:

- Normalized names (trimmed and lowercased)

- Trimmed values (case preserved)

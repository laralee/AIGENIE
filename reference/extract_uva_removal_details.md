# Extract item-level UVA removal evidence

Creates one row per item removed by UVA, retaining the strongest
redundant relationship as the primary diagnostic and all redundant
partners for auditability.

## Usage

``` r
extract_uva_removal_details(
  uva_object,
  removed_ids,
  remaining_ids,
  items,
  sweep,
  cut.off
)
```

## Arguments

- uva_object:

  An [`EGAnet::UVA`](https://rdrr.io/pkg/EGAnet/man/UVA.html) result for
  the current sweep.

- removed_ids:

  Character vector of item IDs removed in this sweep.

- remaining_ids:

  Character vector of item IDs retained after this sweep.

- items:

  Data frame with `ID` and `statement` columns.

- sweep:

  Integer. The UVA sweep number.

- cut.off:

  Numeric. The wTO threshold used by UVA.

## Value

A data frame with one row per removed item: `ID`, `uva_sweep`,
`redundant_with_ID`, `redundant_with_statement`, `wTO`,
`all_redundant_with_IDs`, and `all_redundant_wTO`.

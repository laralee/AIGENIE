# Restore original item labels after an `all.together` reduction

[`run_all_together()`](https://laralee.github.io/AIGENIE/reference/run_all_together.md)
relabels items before the pooled reduction. This helper replaces the
relabeled rows in `final_items` (and `initial_items`, when present) with
the original item rows, carrying over the `EGA_com` community
assignments estimated by the pipeline.

## Usage

``` r
restore_all_together_items(result, items)
```

## Arguments

- result:

  The pipeline result for the pooled `"All"` item type.

- items:

  The original (un-relabeled) items data frame.

## Value

`result` with `final_items` (and `initial_items`, if present) holding
the original item rows plus their `EGA_com` column.

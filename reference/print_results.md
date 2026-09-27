# Print Results

Displays a summary of the AI-GENIE analysis results for each item type
(and, optionally, the pooled sample), including the EGA model used,
embedding type, starting and final number of items, and NMI values
before and after reduction.

## Usage

``` r
print_results(obj, obj2, run.overall)
```

## Arguments

- obj:

  A list containing the OVERALL analysis results (the `overall_result`
  returned by `run_pipeline_for_all`). Only used when
  `run.overall = TRUE`.

- obj2:

  A named list containing the ITEM-TYPE LEVEL analysis results (the
  `item_level` returned by `run_item_reduction_pipeline`).

- run.overall:

  A flag denoting if overall results should be printed

## Value

No return value; the function prints the results to the console.

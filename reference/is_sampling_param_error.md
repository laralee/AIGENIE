# Detect Errors Caused by Unsupported Sampling Parameters

Detect Errors Caused by Unsupported Sampling Parameters

## Usage

``` r
is_sampling_param_error(message)
```

## Arguments

- message:

  Character string. An error message.

## Value

Logical. `TRUE` if the message mentions `temperature` or `top_p` (also
matching "top p" and "top.p").

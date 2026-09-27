# Warn When Sampling Parameters Are Set for an API Model

Called once during input validation. Warns that many models no longer
accept `temperature` / `top.p`, and separately warns when both are set
for an Anthropic model, since recent Claude models reject requests that
set both.

## Usage

``` r
warn_sampling_params(temperature, top.p, provider)
```

## Arguments

- temperature:

  Numeric or NULL. Sampling temperature.

- top.p:

  Numeric or NULL. Nucleus sampling parameter.

- provider:

  Character. The detected provider (e.g., "openai", "anthropic").

## Value

`NULL`, invisibly. Called for its warnings.

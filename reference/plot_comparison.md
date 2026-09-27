# Plot Comparisons

Generates a side-by-side comparison of two network analysis results,
typically representing the item network before and after AI-GENIE
reduction. The plot includes the provided captions, displays NMI values
for each network, and reports the change in NMI as a subtitle.

## Usage

``` r
plot_comparison(p1, p2, caption1, caption2, nmi2, nmi1, title)
```

## Arguments

- p1:

  An object representing the first network analysis result (e.g., the
  initial EGA object before reduction).

- p2:

  An object representing the second network analysis result (e.g., the
  final EGA object after reduction).

- caption1:

  A character string to be used as a caption or title for the first
  network (e.g., "Before AI-GENIE Network").

- caption2:

  A character string for the second network (e.g., "After AI-GENIE
  Network").

- nmi2:

  A numeric value representing the NMI of the second network.

- nmi1:

  A numeric value representing the Normalized Mutual Information (NMI)
  of the first network.

- title:

  A character string specifying the title of the plot.

## Value

A `patchwork` object displaying the two networks side by side with the
provided captions and NMI values.

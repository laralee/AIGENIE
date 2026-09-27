# Generate and Validate Psychometric Scale Items Using Local Models

Local version of AI-GENIE that uses locally installed language models
and embeddings for complete privacy and offline operation. Generates
items, creates embeddings, and performs network psychometric reduction
entirely on the user's machine.

## Usage

``` r
local_AIGENIE(
  item.attributes,
  model.path,
  embedding.model = "bert-base-uncased",
  main.prompts = NULL,
  temperature = 1,
  top.p = 1,
  target.N = NULL,
  domain = NULL,
  scale.title = NULL,
  item.examples = NULL,
  audience = NULL,
  item.type.definitions = NULL,
  item.attribute.definitions = NULL,
  response.options = NULL,
  prompt.notes = NULL,
  system.role = NULL,
  EGA.model = NULL,
  EGA.algorithm = NULL,
  EGA.uni.method = NULL,
  uva.cut.off = 0.2,
  boot.iter = 500,
  ncores = NULL,
  n.ctx = 4096,
  n.gpu.layers = -1,
  max.tokens = 1024,
  device = "auto",
  batch.size = 32,
  pooling.strategy = "mean",
  max.length = 512L,
  keep.org = FALSE,
  items.only = FALSE,
  embeddings.only = FALSE,
  adaptive = TRUE,
  run.overall = FALSE,
  all.together = FALSE,
  plot = TRUE,
  silently = FALSE
)
```

## Arguments

- item.attributes:

  Named list of item types and their attributes (required)

- model.path:

  Path to local GGUF model file (required)

- embedding.model:

  Name or path to local embedding model (default: "bert-base-uncased")

- main.prompts:

  Custom prompts for item generation (optional)

- temperature:

  LLM temperature for randomness (0-2, default: 1)

- top.p:

  Top-p nucleus sampling parameter (0-1, default: 1)

- target.N:

  Number of items to generate per type (default: 60)

- domain:

  Content domain (e.g., "psychological")

- scale.title:

  Name of the scale

- item.examples:

  Data frame of example items

- audience:

  Target population

- item.type.definitions:

  Definitions for item types

- item.attribute.definitions:

  Named list of definitions for some or all attributes (names must match
  attributes within the `item.attributes` sublists). See
  [`AIGENIE`](https://laralee.github.io/AIGENIE/reference/AIGENIE.md)
  for details.

- response.options:

  Response scale labels

- prompt.notes:

  Additional instructions for generation

- system.role:

  Custom system prompt

- EGA.model:

  Network model ("glasso", "TMFG", or NULL for auto)

- EGA.algorithm:

  Community detection algorithm ("walktrap", "leiden", "louvain"; NULL
  uses "walktrap")

- EGA.uni.method:

  Unidimensionality method ("louvain", "expand", "LE"; NULL uses
  "louvain")

- uva.cut.off:

  Numeric in `[0, 1)`. wTO threshold passed to
  [`EGAnet::UVA`](https://rdrr.io/pkg/EGAnet/man/UVA.html) for the
  redundancy-reduction step (default: 0.20). Lower values remove more
  items.

- boot.iter:

  A positive integer (optional, default: 500). Number of bootstrap
  iterations used by
  [`EGAnet::bootEGA`](https://rdrr.io/pkg/EGAnet/man/bootEGA.html)
  during item-stability analyses and iterative stability filtering.

- ncores:

  A positive integer or `NULL` (optional, default: `NULL`). Number of
  processing cores passed to
  [`EGAnet::bootEGA`](https://rdrr.io/pkg/EGAnet/man/bootEGA.html). When
  `NULL`, AIGENIE does not pass an `ncores` argument, preserving the
  current default behavior of
  [`EGAnet::bootEGA`](https://rdrr.io/pkg/EGAnet/man/bootEGA.html).

- n.ctx:

  Context window size (default: 4096)

- n.gpu.layers:

  GPU layers to use (-1 for all, default: -1)

- max.tokens:

  Maximum tokens per generation (default: 1024)

- device:

  Device for embeddings ("auto", "cpu", "cuda", "mps")

- batch.size:

  Batch size for embeddings (default: 32)

- pooling.strategy:

  Pooling for embeddings ("mean", "cls", "max")

- max.length:

  Max sequence length for embeddings (default: 512)

- keep.org:

  Keep original items and embeddings (default: FALSE)

- items.only:

  Generate items only, skip reduction (default: FALSE)

- embeddings.only:

  Generate embeddings only (default: FALSE)

- adaptive:

  Use adaptive generation (default: TRUE)

- run.overall:

  A logical value (optional, default: FALSE). Controls whether a *fit*
  analysis on the complete item pool is run *post-reduction.* By
  default, only type-level reduction analyses are run (i.e., items of
  like-type go through the pipeline independent of the other items in
  the pool). When this flag is `TRUE`, an additional analysis is run on
  the overall sample, but no further reductions at the overall level are
  made. If only one item type is present, this argument will be ignored.

- all.together:

  A logical value (optional, default: FALSE). Controls whether the
  *reduction* analysis on the complete item pool is run. By default,
  only type-level reduction analyses are run (i.e., items of like-type
  go through the pipeline independent of the other items in the pool).
  When this flag is `TRUE`, reductions are made at the overall level
  (i.e., all items go through the reduction pipeline together, agnostic
  of item type). If only one item type is present, this argument will be
  ignored.

- plot:

  Display network plots (default: TRUE)

- silently:

  Suppress progress messages (default: FALSE)

## Value

The structure of the return value depends on the function flags.

**When `items.only = TRUE`:** Returns a `data.frame` of generated items
with columns `type`, `attribute`, `statement`, and `ID`.

**When `embeddings.only = TRUE`:** Returns a named `list` with two
elements:

- `embeddings` — a numeric embedding matrix (rows are embedding
  dimensions; columns are items, named by item `ID`).

- `items` — the items `data.frame` described above.

**Default behaviour** (`items.only = FALSE`, `embeddings.only = FALSE`,
`run.overall = FALSE`, `keep.org = FALSE`, `all.together = FALSE`):
Returns a named `list` with two top-level elements:

- `item_type_level`:

  A named list where each name is an item type and each element is a
  per-type named list containing:

  `final_NMI`

  :   Numeric: normalized mutual information (NMI) of the final EGA
      solution after reduction.

  `initial_NMI`

  :   Numeric: NMI of the pre-reduction item pool, estimated on the full
      (dense) embeddings with the selected EGA model.

  `embeddings`

  :   List containing `selected` (`"full"` or `"sparse"`, the embedding
      representation chosen for reduction), `selection_log` (a
      `data.frame` of the NMI for each candidate EGA model and
      representation), and `full` and `sparse` (embedding matrices for
      the final items).

  `UVA`

  :   List from Unique Variable Analysis containing `n_removed`,
      `n_sweeps`, `redundant_pairs` (a `data.frame` of redundant item
      groups), and `removal_log` (a `data.frame` with one row per
      removed item, its retained redundant partner, and the wTO
      statistic).

  `bootEGA`

  :   List containing `post_uva_initial_boot` and `post_uva_final_boot`
      (`bootEGA` objects before and after stability filtering),
      `n_removed`, `items_removed` (a `data.frame` of removed items with
      their item stability), and `initial_boot_with_redundancies` (a
      `bootEGA` object for the pre-reduction pool, used in
      `stability_plot`).

  `EGA.model_selected`

  :   Character: the chosen EGA model (`"glasso"` or `"TMFG"`).

  `final_items`

  :   `data.frame`: final items after reduction (columns `ID`, `type`,
      `attribute`, `statement`, and `EGA_com`, the final EGA community).

  `final_EGA`

  :   `EGA.fit` object (from EGAnet) for the final items.

  `initial_EGA`

  :   `EGA.fit` object for the pre-reduction item pool.

  `start_N`

  :   Integer: initial number of items in this type.

  `final_N`

  :   Integer: final number of items in this type.

  `network_plot`

  :   `patchwork` object comparing networks before vs after reduction.

  `stability_plot`

  :   `patchwork` object showing networks and item stability before vs
      after reduction.

  `filtering_audit`

  :   `data.frame` with one row per removed item, giving the removal
      stage (`"UVA"`, `"EGA_selection"`, `"bootEGA"`, or `"final_EGA"`),
      the reason, the filtering statistic and cutoff, redundancy
      partner(s), item stability, and pre-reduction network-loading
      diagnostics. Network loadings are descriptive only; they are not
      used as removal criteria.

  `reduction_summary`

  :   `data.frame` giving the number of items (`N`), `NMI`,
      `n_removed_at_stage`, and `delta_NMI` (change from `initial_NMI`)
      at each stage of the reduction.

- `filtering_audit`:

  `data.frame` combining the per-type `filtering_audit` tables across
  all item types.

**When `keep.org = TRUE`** (in addition to the defaults above): each
per-type sublist also contains `initial_items` (the pre-reduction items,
with their `EGA_com` from the initial EGA), and its `embeddings` list
also contains `full_org` and `sparse_org` (the full and sparse embedding
matrices for the pre-reduction item pool).

**When `run.overall = TRUE`** (and more than one item type is present):
the list additionally contains `overall`, a pooled post-reduction fit of
all items retained by the type-level reductions. No further items are
removed at this level. `overall` contains `final_NMI`, `initial_NMI`,
`embeddings` (`selected`, `full`, and `sparse`), `EGA.model_selected`,
`final_items`, `final_EGA`, `initial_EGA`, `start_N`, `final_N`,
`network_plot`, `stability_plot` (always `NULL`), `filtering_audit`, and
`reduction_summary`. Pooled NMI values compare EGA communities against
type-by-attribute labels. With `keep.org = TRUE`, `overall` also
contains `initial_items`, and `overall$embeddings` also contains
`full_org` and `sparse_org`. The top-level `filtering_audit` then
reports pooled (rather than within-type) pre-reduction network-loading
diagnostics.

**When `all.together = TRUE`** (and more than one item type is present):
results are **not** split by item type. The function returns a single
per-type named list (as described under `item_type_level` above) for the
pooled analysis, in which EGA communities are compared against
type-by-attribute labels. Here, `final_items` (and `initial_items`, when
`keep.org = TRUE`) contain the original item rows (with their original
`type` and `attribute` labels) plus the `EGA_com` column.

**On failure:** if item generation or embedding fails, the items
generated so far are returned. If the reduction pipeline fails, the
partial per-type results list is returned.

## References

Golino, H. F., & Epskamp, S. (2017). Exploratory graph analysis: A new
approach for estimating the number of dimensions in psychological
research. *PLOS ONE, 12*(6), e0174035.
[doi:10.1371/journal.pone.0174035](https://doi.org/10.1371/journal.pone.0174035)

Christensen, A. P., Garrido, L. E., & Golino, H. (2023). Unique variable
analysis: A network psychometrics method to detect local dependence.
*Multivariate Behavioral Research, 58*(6), 1165–1182.
[doi:10.1080/00273171.2023.2194606](https://doi.org/10.1080/00273171.2023.2194606)

Christensen, A. P., & Golino, H. (2021). Estimating the stability of
psychological dimensions via bootstrap exploratory graph analysis: A
Monte Carlo simulation and tutorial. *Psych, 3*(3), 479–500.
[doi:10.3390/psych3030032](https://doi.org/10.3390/psych3030032)

Danon, L., Díaz-Guilera, A., Duch, J., & Arenas, A. (2005). Comparing
community structure identification. *Journal of Statistical Mechanics:
Theory and Experiment, 2005*(9), P09008.
[doi:10.1088/1742-5468/2005/09/P09008](https://doi.org/10.1088/1742-5468/2005/09/P09008)

Russell-Lasalandra, L. L., Christensen, A. P., & Golino, H. F. (2026).
Generative psychometrics via AI-GENIE: Automatic item generation and
validation with network-integrated evaluation. *Behavior Research
Methods*, *58*(8), 217.
[doi:10.3758/s13428-026-03082-1](https://doi.org/10.3758/s13428-026-03082-1)

## Examples

``` r
if (FALSE) { # \dontrun{
########################################################
#### Running AIGENIE with a downloaded LLM model ######
########################################################

# Item type definitions
trait.definitions <- list(
 neuroticism = paste0(
   "Neuroticism is a personality trait that describes one's ",
   "tendency to experience negative emotions like anxiety, ",
   "depression, irritability, anger, and self-consciousness."
 ),
 extraversion = paste0(
   "Extraversion is a personality trait that describes people ",
   "who are more focused on the external world than their ",
   "internal experience."
 )
)

# Item attributes
aspects.of.personality.traits <- list(
 neuroticism = c("anxious", "depressed", "insecure", "emotional"),
 extraversion = c("friendly", "positive", "assertive", "energetic")
)

# Name the field or specialty
domain <- "Personality Measurement"

# Name the Inventory being created
scale.title <- "Two of 'Big Five:' A Streamlined Personality Inventory"

# Add a file path name to a local text generation model downloaded on your computer
model.path <- "ADD FILE PATH TO DOWNLOADED MODEL HERE"


# Generate and validate items using a model installed on your machine
local_example <- local_AIGENIE(
 item.attributes = aspects.of.personality.traits,
 item.type.definitions = trait.definitions,
 domain = domain,
 model.path = model.path
)

} # }
```

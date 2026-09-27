# Local Generative Network-Integrated Evaluation (local_GENIE)

Local version of GENIE that uses locally installed embedding models for
complete privacy and offline operation. Provides the same psychometric
validation and quality assessment for user-supplied items as GENIE, but
generates embeddings locally using transformer models instead of API
calls.

## Usage

``` r
local_GENIE(
  items,
  embedding.matrix = NULL,
  embedding.model = "bert-base-uncased",
  device = "auto",
  batch.size = 32,
  pooling.strategy = "mean",
  max.length = 512,
  EGA.model = NULL,
  EGA.algorithm = NULL,
  EGA.uni.method = NULL,
  uva.cut.off = 0.2,
  boot.iter = 500,
  ncores = NULL,
  embeddings.only = FALSE,
  run.overall = FALSE,
  all.together = FALSE,
  plot = TRUE,
  silently = FALSE
)
```

## Arguments

- items:

  Data frame with columns: statement, attribute, type, ID. `statement`,
  `attribute`, and `type` are coerced to character, and `attribute` and
  `type` are trimmed and lowercased. `ID` may be numeric, character, or
  factor, and must be unique.

  - `statement`: The actual item text

  - `attribute`: The construct/attribute the item measures

  - `type`: The item type/category

  - `ID`: Unique identifier for each item

- embedding.matrix:

  Optional numeric matrix or data frame where:

  - Rows represent embedding dimensions

  - Columns represent items (must match items\$ID exactly)

  - If `NULL`, embeddings will be generated using `embedding.model`

- embedding.model:

  Local embedding model identifier or path. Compatible models:

  - BERT variants: "bert-base-uncased", "bert-large-uncased"

  - RoBERTa: "roberta-base", "roberta-large"

  - DeBERTa: "microsoft/deberta-v3-base", "microsoft/deberta-v3-large"

  - DistilBERT: "distilbert-base-uncased"

  - Local paths: e.g., "/path/to/local/model"

- device:

  Device for embedding computation:

  - "auto": Automatically detect best available device

  - "cpu": Force CPU usage

  - "cuda": Use NVIDIA GPU (if available)

  - "mps": Use Apple Silicon GPU (if available)

- batch.size:

  Number of items to process simultaneously (default: 32)

- pooling.strategy:

  Method for pooling token embeddings:

  - "mean": Average all token embeddings (default)

  - "cls": Use only the CLS token embedding

  - "max": Max pooling across tokens

- max.length:

  Maximum sequence length for tokenization (default: 512)

- EGA.model:

  Network estimation model ("glasso", "TMFG", or NULL for
  auto-selection)

- EGA.algorithm:

  Community detection algorithm ("walktrap", "leiden", "louvain"; NULL
  uses "walktrap")

- EGA.uni.method:

  Unidimensionality assessment method ("louvain", "expand", "LE"; NULL
  uses "louvain")

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

- embeddings.only:

  If `TRUE`, return the embeddings and items and stop (skip network
  analysis)

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

  If `TRUE`, display network comparison plots

- silently:

  If `TRUE`, suppress progress messages

## Value

The structure of the return value depends on the function flags.

**When `embeddings.only = TRUE`:** Returns a named `list` with
`embeddings` (a numeric matrix with embedding dimensions in rows and
items in columns, named by item `ID`) and `items` (the validated items
`data.frame`).

**Default behaviour** (`embeddings.only = FALSE`, `run.overall = FALSE`,
`all.together = FALSE`): Returns a named `list` with two top-level
elements:

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

  :   `data.frame`: final items after reduction (columns `ID`,
      `statement`, `attribute`, `type`, and `EGA_com`, the final EGA
      community).

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

**When `run.overall = TRUE`** (and more than one item type is present):
the list additionally contains `overall`, a pooled post-reduction fit of
all items retained by the type-level reductions. No further items are
removed at this level. `overall` contains `final_NMI`, `initial_NMI`,
`embeddings` (`selected`, `full`, and `sparse`), `EGA.model_selected`,
`final_items`, `final_EGA`, `initial_EGA`, `start_N`, `final_N`,
`network_plot`, `stability_plot` (always `NULL`), `filtering_audit`, and
`reduction_summary`. Pooled NMI values compare EGA communities against
type-by-attribute labels. The top-level `filtering_audit` then reports
pooled (rather than within-type) pre-reduction network-loading
diagnostics.

**When `all.together = TRUE`** (and more than one item type is present):
results are **not** split by item type. The function returns a single
per-type named list (as described under `item_type_level` above) for the
pooled analysis, in which EGA communities are compared against
type-by-attribute labels. Here, `final_items` contains the original item
rows (with their original `type` and `attribute` labels) plus the
`EGA_com` column.

**On failure:** if the reduction pipeline fails, the partial per-type
results list is returned.

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
###################################################
#### Using GENIE with a Local Embedding Model  ####
###################################################

# First, ensure that your machine is configured to compute local generation
install_local_llm_support()
# Once ready, continue to run GENIE on your data frame


# Specify item statements that you already have written
statements <- c(
  "I find myself naturally initiating conversations with strangers at social gatherings.",
  "I enjoy creating a welcoming atmosphere for people I meet for the first time.",
  "I generally maintain a hopeful outlook, even when faced with challenges.",
  "I frequently find myself in a good mood, spreading cheer to those around me.",
  "I often have the drive to engage in exciting activities, even after a long day.",
  "I tend to tackle projects with enthusiasm and high energy from start to finish.",
  paste0(
    "I actively seek to include others in group activities, ",
    "making them feel part of the team."
  ),
  "I frequently reach out to new acquaintances to foster connections and friendships.",
  paste0(
    "I habitually focus on the silver lining in difficult ",
    "situations, maintaining an optimistic perspective."
  ),
  paste0(
    "I often express gratitude for the positive aspects of my ",
    "life, which enhances my overall mood."
  ),
  "I find joy in taking on new challenges that require a burst of energy and enthusiasm.",
  "I thrive in dynamic environments that keep me on my toes and invigorate my spirit.",
  "I take pleasure in introducing people to one another, acting as a social connector.",
  "I enjoy making others comfortable by engaging them in light-hearted conversation.",
  "I often set a positive tone in group settings with my upbeat demeanor.",
  "I approach each day with a sense of excitement and a positive mindset.",
  "I am drawn to fast-paced environments where I can express my high energy levels.",
  "I feel invigorated when working on multiple projects that demand my full attention.",
  "I take delight in meeting new people and quickly making them feel at ease.",
  paste0(
    "I find it rewarding to help shy or reserved individuals ",
    "become involved in group discussions."
  ),
  "I have a natural tendency to uplift others with my positive remarks and outlook.",
  paste0(
    "I find happiness in highlighting the successes of others, ",
    "contributing to a cheerful environment."
  ),
  "I eagerly immerse myself in activities that demand stamina and sustained energy.",
  "I often channel my vitality into hobbies and sports that require physical exertion.",
  "I feel rejuvenated when I bring people together to collaborate and share ideas.",
  "I often extend a genuine greeting to others, creating an inviting atmosphere.",
  "I regularly see challenges as opportunities for growth and learning.",
  "I commonly radiate positivity, influencing the mood of those around me.",
  "I approach mornings with anticipation and vigor, ready to embrace the day.",
  paste0(
    "I consistently infuse enthusiasm into group activities, ",
    "boosting collective energy levels."
  ),
  "I make an effort to connect with people by remembering details about their lives.",
  "I genuinely enjoy learning about people's diverse experiences and viewpoints.",
  "I have a habit of encouraging others to see the bright side of their situations.",
  "I believe in celebrating small victories, finding joy in daily accomplishments.",
  "I often find myself eager to start the day with ambitious plans and goals.",
  paste0(
    "I am known for sustaining high levels of energy during ",
    "extended work sessions or projects."
  ),
  "I make an effort to engage those around me in meaningful and enjoyable conversations.",
  "I often seek opportunities to bring people together, fostering a sense of community.",
  "I naturally inspire others with my optimistic outlook, even in uncertain times.",
  paste0(
    "I frequently look for the positive aspects in challenging ",
    "situations and share them with others."
  ),
  "I approach new experiences with an eagerness and fervor that motivates those around me.",
  "I thrive on maintaining high energy levels throughout demanding and fast-paced days.",
  paste0(
    "I take pleasure in initiating warm interactions in group ",
    "settings to make everyone comfortable."
  ),
  "I enjoy hosting gatherings that connect friends and encourage social bonding.",
  paste0(
    "I am skilled at turning setbacks into learning experiences ",
    "to maintain a positive outlook."
  ),
  "I always try to highlight the benefits in situations, enhancing a cheerful atmosphere.",
  "I find excitement in starting the day with a list of activities to energize my routine.",
  paste0(
    "I relish the challenge of keeping up with dynamic schedules ",
    "that require sustained energy."
  ),
  "I often find joy in making newcomers feel welcome and appreciated in group settings.",
  "I genuinely enjoy striking up conversations to learn more about the people I encounter.",
  "I have a knack for seeing potential in situations that others might overlook.",
  paste0(
    "I consistently try to uplift the mood in my surroundings ",
    "with hopeful and encouraging words."
  ),
  paste0(
    "I frequently harness my energy to inspire and motivate those ",
    "around me in team environments."
  ),
  paste0(
    "I often feel invigorated by challenges that require ",
    "sustained focus and dynamic thinking."
  ),
  "I often create environments where people feel encouraged to share their thoughts freely.",
  "I find it fulfilling to engage deeply with people, building lasting connections.",
  "I see potential in every day, believing it holds opportunities for something good.",
  "I actively focus on the pleasures of life, which naturally enhances my mood.",
  "I am invigorated by opportunities to engage in lively and spirited events.",
  "I tend to maintain momentum throughout the day, sustaining my energy levels.",
  paste0(
    "I frequently experience sudden shifts in my emotions even ",
    "when there is no apparent reason."
  ),
  paste0(
    "People often find it difficult to predict my emotional ",
    "reactions to different situations."
  ),
  "I often doubt my abilities and worry about whether I am meeting expectations.",
  "I frequently question my self-worth and tend to seek reassurance from others.",
  "I become annoyed easily over small inconveniences or delays.",
  paste0(
    "I often find myself feeling agitated or frustrated in ",
    "situations that don't bother most people."
  ),
  "My mood can change drastically over the course of a day, often without any clear reason.",
  "I tend to experience emotional highs and lows more intensely than those around me.",
  "I sometimes avoid taking on new challenges because I fear not being good enough.",
  paste0(
    "I often feel uncertain about my social standing and worry ",
    "about being accepted by others."
  ),
  "I find myself getting irritated quickly when things don't go my way.",
  "Minor annoyances often cause my patience to wear thin unusually fast.",
  "I frequently struggle to maintain a stable emotional state throughout the day.",
  "Unexpected events can cause me to experience drastic emotional swings.",
  "I often feel inadequate in comparison to others around me.",
  "I tend to second-guess my choices due to a lack of confidence in myself.",
  "I tend to become frustrated when things do not proceed as I have planned.",
  "I am prone to irritation when faced with unexpected changes to my routine.",
  paste0(
    "My emotional state is often unpredictable, shifting from ",
    "contentment to sadness with little warning."
  ),
  "People have commented that my emotions seem to fluctuate more than those of others.",
  "I frequently feel self-conscious about my achievements compared to those of my peers.",
  paste0(
    "I often worry excessively about making mistakes, even in ",
    "situations where it might be inconsequential."
  ),
  "Small disruptions in my daily routine can trigger strong feelings of annoyance.",
  "I find myself becoming irritated more quickly than others when under stress or pressure.",
  paste0(
    "I often find my emotional responses to be unpredictable, ",
    "feeling fine one moment and unsettled the next."
  ),
  "I experience strong emotions that can shift unexpectedly, often catching me off guard.",
  "I regularly feel uncertain about my ability to manage new responsibilities effectively.",
  "I often question my decisions, fearing they might not lead to the best outcomes.",
  paste0(
    "I frequently find myself reacting with impatience to ",
    "situations perceived as minor interruptions."
  ),
  "Even minor provocations can sometimes lead to an exaggerated sense of annoyance for me.",
  paste0(
    "My emotional state is often inconsistent, and I can feel ",
    "ecstatic or despondent within short timeframes."
  ),
  paste0(
    "I notice that my feelings can be quite volatile and intense, ",
    "affecting how I interact with others throughout the day."
  ),
  "I regularly doubt whether I am capable of achieving my personal or professional goals.",
  "I often seek validation from others to feel reassured about my self-worth.",
  paste0(
    "I am sensitive to disturbances and find my patience wearing ",
    "thin quickly when things aren't orderly."
  ),
  paste0(
    "I occasionally struggle to contain my annoyance over trivial ",
    "issues that disrupt my sense of calm."
  ),
  "I can go from feeling upbeat to being downcast without an obvious cause.",
  "My emotional responses can sometimes be unpredictable, shifting with little notice.",
  "I often feel the need for affirmation about my abilities from friends or colleagues.",
  "I tend to compare myself to others and feel uncertain about my achievements.",
  "I find myself easily bothered by noises or disturbances in my environment.",
  "I get easily flustered by situations that interrupt my planned activities.",
  paste0(
    "I find it challenging to maintain a consistent emotional ",
    "state, regardless of external situations."
  ),
  "My emotional reactions can be intense and differ significantly from moment to moment.",
  "I have a persistent fear of not measuring up to the expectations placed on me.",
  "I often feel anxious about others' perceptions of my capabilities and appearance.",
  "I am quick to express frustration at minor inconveniences in my daily routine.",
  paste0(
    "I find that small, unforeseen events often disrupt my sense ",
    "of calm and lead to irritation."
  ),
  paste0(
    "My emotional reactions can be strong and relentless, ",
    "impacting my behavior throughout the day."
  ),
  paste0(
    "I often find myself emotionally labile, with an inner ",
    "turbulence that others rarely perceive."
  ),
  "I frequently worry about my competence in areas where others seem confident.",
  paste0(
    "I have a tendency to second-guess myself and require ",
    "affirmation to feel reassured about my choices."
  ),
  "Small disruptions can ignite a lingering sense of agitation within me.",
  "I often catch myself feeling irritable even in relatively calm settings.",
  paste0(
    "I find myself swinging from happy to melancholic in a short ",
    "span of time, often surprising even myself."
  ),
  paste0(
    "Others often comment on how quickly my mood can change in ",
    "response to seemingly minor events."
  ),
  paste0(
    "I tend to feel apprehensive about presenting my opinions, ",
    "fearing they may be judged harshly."
  ),
  "I often require reassurance from peers to feel confident in my decisions and ideas.",
  "Interruptions during focused tasks often lead to an outpour of irritation from me.",
  "I struggle to keep my frustration in check when things do not unfold as expected."
)


# Create the item type and attribute labels
item.attributes <- c(
  rep(c("friendly", "positive", "energetic"), each = 2, times = 10),
  rep(c("moody", "insecure", "irritable"), each = 2, times = 10)
)
item.types <- c(
  rep("extraversion", 60),
  rep("neuroticism", 60)
)


# Build your data frame with the required columns: ID, statement, attribute, and type
items_df <- data.frame(
  ID = rep(as.factor(1:length(statements))),
  statement = statements,
  attribute = item.attributes,
  type = item.types
)


# Run GENIE with items you provide with the default local embedding model ("bert-base-uncased")
example_reduction <- local_GENIE(items = items_df)

# View the results
View(example_reduction)


########################################################################################
###### Or, Run local_GENIE with a locally-install Embedding Model of your Choice #######
#######################################################################################

# Provide the path to a compatible locally installed embedding model
# Note that this package will not install the model for you, it should already be
# installed and ready to go
embedding.model <- "ADD YOUR PATH HERE"

# Run GENIE using the Hugging Face Embedding model
example_reduction_your_model <- local_GENIE(items = items_df,
                              embedding.model = embedding.model)

} # }
```

# tests/testthat/test-attribute-definitions.R
# ============================================================
# Unit tests for item.attribute.definitions (no API keys required)
# ============================================================

attrs <- AIGENIE:::items.attributes_validate(list(
  neuroticism = c("anxious", "depressed", "moody"),
  extraversion = c("friendly", "energetic", "moody")
))

test_that("item.attribute.definitions_validate accepts a partial, messy definition list", {

  out <- AIGENIE:::item.attribute.definitions_validate(
    list(" Anxious " = "  Prone to worry.  ", MOODY = "Frequent shifts in mood."),
    attrs
  )

  expect_named(out, c("anxious", "moody"))
  expect_equal(out$anxious, "Prone to worry.")
})

test_that("item.attribute.definitions_validate rejects malformed input", {

  expect_error(
    AIGENIE:::item.attribute.definitions_validate(c(anxious = "x"), attrs),
    regexp = "named list"
  )
  expect_error(
    AIGENIE:::item.attribute.definitions_validate(list("x"), attrs),
    regexp = "non-empty names"
  )
  expect_error(
    AIGENIE:::item.attribute.definitions_validate(list(anxious = "a", ANXIOUS = "b"), attrs),
    regexp = "unique names"
  )
  # Item type names are not attributes
  expect_error(
    AIGENIE:::item.attribute.definitions_validate(list(neuroticism = "x"), attrs),
    regexp = "Invalid name.*neuroticism"
  )
  expect_error(
    AIGENIE:::item.attribute.definitions_validate(list(anxious = c("a", "b")), attrs),
    regexp = "non-empty string"
  )
  expect_error(
    AIGENIE:::item.attribute.definitions_validate(list(anxious = 1), attrs),
    regexp = "non-empty string"
  )
  expect_error(
    AIGENIE:::item.attribute.definitions_validate(list(anxious = "   "), attrs),
    regexp = "after trimming"
  )
})

test_that("create_main.prompts inserts definitions after the attribute list", {

  defs <- list(anxious = "Prone to worry.", moody = "Frequent shifts in mood")
  notes <- list(neuroticism = "", extraversion = "")

  prompts <- AIGENIE:::create_main.prompts(
    item.attributes = attrs, item.type.definitions = NULL,
    item.attribute.definitions = defs,
    domain = NULL, scale.title = NULL, prompt.notes = notes,
    audience = NULL, item.examples = NULL
  )

  expected_neuro <- paste0(
    "(1) anxious, (2) depressed and (3) moody. ",
    "Here are the precise definitions of some of these attributes in this context: ",
    "(1) anxious: Prone to worry; (2) moody: Frequent shifts in mood. ",
    "Generate EXACTLY TWO items PER attribute."
  )
  expect_true(grepl(expected_neuro, prompts$neuroticism, fixed = TRUE))

  # A shared attribute's definition applies to every type that lists it
  expect_true(grepl("(1) moody: Frequent shifts in mood.", prompts$extraversion, fixed = TRUE))
  expect_false(grepl("anxious:", prompts$extraversion, fixed = TRUE))

  # Without definitions, prompts are unchanged from the previous behaviour
  plain <- AIGENIE:::create_main.prompts(
    item.attributes = attrs, item.type.definitions = NULL,
    domain = NULL, scale.title = NULL, prompt.notes = notes,
    audience = NULL, item.examples = NULL
  )
  expect_true(grepl("(3) moody. Generate EXACTLY TWO", plain$neuroticism, fixed = TRUE))
  expect_false(grepl("precise definitions of some", plain$neuroticism, fixed = TRUE))
})

test_that("modify_main.prompts appends definitions once to custom prompts", {

  defs <- list(friendly = "Warm toward others")
  custom <- list(
    neuroticism = "Write items on anxious, depressed, and moody.",
    extraversion = "Write items on friendly, energetic, and moody."
  )
  notes <- list(neuroticism = "", extraversion = "")

  modified <- AIGENIE:::modify_main.prompts(
    custom, attrs, item.type.definitions = NULL,
    item.attribute.definitions = defs,
    domain = NULL, scale.title = NULL, prompt.notes = notes,
    audience = NULL, item.examples = NULL
  )

  sentence <- paste0(
    "Here are the precise definitions of some of these attributes in this context: ",
    "(1) friendly: Warm toward others."
  )
  expect_true(grepl(sentence, modified$extraversion, fixed = TRUE))
  expect_false(grepl("precise definitions of some", modified$neuroticism, fixed = TRUE))

  # Already present -> not appended a second time
  again <- AIGENIE:::modify_main.prompts(
    modified, attrs, item.type.definitions = NULL,
    item.attribute.definitions = defs,
    domain = NULL, scale.title = NULL, prompt.notes = notes,
    audience = NULL, item.examples = NULL
  )
  expect_equal(lengths(regmatches(again$extraversion,
                                  gregexpr(sentence, again$extraversion, fixed = TRUE))), 1L)
})

test_that("AIGENIE validators return cleaned item.attribute.definitions", {

  v <- AIGENIE:::validate_user_input_AIGENIE(
    item.attributes = list(neuroticism = c("anxious", "moody"),
                           extraversion = c("friendly", "energetic")),
    openai.API = "fake-key-for-test", hf.token = NULL, main.prompts = NULL,
    groq.API = NULL, anthropic.API = NULL, jina.API = NULL, model = "gpt4o",
    temperature = 1, top.p = 1, embedding.model = "text-embedding-3-small",
    target.N = NULL, domain = NULL, scale.title = NULL, item.examples = NULL,
    audience = NULL, item.type.definitions = NULL,
    item.attribute.definitions = list(Anxious = " Prone to worry. "),
    response.options = NULL, prompt.notes = NULL, system.role = NULL,
    EGA.model = NULL, EGA.algorithm = NULL, EGA.uni.method = NULL,
    keep.org = FALSE, items.only = FALSE, embeddings.only = FALSE,
    adaptive = TRUE, run.overall = FALSE, all.together = FALSE,
    plot = FALSE, silently = TRUE
  )
  expect_equal(v$item.attribute.definitions, list(anxious = "Prone to worry."))

  expect_error(
    AIGENIE:::validate_user_input_AIGENIE(
      item.attributes = list(neuroticism = c("anxious", "moody")),
      openai.API = "fake-key-for-test", hf.token = NULL, main.prompts = NULL,
      groq.API = NULL, anthropic.API = NULL, jina.API = NULL, model = "gpt4o",
      temperature = 1, top.p = 1, embedding.model = "text-embedding-3-small",
      target.N = NULL, domain = NULL, scale.title = NULL, item.examples = NULL,
      audience = NULL, item.type.definitions = NULL,
      item.attribute.definitions = list(calm = "Not anxious."),
      response.options = NULL, prompt.notes = NULL, system.role = NULL,
      EGA.model = NULL, EGA.algorithm = NULL, EGA.uni.method = NULL,
      keep.org = FALSE, items.only = FALSE, embeddings.only = FALSE,
      adaptive = TRUE, run.overall = FALSE, all.together = FALSE,
      plot = FALSE, silently = TRUE
    ),
    regexp = "calm"
  )
})

test_that("AIGENIE forwards item.attribute.definitions into the generation prompt", {

  captured <- NULL
  local_mocked_bindings(
    generate_items_via_llm = function(main.prompts, ...) {
      captured <<- main.prompts
      list(items = data.frame(type = "neuroticism", attribute = "moody",
                              statement = "I often feel moody."),
           successful = TRUE)
    },
    .package = "AIGENIE"
  )

  AIGENIE(
    item.attributes = list(neuroticism = c("anxious", "moody"),
                           extraversion = c("friendly", "energetic")),
    openai.API = "fake-key-for-test",
    item.attribute.definitions = list(moody = "Frequent shifts in mood"),
    items.only = TRUE, target.N = 30, silently = TRUE
  )

  expect_true(grepl("(1) moody: Frequent shifts in mood.", captured$neuroticism, fixed = TRUE))
  expect_false(grepl("precise definitions of some", captured$extraversion, fixed = TRUE))
})

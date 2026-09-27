# tests/testthat/test-pipeline-fixes.R
# ============================================================
# Regression tests for EGA.model forwarding, all.together item
# restoration, and early return on overall-fit failure.
# (no API keys or Python required)
# ============================================================

test_attributes <- list(
  anxiety = c("worry", "nervousness"),
  depression = c("sadness", "hopelessness")
)

test_that("validate_user_input_AIGENIE forwards a user-supplied EGA.model", {

  validate <- function(EGA.model) {
    AIGENIE:::validate_user_input_AIGENIE(
      item.attributes = test_attributes, openai.API = "fake-key-for-test",
      hf.token = NULL, main.prompts = NULL, groq.API = NULL,
      anthropic.API = NULL, jina.API = NULL, model = "gpt4o",
      temperature = 1, top.p = 1, embedding.model = "text-embedding-3-small",
      target.N = NULL, domain = NULL, scale.title = NULL, item.examples = NULL,
      audience = NULL, item.type.definitions = NULL, response.options = NULL,
      prompt.notes = NULL, system.role = NULL, EGA.model = EGA.model,
      EGA.algorithm = NULL, EGA.uni.method = NULL, keep.org = FALSE,
      items.only = FALSE, embeddings.only = FALSE, adaptive = TRUE,
      run.overall = FALSE, all.together = FALSE, plot = FALSE,
      silently = TRUE
    )
  }

  tmfg <- validate("tmfg")
  expect_equal(tmfg$EGA.model$type, "TMFG")
  expect_equal(tmfg$EGA.model$overall, "TMFG")

  auto <- validate(NULL)
  expect_null(auto$EGA.model$type)
  expect_null(auto$EGA.model$overall)
})


test_that("restore_all_together_items keeps EGA_com with original labels", {

  items <- data.frame(
    type = c("anxiety", "anxiety", "depression", "depression"),
    attribute = c("worry", "nervousness", "sadness", "hopelessness"),
    statement = paste("Item", 1:4),
    ID = 1:4,
    stringsAsFactors = FALSE
  )

  relabeled <- AIGENIE:::run_all_together(items)

  # Pipeline output: character IDs, relabeled columns, EGA communities
  result <- list(
    final_items = data.frame(
      ID = c("4", "1", "3"),
      type = "All",
      attribute = relabeled$attribute[c(4, 1, 3)],
      statement = relabeled$statement[c(4, 1, 3)],
      EGA_com = c(2L, 1L, 2L),
      stringsAsFactors = FALSE
    ),
    initial_items = data.frame(
      ID = as.character(1:4),
      type = "All",
      attribute = relabeled$attribute,
      statement = relabeled$statement,
      EGA_com = c(1L, 1L, 2L, 2L),
      stringsAsFactors = FALSE
    )
  )

  restored <- AIGENIE:::restore_all_together_items(result, items)

  expect_equal(restored$final_items$ID, c(1L, 3L, 4L))
  expect_equal(restored$final_items$type, c("anxiety", "depression", "depression"))
  expect_equal(restored$final_items$attribute, c("worry", "sadness", "hopelessness"))
  expect_equal(restored$final_items$EGA_com, c(1L, 2L, 2L))

  expect_equal(nrow(restored$initial_items), 4L)
  expect_equal(restored$initial_items$type, items$type)
  expect_equal(restored$initial_items$EGA_com, c(1L, 1L, 2L, 2L))

  # Without keep.org the pipeline result has no initial_items
  no_org <- AIGENIE:::restore_all_together_items(result["final_items"], items)
  expect_null(no_org$initial_items)
})


test_that("AIGENIE returns type-level results when the overall fit fails silently", {

  items <- data.frame(
    type = rep(c("anxiety", "depression"), each = 2),
    attribute = c("worry", "nervousness", "sadness", "hopelessness"),
    statement = paste("Item", 1:4),
    stringsAsFactors = FALSE
  )
  type_level <- list(anxiety = list(final_N = 2), depression = list(final_N = 2))

  local_mocked_bindings(
    generate_items_via_llm = function(...) list(items = items, successful = TRUE),
    generate_embeddings = function(...) list(success = TRUE, embeddings = matrix(0)),
    run_item_reduction_pipeline = function(...) list(item_level = type_level, success = TRUE),
    run_pipeline_for_all = function(...) list(overall_result = NULL, success = FALSE),
    .package = "AIGENIE"
  )

  for (quiet in c(TRUE, FALSE)) {
    res <- suppressMessages(AIGENIE(
      item.attributes = test_attributes,
      openai.API = "fake-key-for-test",
      target.N = 30,
      run.overall = TRUE,
      plot = FALSE,
      silently = quiet
    ))
    expect_identical(res, type_level, info = paste("silently =", quiet))
  }
})

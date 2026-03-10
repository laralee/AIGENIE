# tests/testthat/test-validation.R
# ============================================================
# Unit tests for input validation (no API keys required)
# ============================================================

test_that("item.attributes must be a named list of character vectors", {

  # Should fail: unnamed list
  expect_error(
    AIGENIE:::items.attributes_validate(list(c("a", "b"))),
    regexp = "named"
  )

  # Should fail: single-element sublists
  expect_error(
    AIGENIE:::items.attributes_validate(list(trait = "only_one")),
    regexp = "two"
  )

})

test_that("embedding.model_validate recognises known providers", {

  expect_equal(
    AIGENIE:::embedding.model_validate("text-embedding-3-small"),
    "openai"
  )

  expect_equal(
    AIGENIE:::embedding.model_validate("jina-embeddings-v3"),
    "jina"
  )

  expect_equal(
    AIGENIE:::embedding.model_validate("BAAI/bge-small-en-v1.5"),
    "huggingface"
  )

})

test_that("detect_llm_provider resolves aliases correctly", {

  # Sonnet alias → full Anthropic model string
  result <- AIGENIE:::detect_llm_provider(
    "sonnet", anthropic.API = "fake-key-for-test"
  )
  expect_equal(result$provider, "anthropic")
  expect_match(result$model, "claude-sonnet")

  # gpt4o alias → gpt-4o
  result <- AIGENIE:::detect_llm_provider(
    "gpt4o", openai.API = "fake-key-for-test"
  )
  expect_equal(result$provider, "openai")
  expect_equal(result$model, "gpt-4o")

  # llama3 alias → groq
  result <- AIGENIE:::detect_llm_provider(
    "llama3", groq.API = "fake-key-for-test"
  )
  expect_equal(result$provider, "groq")

})

test_that("detect_llm_provider errors without the required API key", {

  expect_error(
    AIGENIE:::detect_llm_provider("gpt-4o"),
    regexp = "API key"
  )

  expect_error(
    AIGENIE:::detect_llm_provider("sonnet"),
    regexp = "API key"
  )

})

test_that("create_system.role returns a non-empty string", {

  sr <- AIGENIE:::create_system.role(
    domain = "psychology", scale.title = "Test",
    audience = NULL, response.options = NULL, system.role = NULL
  )
  expect_type(sr, "character")
  expect_true(nchar(sr) > 0)

})

test_that("create_main.prompts returns a named list matching item.attributes", {

  attrs <- list(trait_a = c("x", "y"), trait_b = c("a", "b"))
  prompts <- AIGENIE:::create_main.prompts(
    item.attributes = attrs,
    item.type.definitions = NULL,
    domain = "test", scale.title = "Test",
    prompt.notes = list(trait_a = "", trait_b = ""),
    audience = NULL, item.examples = NULL
  )

  expect_type(prompts, "list")
  expect_named(prompts, names(attrs))
  expect_true(all(nchar(unlist(prompts)) > 0))

})


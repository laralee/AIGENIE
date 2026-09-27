# tests/testthat/test-sampling-params.R
# ============================================================
# temperature / top.p default to NULL, are only sent when set,
# warn once at validation, and fail fast when rejected.
# (no API keys or Python required)
# ============================================================

test_that("public generation functions default temperature and top.p to NULL", {
  for (nm in c("AIGENIE", "local_AIGENIE", "chat", "local_chat")) {
    fml <- formals(getExportedValue("AIGENIE", nm))
    expect_null(fml$temperature, info = nm)
    expect_null(fml$top.p, info = nm)
  }
})

test_that("sampling_args only includes parameters that are set", {
  expect_identical(AIGENIE:::sampling_args(NULL, NULL), list())
  expect_identical(AIGENIE:::sampling_args(0.7, NULL), list(temperature = 0.7))
  expect_identical(AIGENIE:::sampling_args(NULL, 0.9), list(top_p = 0.9))
  expect_identical(AIGENIE:::sampling_args(1, 1), list(temperature = 1, top_p = 1))
})

test_that("temperature and top.p validators accept NULL and still check ranges", {
  expect_silent(AIGENIE:::temperature_validate(NULL))
  expect_silent(AIGENIE:::top.p_validate(NULL))
  expect_error(AIGENIE:::temperature_validate(3), regexp = "between 0 and 2")
  expect_error(AIGENIE:::top.p_validate(1.5), regexp = "between 0 and 1")
})

test_that("is_sampling_param_error matches the ways providers name the parameters", {
  f <- AIGENIE:::is_sampling_param_error
  expect_true(f("Unsupported parameter: 'temperature' is not supported with this model."))
  expect_true(f("`top_p` cannot be set"))
  expect_true(f("top p is not allowed"))
  expect_true(f("Temperature must be 1"))
  expect_false(f("Rate limit exceeded"))
  expect_false(f("Unsupported parameter: 'max_tokens'"))
})

test_that("warn_sampling_params warns only when set, plus the Anthropic case", {
  expect_silent(AIGENIE:::warn_sampling_params(NULL, NULL, "openai"))
  expect_warning(
    AIGENIE:::warn_sampling_params(0.5, NULL, "openai"),
    regexp = "`temperature`.*Many models no longer accept"
  )

  w <- character()
  withCallingHandlers(
    AIGENIE:::warn_sampling_params(0.5, 0.9, "anthropic"),
    warning = function(cnd) { w <<- c(w, conditionMessage(cnd)); invokeRestart("muffleWarning") }
  )
  expect_length(w, 2L)
  expect_match(w[1], "`temperature` and `top.p`")
  expect_match(w[2], "Anthropic")

  # Only one parameter set for Anthropic -> no extra warning
  expect_warning(AIGENIE:::warn_sampling_params(NULL, 0.9, "anthropic"), regexp = "`top.p`")
})

test_that("validation warns once when sampling parameters are set, even when silent", {

  validate <- function(temperature, top.p) {
    AIGENIE:::validate_user_input_AIGENIE(
      item.attributes = list(a = c("x", "y"), b = c("u", "v")),
      openai.API = "fake-key-for-test", hf.token = NULL, main.prompts = NULL,
      groq.API = NULL, anthropic.API = NULL, jina.API = NULL, model = "gpt4o",
      temperature = temperature, top.p = top.p,
      embedding.model = "text-embedding-3-small",
      target.N = 30, domain = NULL, scale.title = NULL, item.examples = NULL,
      audience = NULL, item.type.definitions = NULL, response.options = NULL,
      prompt.notes = NULL, system.role = NULL, EGA.model = NULL,
      EGA.algorithm = NULL, EGA.uni.method = NULL, keep.org = FALSE,
      items.only = FALSE, embeddings.only = FALSE, adaptive = TRUE,
      run.overall = FALSE, all.together = FALSE, plot = FALSE, silently = TRUE
    )
  }

  expect_no_warning(validate(NULL, NULL))
  expect_warning(validate(0.8, NULL), regexp = "Many models no longer accept")

  w <- character()
  withCallingHandlers(
    AIGENIE:::validate_chat_params(
      prompts = "hi", model = "sonnet", system.role = NULL, openai.API = NULL,
      hf.token = NULL, groq.API = NULL, anthropic.API = "fake-key-for-test",
      reps = 1, top.p = 0.9, temperature = 0.5, max.tokens = 500, silently = TRUE
    ),
    warning = function(cnd) { w <<- c(w, conditionMessage(cnd)); invokeRestart("muffleWarning") }
  )
  expect_length(w, 2L)
  expect_match(w[2], "Anthropic")
})

test_that("generate_text_llm adds a hint to sampling-parameter errors", {
  local_mocked_bindings(
    generate_text_openai = function(...) {
      stop("Unsupported parameter: 'temperature' is not supported with this model.")
    },
    .package = "AIGENIE"
  )
  expect_error(
    AIGENIE:::generate_text_llm("hi", model = "gpt-4o", temperature = 0.5,
                                openai.API = "fake-key-for-test"),
    regexp = "may not accept `temperature` or `top.p`"
  )
})

test_that("item generation and chat fail fast on sampling-parameter errors", {

  calls <- 0L
  local_mocked_bindings(
    ensure_aigenie_python = function(...) invisible(TRUE),
    generate_text_llm = function(...) {
      calls <<- calls + 1L
      stop("Unsupported value: 'top_p' does not support 0.9 with this model.")
    },
    .package = "AIGENIE"
  )

  expect_error(
    AIGENIE:::generate_items_via_llm(
      main.prompts = list(a = "prompt"), system.role = "", model = "gpt-4o",
      top.p = 0.9, temperature = NULL, adaptive = TRUE, silently = TRUE,
      groq.API = NULL, openai.API = "fake-key-for-test", target.N = list(a = 10)
    ),
    regexp = "Item generation stopped.*top_p"
  )
  expect_equal(calls, 1L)

  calls <- 0L
  expect_error(
    suppressWarnings(chat("hi", model = "gpt4o", openai.API = "fake-key-for-test",
                          top.p = 0.9, silently = TRUE)),
    regexp = "API call failed.*top_p"
  )
  expect_equal(calls, 1L)
})

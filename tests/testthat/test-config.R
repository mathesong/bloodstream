# A configuration is written by one version of bloodstream and read by
# another, so reading one means filling in the fields it does not carry and
# translating the names it uses. The failure this prevents is silent: a
# configuration which named the model by its linear rise, read as asking for
# the interpolated one, produces different numbers without saying anything.

test_that("merging runs is the default", {
  expect_true(resolve_config(list())$MergeRuns)
})

test_that("a MergeRuns choice is respected, boxed or not", {
  expect_false(resolve_config(list(MergeRuns = FALSE))$MergeRuns)
  # jsonlite reads a one-element JSON array as a list or a vector
  expect_false(resolve_config(list(MergeRuns = list(FALSE)))$MergeRuns)
  expect_false(resolve_config(list(MergeRuns = c(FALSE)))$MergeRuns)
})

aif <- function(...) list(Model = list(AIF = list(...)))

test_that("the triexponential model's old name selects it, with a linear rise", {
  out <- resolve_config(aif(Method = "Fit Individually: Linear Rise, Triexponential Decay"))
  expect_equal(out$Model$AIF$Method, "Fit Individually: Triexponential Decay")
  # the old name says linear rise, and the config keeps what it asked for
  expect_equal(out$Model$AIF$rise, "linear")
})

test_that("the triexponential model interpolates the rise by default", {
  out <- resolve_config(aif(Method = "Fit Individually: Triexponential Decay"))
  expect_equal(out$Model$AIF$rise, "interp")
})

test_that("a rise named in the config wins, even under the old name", {
  out <- resolve_config(aif(Method = "Fit Individually: Linear Rise, Triexponential Decay",
                            rise = "interp"))
  expect_equal(out$Model$AIF$rise, "interp")
})

test_that("a rise which is not one of the two is refused", {
  expect_error(resolve_config(aif(Method = "Fit Individually: Triexponential Decay",
                                  rise = "spline")))
})

test_that("the other AIF models are left alone, rise included", {
  out <- resolve_config(aif(Method = "Interpolation"))
  expect_equal(out$Model$AIF$Method, "Interpolation")
  expect_null(out$Model$AIF$rise)
})

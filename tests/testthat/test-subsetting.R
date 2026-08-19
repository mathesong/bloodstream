# Subsetting fields are semicolon-separated, and a field may be negated with a
# leading "-". Both rules exist because the failure they prevent is silent: a
# comma makes a value unmatchable, and without negation a user wanting "all but
# these two" has to enumerate everything else and hope they do not miss one.

cfg <- function(...) list(Subsets = list(...))

test_that("a field is split on semicolons", {
  s <- parse_config_subsets(cfg(sub = "H01;H02;P01"))
  expect_setequal(s$sub, c("H01", "H02", "P01"))
  expect_equal(ncol(s), 1)
})

test_that("whitespace around values is ignored", {
  s <- parse_config_subsets(cfg(sub = "H01 ; H02"))
  expect_setequal(s$sub, c("H01", "H02"))
})

test_that("an empty field contributes nothing", {
  s <- parse_config_subsets(cfg(sub = "", ses = "01"))
  expect_equal(colnames(s), "ses")
})

test_that("a comma is refused, with the intended split suggested", {
  expect_error(parse_config_subsets(cfg(sub = "H01;H02, P01")),
               "may not contain commas")
  expect_error(parse_config_subsets(cfg(sub = "H01;H02, P01")),
               'Did you mean:    "H02; P01"')
  # named so the user knows which field to correct
  expect_error(parse_config_subsets(cfg(ses = "01, 02")), "^ses: ")
})

test_that("a leading - marks the field as an exclusion", {
  s <- parse_config_subsets(cfg(sub = "-H01;H02"))
  # exclusions are not rows to join against, so the grid has no sub column
  expect_false("sub" %in% colnames(s))
  expect_equal(attr(s, "exclusions")$sub, c("H01", "H02"))
})

test_that("inclusion and exclusion fields coexist, each reading its own prefix", {
  s <- parse_config_subsets(cfg(sub = "-H01", ses = "01"))
  expect_equal(colnames(s), "ses")
  expect_equal(attr(s, "exclusions")$sub, "H01")
})

test_that("a bare - excludes nothing, and says so", {
  expect_warning(s <- parse_config_subsets(cfg(sub = "-")), "excludes nothing")
  expect_length(attr(s, "exclusions"), 0)
})

# --- applying the result ------------------------------------------------------

meas <- function() {
  tibble::tibble(sub = c("H01", "H02", "P01", "P02"),
                 ses = c("01", "01", "02", NA))
}

test_that("inclusion keeps only the named values", {
  out <- apply_config_subsets(meas(), parse_config_subsets(cfg(sub = "H01;P01")))
  expect_setequal(out$sub, c("H01", "P01"))
})

test_that("exclusion keeps everything else", {
  out <- apply_config_subsets(meas(), parse_config_subsets(cfg(sub = "-H01;H02")))
  expect_setequal(out$sub, c("P01", "P02"))
})

test_that("exclusion keeps measurements lacking the attribute entirely", {
  # a measurement with no session is indeed not ses-01, so excluding "01"
  # must keep it -- whereas including "01" drops it
  excluded <- apply_config_subsets(meas(), parse_config_subsets(cfg(ses = "-01")))
  expect_true(any(is.na(excluded$ses)))
  expect_setequal(excluded$sub, c("P01", "P02"))

  included <- apply_config_subsets(meas(), parse_config_subsets(cfg(ses = "01")))
  expect_false(any(is.na(included$ses)))
})

test_that("an exclusion matching nothing warns but leaves the data complete", {
  expect_warning(
    out <- apply_config_subsets(meas(), parse_config_subsets(cfg(sub = "-NOSUCH"))),
    "matches nothing")
  expect_equal(nrow(out), 4)
})

test_that("subsetting on an attribute the dataset lacks is reported clearly", {
  expect_error(
    apply_config_subsets(meas(), parse_config_subsets(cfg(task = "rest"))),
    "not present in this dataset")
  # and for an exclusion too, which never reaches the join
  expect_error(
    apply_config_subsets(meas(), parse_config_subsets(cfg(task = "-rest"))),
    "not present in this dataset")
})

test_that("no subsetting at all leaves the measurements untouched", {
  out <- apply_config_subsets(meas(), parse_config_subsets(cfg(sub = "")))
  expect_equal(nrow(out), 4)
})

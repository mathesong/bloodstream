# Some tracers are scanned in two blocks from one injection, and those runs
# share a blood curve. BIDS times each run's samples from its own TimeZero, so
# combining them means putting them back on one clock first: an offset read
# from the wrong place, or not applied at all, silently produces a curve which
# doubles back on itself.

bd <- function(times, activity = times, avail_continuous = FALSE,
               continuous_times = times) {

  out <- list(
    Data = list(
      Blood = list(
        Discrete = list(Avail = TRUE,
                        time = list(Units = "s"),
                        Values = tibble::tibble(time = times,
                                                activity = activity)),
        Continuous = if (avail_continuous) {
          list(Avail = TRUE,
               DispersionConstant = 2.5,
               Values = tibble::tibble(time = continuous_times,
                                       activity = continuous_times))
        } else {
          list(Avail = FALSE)
        }),
      Plasma = list(Avail = TRUE,
                    Values = tibble::tibble(time = times,
                                            activity = activity * 2)),
      Metabolite = list(Avail = TRUE,
                        Values = tibble::tibble(time = times,
                                                parentFraction = 1))
    ),
    Models = list(
      Blood = list(Method = "interp", Data = NULL),
      BPR = list(Method = "interp", Data = NULL),
      parentFraction = list(Method = "interp", Data = NULL),
      AIF = list(Method = "interp", Data = NULL)
    ),
    TimeShift = 0
  )

  class(out) <- "blooddata"
  out
}

# --- the clock ----------------------------------------------------------------

test_that("a TimeZero clock time is read as seconds since midnight", {
  expect_equal(bids_clocktime_seconds("10:15:00"), 36900)
  expect_equal(bids_clocktime_seconds("10:15"), 36900)
  expect_equal(bids_clocktime_seconds("00:00:30.5"), 30.5)
})

test_that("a TimeZero which is not a clock time gives no offset", {
  # a dataset timing from its own scan start, rather than from the clock
  expect_true(is.na(bids_clocktime_seconds("0")))
  expect_true(is.na(bids_clocktime_seconds("")))
  expect_true(is.na(bids_clocktime_seconds(NULL)))
  expect_true(is.na(bids_clocktime_seconds("25:00:00")))
})

test_that("offsets are measured from the first run", {
  offsets <- run_time_offsets(list(list(TimeZero = "10:15:00"),
                                   list(TimeZero = "11:20:00")))
  expect_equal(offsets, c(0, 3900))
})

test_that("runs sharing a time zero need no offset", {
  offsets <- run_time_offsets(list(list(TimeZero = "10:15:00"),
                                   list(TimeZero = "10:15:00")))
  expect_equal(offsets, c(0, 0))
})

test_that("a session running past midnight does not read the later run as earlier", {
  offsets <- run_time_offsets(list(list(TimeZero = "23:50:00"),
                                   list(TimeZero = "00:30:00")))
  expect_equal(offsets, c(0, 2400))
})

test_that("no usable TimeZero yields no offsets at all, rather than zeroes", {
  # NULL is distinguishable from c(0, 0), so the caller can say so
  expect_null(run_time_offsets(list(list(TimeZero = "10:15:00"),
                                    list(TimeZero = "0"))))
  expect_null(run_time_offsets(list(NA, list(TimeZero = "10:15:00"))))
})

# --- combining the blood ------------------------------------------------------

test_that("the later run's samples are shifted onto the first run's clock", {
  merged <- merge_blooddata(list(bd(c(1, 2, 3)), bd(c(1, 2, 3))),
                            offsets = c(0, 100))
  expect_equal(merged$Data$Blood$Discrete$Values$time, c(1, 2, 3, 101, 102, 103))
  expect_equal(merged$Data$Plasma$Values$time, c(1, 2, 3, 101, 102, 103))
  expect_equal(merged$Data$Metabolite$Values$time, c(1, 2, 3, 101, 102, 103))
})

test_that("the activities travel with their times", {
  merged <- merge_blooddata(list(bd(c(1, 2), activity = c(10, 20)),
                                 bd(c(1, 2), activity = c(30, 40))),
                            offsets = c(0, 100))
  expect_equal(merged$Data$Blood$Discrete$Values$activity, c(10, 20, 30, 40))
  expect_equal(merged$Data$Plasma$Values$activity, c(20, 40, 60, 80))
})

test_that("the descriptions and units of the first run are kept", {
  merged <- merge_blooddata(list(bd(1:3), bd(1:3)), offsets = c(0, 100))
  expect_equal(merged$Data$Blood$Discrete$time$Units, "s")
  expect_s3_class(merged, "blooddata")
})

test_that("samples landing on a time already taken are dropped, and said so", {
  # what an unseparated pair of runs looks like: no offset to tell them apart
  # (one warning per part of the blood data it happened to)
  warnings <- capture_warnings(
    merged <- merge_blooddata(list(bd(c(1, 2)), bd(c(2, 3))), offsets = c(0, 0)))
  expect_match(warnings, "already taken by another run", all = TRUE)
  expect_equal(merged$Data$Blood$Discrete$Values$time, c(1, 2, 3))
})

test_that("a run without autosampler data contributes none, rather than emptying it", {
  # the usual shape: the autosampler runs for the early block only
  merged <- merge_blooddata(list(bd(c(1, 2), avail_continuous = TRUE),
                                 bd(c(1, 2))),
                            offsets = c(0, 100))
  expect_true(merged$Data$Blood$Continuous$Avail)
  expect_equal(merged$Data$Blood$Continuous$Values$time, c(1, 2))
  expect_equal(merged$Data$Blood$Continuous$DispersionConstant, 2.5)
})

test_that("autosampler data present in a later run only is still shifted", {
  merged <- merge_blooddata(list(bd(c(1, 2)),
                                 bd(c(1, 2), avail_continuous = TRUE)),
                            offsets = c(0, 100))
  expect_true(merged$Data$Blood$Continuous$Avail)
  expect_equal(merged$Data$Blood$Continuous$Values$time, c(101, 102))
})

test_that("no autosampler data anywhere leaves a section which says so", {
  merged <- merge_blooddata(list(bd(1:2), bd(1:2)), offsets = c(0, 100))
  expect_false(merged$Data$Blood$Continuous$Avail)
})

test_that("one run is returned untouched", {
  expect_identical(merge_blooddata(list(bd(1:3))), bd(1:3))
})

test_that("an offset is required for every run", {
  expect_error(merge_blooddata(list(bd(1:2), bd(1:2)), offsets = 0),
               "One offset is needed")
})

# --- combining the measurements -----------------------------------------------

meas <- function(runs = c("01", "02"), subject = "01",
                 timezero = c("10:15:00", "11:20:00")) {

  tibble::tibble(
    sub = subject,
    run = runs,
    filedata = purrr::map(runs, ~tibble::tibble(
      measurement = "blood",
      path = paste0("sub-", subject, "_run-", .x,
                    "_recording-manual_blood.json"))),
    petinfo = purrr::map(timezero, ~list(TimeZero = .x)),
    blooddata = purrr::map(seq_along(runs), ~bd(c(1, 2, 3))),
    pet = paste0("sub-", subject, "_run-", runs)
  )
}

test_that("the runs of one measurement become one row, named for both", {
  out <- merge_runs(meas())
  expect_equal(nrow(out), 1)
  expect_equal(out$merged_runs, "01 + 02")
  # the curve belongs to both runs, so it carries neither's run entity
  expect_true(is.na(out$run))
  expect_equal(out$blooddata[[1]]$Data$Blood$Discrete$Values$time,
               c(1, 2, 3, 3901, 3902, 3903))
})

test_that("the files of every run are carried, so the report can name them", {
  out <- merge_runs(meas())
  expect_equal(nrow(out$filedata[[1]]), 2)
})

test_that("measurements of different subjects are not combined", {
  data <- dplyr::bind_rows(meas(subject = "01"), meas(subject = "02"))
  out <- merge_runs(data)
  expect_equal(nrow(out), 2)
  expect_setequal(out$sub, c("01", "02"))
})

test_that("a measurement with one run is left exactly as it was", {
  data <- meas(runs = "01", timezero = "10:15:00")
  out <- merge_runs(data)
  expect_equal(nrow(out), 1)
  # its run entity is part of its identity, and its filenames keep it
  expect_equal(out$run, "01")
  expect_true(is.na(out$merged_runs))
})

test_that("runs which cannot be placed on a clock are combined as they are, with a warning", {
  warnings <- capture_warnings(out <- merge_runs(meas(timezero = c("0", "0"))))
  expect_match(warnings, "common clock", all = FALSE)
  expect_equal(nrow(out), 1)
  expect_equal(out$merged_runs, "01 + 02")
})

test_that("a study with no run entity at all is untouched", {
  data <- meas()[, setdiff(colnames(meas()), "run")]
  out <- merge_runs(data)
  expect_equal(nrow(out), 2)
  expect_true(all(is.na(out$merged_runs)))
})

test_that("run labels need not be numbers", {
  out <- merge_runs(meas(runs = c("early", "late")))
  expect_equal(out$merged_runs, "early + late")
})

# --- naming the output --------------------------------------------------------

test_that("an entity is dropped with its separator, and nothing else", {
  expect_equal(
    bids_drop_entity("sub-01_ses-02_run-01_recording-manual_blood.json", "run"),
    "sub-01_ses-02_recording-manual_blood.json")
  expect_equal(bids_drop_entity("sub-01_run-early_blood.json", "run"),
               "sub-01_blood.json")
  # a filename with no such entity is its own answer
  expect_equal(bids_drop_entity("sub-01_blood.json", "run"),
               "sub-01_blood.json")
})

test_that("run labels which are numbers are ordered as numbers, not as strings", {
  # BIDS does not require run indices to be zero-padded, so run-10 must not
  # sort ahead of run-2: run_time_offsets() would then read run-2 as crossing
  # midnight and shift its samples by nearly a day
  out <- merge_runs(meas(runs = c("10", "2"),
                         timezero = c("12:00:00", "11:00:00")))
  expect_equal(out$merged_runs, "2 + 10")
  expect_equal(out$blooddata[[1]]$Data$Blood$Discrete$Values$time,
               c(1, 2, 3, 3601, 3602, 3603))
})

test_that("labels which are not numbers order after the numbered ones", {
  expect_equal(c("late", "2", "early", "10")[
    run_label_order(c("late", "2", "early", "10"))],
    c("2", "10", "early", "late"))
  expect_equal(c("02", "01")[run_label_order(c("02", "01"))], c("01", "02"))
})

test_that("runs assumed to share a time zero are checked for overlapping", {
  # no TimeZero to separate them, and sample times which run over each other:
  # the assumption that they already share a zero cannot hold
  warnings <- capture_warnings(merge_runs(meas(timezero = c("0", "0"))))
  expect_match(warnings, "overlap in time", all = FALSE)
})

test_that("runs with no time zero which follow each other are accepted", {
  # the same missing TimeZero, but sample times which do not overlap: taking
  # them as they are is exactly right. run-start is combined after run-end,
  # since the labels give no better order, but whether two runs overlap does
  # not depend on the order they were combined in
  data <- meas(runs = c("start", "end"), timezero = c("0", "0"))
  data$blooddata <- list(bd(c(1, 2, 3)), bd(c(3601, 3602, 3603)))
  warnings <- capture_warnings(out <- merge_runs(data))
  expect_no_match(warnings, "overlap in time", all = TRUE)
  expect_equal(out$blooddata[[1]]$Data$Blood$Discrete$Values$time,
               c(1, 2, 3, 3601, 3602, 3603))
})

test_that("runs whose TimeZeros place them on top of each other are warned about", {
  # TimeZeros half a minute apart, but each run sampled across its own hour:
  # whatever those TimeZeros are, they are not the times the runs began
  data <- meas(timezero = c("11:00:00", "11:00:30"))
  data$blooddata <- list(bd(c(0, 1800, 3600)), bd(c(0, 1800, 3600)))
  warnings <- capture_warnings(merge_runs(data))
  expect_match(warnings, "overlap in time", all = FALSE)
  expect_match(warnings, "TimeZero is the time that run", all = FALSE)
})

test_that("runs placed implausibly far apart are warned about", {
  # run-start sorts after run-end, so these are combined the wrong way round
  # and run-start's samples land nearly a day late: the labels cannot say so,
  # but the gap between the runs can
  warnings <- capture_warnings(
    out <- merge_runs(meas(runs = c("start", "end"),
                           timezero = c("11:00:00", "12:00:00"))))
  expect_match(warnings, "23 hours apart", all = FALSE)
  expect_match(warnings, "Check the run labels", all = FALSE)
})

test_that("runs which follow each other sensibly are not warned about", {
  # an hour apart, in label order
  expect_silent(merge_runs(meas()))
  # a session running past midnight: forty minutes apart, not a day
  expect_silent(merge_runs(meas(timezero = c("23:50:00", "00:30:00"))))
  # runs already sharing a clock, whose samples run on from each other in
  # their own times rather than being offset onto one
  shared <- meas(runs = c("start", "end"), timezero = c("11:00:00", "11:00:00"))
  shared$blooddata[[2]] <- bd(c(3601, 3602, 3603))
  expect_silent(merge_runs(shared))
})

test_that("runs are combined in label order, whatever order they arrived in", {
  # the same pair, listed backwards: the offsets still run forwards
  reversed <- meas(runs = c("02", "01"), timezero = c("11:20:00", "10:15:00"))
  out <- merge_runs(reversed)
  expect_equal(out$merged_runs, "01 + 02")
  expect_equal(out$blooddata[[1]]$Data$Blood$Discrete$Values$time,
               c(1, 2, 3, 3901, 3902, 3903))
})

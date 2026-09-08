# bloodstream 0.2.4

## Combining runs

* **New: multiple runs of a measurement can be combined into one blood curve**,
  for tracers scanned in two blocks from a single injection. Each run's samples
  are placed on the first run's `TimeZero`, and one set of derivatives is
  written out for them, without a `run` entity in the filename. This is the
  default: set the new top-level `MergeRuns` field to `false` if the runs in
  your study are separate injections.

## AIF modelling

* **New: the triexponential AIF model can interpolate the rise through the
  measured samples**, fitting only the decay after the peak. More robust, less
  flexible, and now the default; the new AIF `rise` field chooses `"interp"` or
  `"linear"`. The model is renamed to `Fit Individually: Triexponential Decay`,
  but a config under the old name still selects it, with the linear rise.

* **`expdecay_props` is now passed to the AIF models.** It was read from the
  configuration but never given to the model, so setting it had no effect.

* Requires kinfitr >= 0.9.6.

## The bloodstream-docker wrapper

* **New: a `bloodstream-docker` command-line wrapper**, in `wrapper/`, which
  turns a BIDS-App-style command line into the matching `docker run`
  invocation: `bloodstream-docker /path/to/bids /path/to/derivatives
  participant --config my_config.json --automatic`. It maps the directories
  into the container, creates the derivatives directory before mounting it (an
  absent one is otherwise created by Docker as root, and then cannot be written
  to), checks that Docker is running and that the image is present, and prints
  the command it runs. `--dry-run` prints it without running anything.

* **It generates Apptainer commands too**, with `--apptainer`
  Apptainer shares the host network, so the port is passed as an environment
  variable rather than published, and `/tmp` is bound for report rendering.

* Interactive mode is the default, and needs no paths at all: with no
  arguments, the wrapper launches the config app so a configuration can be
  created without any data. `--port` moves the app off 3838 on both sides at
  once.

## Containers

* **New: an Apptainer definition file** in `apptainer/bloodstream.def`, for
  building the image from source rather than converting the published Docker
  image. The documentation's Singularity page is now the Apptainer page.

* **The interactive app's port is now configurable**, through
  `BLOODSTREAM_SHINY_PORT` or `SHINY_PORT`. If the requested port is taken the
  entrypoint scans upward to the next free one and prints the address to use,
  which matters under Apptainer, where the container shares the host network.

* **New: `--patch` in the wrapper**, which bind-mounts a local bloodstream
  checkout into the container and reinstalls it over the version baked into the
  image, so local changes can be tested without rebuilding.

* **New: `--bids_dir` and `--derivatives_dir` on the container entrypoint**,
  giving explicit paths inside the container instead of the `/data/*` mount
  points. This makes the Apptainer alias workflow possible, where `$HOME` is
  auto-mounted and no binds are needed.

# bloodstream 0.2.3

## Subsetting

* **Commas in a subsetting field are now rejected.** Values are separated by
  semicolons, so `H01;H02, P01` was read as two values, the second of which
  matched nothing and was dropped — leaving an analysis quietly running on
  fewer measurements than were asked for. Such input now stops with the
  intended split suggested.

* **New: exclude rather than include by prefixing a field with `-`.** Writing
  `-test;retest` in `ses` selects every session except those two. The prefix
  applies to the whole field, so a field is either an inclusion or an
  exclusion, never a mixture; each field reads its own prefix independently.
  Note the asymmetry around absent attributes: including `ses = "test"` drops
  measurements that have no session, whereas excluding it keeps them, since a
  measurement with no session is indeed not `ses-test`.

* An excluded value matching nothing **warns** rather than errors: the analysis
  is complete rather than wrong, but you did not remove what you thought you
  had.

* Subsetting on an attribute the dataset does not carry is now reported by
  name, instead of failing inside a join.

* **The report sets a fixed seed.** Model fitting draws random starting values,
  so without a seed a re-run of the same configuration gave slightly different
  numbers. `set.seed(123)` now runs alongside the library calls in both
  templates. This changes numerical output once.


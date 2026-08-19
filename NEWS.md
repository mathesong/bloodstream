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


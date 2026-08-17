# bloodstream 0.2.3

* **The report sets a fixed seed.** Model fitting draws random starting values,
  so without a seed a re-run of the same configuration gave slightly different
  numbers. `set.seed(123)` now runs alongside the library calls in both
  templates. This changes numerical output once.



<!-- README.md is generated from README.Rmd. Please edit that file -->

# blenders

The [`general-meta` branch of
`tidymodels/stacks`](https://github.com/tidymodels/stacks/tree/general-meta)
contains experimental source code for an interface to a generalized
meta-learner in stacks. This repository contains source code for testing
the possible benefits of this functionality.

The `R` folder contains a few helper functions that are utilized in
`inst`. The script in that folder, `data-raw/blenders.Rmd`, contains
source code for generating the dataset supplied with this package. The
dataset, `stack_benchmarks`, contains coarse benchmarks on different
modeling procedures.

``` r
library(tidyverse)
library(blenders)

data(stack_benchmarks)

glimpse(stack_benchmarks)
#> Rows: 40
#> Columns: 6
#> Rowwise: 
#> $ stack        <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, F…
#> $ model_type   <chr> "linear_reg", "boost_tree", "svm_linear", "mlp", "nearest…
#> $ dataset      <chr> "Tree Frogs", "Tree Frogs", "Tree Frogs", "Tree Frogs", "…
#> $ metric       <chr> "rmse", "rmse", "rmse", "rmse", "rmse", "rmse", "rmse", "…
#> $ metric_value <dbl> 56.221954, 55.868331, 56.744354, 57.558454, 56.633912, 14…
#> $ time_to_fit  <dbl> 4.681, 5.576, 4.791, 5.540, 2.255, 4.521, 5.787, 4.387, 6…
```

Notably, the `stack` column indicates whether model stacking was used,
and the `model_type` column indicates the highest-level learner used.
When `stack` is `TRUE`, this refers to the meta-learner. For several
different datasets, we record the time to fit and RMSE value.

``` r
stack_benchmarks %>%
  mutate(
    glmnet_meta = if_else(isTRUE(stack) && model_type == "linear_reg", TRUE, FALSE)
  ) %>%
  ggplot() +
  aes(x = time_to_fit, y = metric_value, col = glmnet_meta) +
  geom_point() +
  facet_grid(dataset ~ stack, scales = "free") +
  labs(x = "Time to Fit", y = "RMSE", col = "glmnet\nMeta-learner")
```

![](README_files/figure-gfm/basic-plot-1.png)<!-- -->

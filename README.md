
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
dataset, `regression_benchmarks`, contains coarse benchmarks on
different modeling procedures.

``` r
library(tidyverse)
library(blenders)

data(regression_benchmarks)

glimpse(regression_benchmarks)
#> Rows: 20
#> Columns: 5
#> $ dataset      <chr> "Concrete", "Concrete", "Concrete", "Concrete", "Concrete…
#> $ meta_learner <chr> "linear_reg", "boost_tree", "svm_linear", "mlp", "nearest…
#> $ time_to_fit  <dbl> 19.017, 24.119, 21.355, 25.684, 14.965, 63.389, 89.097, 7…
#> $ metric       <chr> "rmse", "rmse", "rmse", "rmse", "rmse", "rmse", "rmse", "…
#> $ metric_value <dbl> 7.0923820, 7.1114722, 7.4861566, 16.5378152, 7.3095294, 0…
```

Notably, the `model_type` column indicates the meta-learner learner
used. For several different datasets, we record the time to fit and a
metric value.

``` r
regression_benchmarks %>%
  mutate(
    glmnet_meta = if_else(meta_learner == "linear_reg", TRUE, FALSE)
  ) %>%
  ggplot() +
  aes(x = time_to_fit, y = metric_value, col = glmnet_meta) +
  geom_point() +
  facet_wrap(vars(dataset), scales = "free") +
  labs(x = "Time to Fit", y = "RMSE", col = "glmnet\nMeta-learner")
```

![](README_files/figure-gfm/basic-plot-1.png)<!-- -->

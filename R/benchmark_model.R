#' Ensemble benchmarking
#'
#' A quick and scrappy utility for benchmarking a model stack.
#'
#' @param workflow_set An untrained workflow set containing the base learners
#'   for the model stack.
#' @param data A dataset to benchmark with---will be split into training and
#'   testing, and resampled, internally.
#' @param meta_learner A parsnip model specification giving the model that
#'   will combine the predictions. Should contain specification of
#'   hyperparameters to tune.
#' @param steps A tibble of recipes steps to apply to the data stack. The
#'   first column is a step function, and the second is a quosure giving the
#'   selector (likely as a tidyselect helper). This object structure is
#'   needed since the recipe can't be defined until it has a data structure
#'   to prep on---the recipe is defined after the data stack is constructed.
#'
#' @return A list, with elements
#'
#' * `time_to_fit`: The time to tune over the workflowset (this will change),
#'   construct the data stack, fit the meta-learner, and fit members with
#'   non-zero coefficients.
#' * `metric`: The metric automatically determined by tune.
#' * `metric_value`: The value of that metric.
#'
#' @export
benchmark_model <- function(workflow_set, data, meta_learner, steps) {
  set.seed(1)
  data_split <- rsample::initial_split(data)
  data_train <- rsample::training(data_split)
  data_test  <- rsample::testing(data_split)

  timing <-
    system.time({
      map_res <-
        workflowsets::workflow_map(
          object = workflow_set,
          resamples = rsample::vfold_cv(data_train, v = 10),
          control = stacks::control_stack_grid()
        )

      data_st <-
        stacks::stacks() %>%
        stacks::add_candidates(candidates = map_res)

      if (inherits(meta_learner, "model_spec")) {
        st_rec <- preprocess_data(data_st, steps)

        st_wf <-
          workflows::workflow() %>%
          workflows::add_model(meta_learner) %>%
          workflows::add_recipe(st_rec)
      } else {
        st_wf <- NULL
      }

      res <-
        data_st %>%
        stacks::blend_predictions(meta_learner = st_wf) %>%
        stacks::fit_members()
    })

  metric <- res$model_metrics[[1]]$.metric[[1]]

  res_metric <-
    rlang::call2(
      paste0(metric, "_vec"),
      truth = data_test[[attr(data_st, "outcome")]],
      estimate = predict(res, data_test) %>% dplyr::pull(),
      .ns = "yardstick"
    ) %>%
    rlang::eval_tidy()

  list(time_to_fit = timing[["elapsed"]], metric = metric, metric_value = res_metric)
}


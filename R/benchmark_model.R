# Given a specification of a model and a dataset,
# clock the time to tune + fit the model and a
# simple metric on its predictions.
#
# These methods are purposefully quite inflexible---we want quick,
# analogous benchmarks for somewhat disanalogous modeling workflows.
#' @export
benchmark_model <- function(..., data) {
  UseMethod("benchmark_model")
}

#' @export
benchmark_model.workflow <- function(workflow, data) {
  set.seed(1)
  data_split <- rsample::initial_split(data)
  data_train <- rsample::training(data_split)
  data_test  <- rsample::testing(data_split)

  timing <-
    system.time({
      tune_res <-
        tune::tune_grid(
          object = workflow,
          resamples = rsample::vfold_cv(data_train, v = 5)
        )

      metric_name <- tune::.get_tune_metric_names(tune_res)
      metrics <- tune::.get_tune_metrics(tune_res)

      res <-
        workflow %>%
        tune::finalize_workflow(tune::select_best(tune_res, metric = metric_name[1])) %>%
        tune::last_fit(split = data_split, metrics = metrics)
    })

  list(time_to_fit = timing[["elapsed"]], metric = metric_name[1], metric_value = res$.metrics[[1]]$.estimate[1])
}

# note that the `steps` are the recipe steps for the preprocessor that
# will be applied to the data stack rather than to the original data.
#' @export
benchmark_model.workflow_set <- function(workflow_set, data, meta_learner, steps) {
  set.seed(1)
  data_split <- rsample::initial_split(data)
  data_train <- rsample::training(data_split)
  data_test  <- rsample::testing(data_split)

  timing <-
    system.time({
      map_res <-
        workflow_map(
          object = workflow_set,
          resamples = rsample::bootstraps(data_train, times = 25),
          control = control_stack_grid()
        )

      data_st <-
        stacks() %>%
        add_candidates(candidates = map_res)

      st_rec <- preprocess_data_stack(data_st, steps)

      st_wf <-
        workflow() %>%
        add_model(meta_learner) %>%
        add_recipe(st_rec)

      res <-
        blend_predictions(meta_learner = st_wf) %>%
        fit_members()
    })

  metric <- res$metrics$.metric[[1]]

  res_metric <-
    rlang::call2(
      paste0(metric, "_vec"),
      truth = data_st[attr(data_st, "outcome")],
      estimate = predict(res, data_test) %>% dplyr::pull(),
      .ns = "yardstick"
    )

  list(time_to_fit = timing[["elapsed"]], metric = metric, metric_value = res_metric)
}


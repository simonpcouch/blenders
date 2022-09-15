# Given a specification of a meta-learner and a dataset,
# clock the time to tune + fit the model and a
# simple metric on its predictions.
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


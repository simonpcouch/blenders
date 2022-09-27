#' Ensemble benchmarking
#'
#' A quick and scrappy utility for benchmarking a model stack.
#'
#' @param data_stack A data stack outputted by `stacks::add_candidates`.
#' @param meta_learner A [workflows::workflow] giving the model and recipe that
#'   will combine the predictions. Should contain specification of
#'   hyperparameters to tune.
#'
#' @return A list, with elements
#'
#' * `time_to_fit`: The time to fit the meta-learner, and fit members with non-zero coefficients.
#' * `metric`: The metric automatically determined by tune.
#' * `metric_value`: The value of that metric.
#'
#' @export
benchmark_model <- function(name, data_stack, meta_learner, data_test) {
  library(bonsai)

  if ((!inherits(data_stack, "data_stack"))) {
    rlang::abort("Please supply a data stack as `data_stack`.")
  }

  if (!inherits(meta_learner, "workflow")) {
    rlang::abort("Please supply a workflow as `meta_learner`.")
  }

  timing <-
    system.time({
      res <-
        data_stack %>%
        stacks::blend_predictions(meta_learner = meta_learner) %>%
        stacks::fit_members()
    })

  metric <- res$model_metrics[[1]]$.metric[[1]]

  res_metric <-
    rlang::call2(
      paste0(metric, "_vec"),
      truth = data_test[[attr(data_stack, "outcome")]],
      estimate = predict(res, data_test) %>% dplyr::pull(),
      .ns = "yardstick"
    ) %>%
    rlang::eval_tidy()

  list(
    dataset = name,
    meta_learner = class(extract_spec_parsnip(meta_learner))[[1]],
    time_to_fit = timing[["elapsed"]],
    metric = metric,
    metric_value = res_metric
  )
}


#' @export
fit_stack <- function(workflow_set, meta_learner, steps) {
  data_st <-
    stacks() %>%
    add_candidates(candidates = workflow_set)

  st_rec <- preprocess_data_st(data_st, steps)

  st_wf <-
    workflow() %>%
    add_model(meta_learner) %>%
    add_recipe(st_rec)

  res <-
    blend_predictions(meta_learner = st_wf) %>%
    fit_members()
}

#' @export
preprocess_data <- function(data, steps, outcome = attr(data, "outcome")) {
  form <-
    rlang::new_formula(
      as.name(outcome),
      as.name("."),
      env = rlang::new_environment()
    )

  # make a recipe based on the data stack and add the steps
  if (nrow(steps) > 0) {
    res <-
      purrr::reduce2(.x = steps$steps,
                     .y = steps$selectors,
                     .f = call_step,
                     .init = recipe(form, data = data))
  } else {
    res <-
      recipe(form, data = data)
  }

  res
}

#' @export
call_step <- function(recipe, step_fn, selector) {
  recipe %>% step_fn(!!selector)
}

#' @export
construct_workflow <- function(spec, steps, data, outcome) {
  preprocess_data(data, steps, outcome) %>%
    workflow(spec)
}

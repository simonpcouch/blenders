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

preprocess_data_stack <- function(data_stack, steps) {
  form <-
    rlang::new_formula(
      as.name(attr(data_stack, "outcome")),
      as.name("."),
      env = rlang::base_env()
    )

  # make a recipe based on the data stack and add the steps
  purrr::reduce2(.x = steps$steps,
                 .y = steps$selectors,
                 .f = call_step,
                 .init = recipe(form, data = data_stack))
}

call_step <- function(recipe, step_fn, selector) {
  recipe %>% step_fn(!!selector)
}

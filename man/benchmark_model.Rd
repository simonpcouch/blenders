% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/benchmark_model.R
\name{benchmark_model}
\alias{benchmark_model}
\title{Ensemble benchmarking}
\usage{
benchmark_model(name, data_stack, meta_learner, data_test)
}
\arguments{
\item{data_stack}{A data stack outputted by \code{stacks::add_candidates}.}

\item{meta_learner}{A \link[workflows:workflow]{workflows::workflow} giving the model and recipe that
will combine the predictions. Should contain specification of
hyperparameters to tune.}
}
\value{
A list, with elements
\itemize{
\item \code{time_to_fit}: The time to fit the meta-learner, and fit members with non-zero coefficients.
\item \code{metric}: The metric automatically determined by tune.
\item \code{metric_value}: The value of that metric.
}
}
\description{
A quick and scrappy utility for benchmarking a model stack.
}

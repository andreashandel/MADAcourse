# Prompt 1:
# 
# The code below produces a data frame called syn_dat2.
# Take the data in that data frame and fit a linear model with drug concentration as predictor and cholesterol level as outcome. 
# Also fit a logistic model with drug concentration as predictor and adverse events as outcome.
# For each model, provide model performance diagnostics.
# Use the tidyverse packages for data manipulation tasks, and the tidymodels framework for model fitting.
# For each function call, use explicit notation to specify from which R package the function comes from.
# Add thorough documentation to your code so it's clear what each line of code does.

# COPY AND PASTE synthetic-data-new-R-example-2-code.R HERE  
# You can omit the parts after the data frame has been generated.


# Load the required packages
library(dplyr) # for data manipulation
library(ggplot2) # for data visualization
library(tidymodels) # for modeling

# MANUAL ADDITION:
syn_dat2 <- read.csv(here::here("data","syn_dat2.csv"))


# Fit a linear model with drug concentration as predictor and cholesterol level as outcome
linear_model <- syn_dat2 %>%
  dplyr::mutate(CholesterolLevel = as.numeric(CholesterolLevel)) %>%
  linear_reg() %>%
  set_engine("lm") %>%
  fit(CholesterolLevel ~ DrugConcentration, data = .)

# Print the linear model
print(linear_model)

# Fit a logistic model with drug concentration as predictor and adverse events as outcome
logistic_model <- syn_dat2 %>%
  dplyr::mutate(AdverseEvent = as.factor(AdverseEvent)) %>%
  tidymodels::logistic_reg() %>%
  tidymodels::set_engine("glm") %>%
  tidymodels::fit(AdverseEvent ~ DrugConcentration, data = .)

# Print the logistic model
print(logistic_model)

# Model performance diagnostics
linear_model_diag <- linear_model %>%
  tidymodels::predict(new_data = syn_dat2) %>%
  tidymodels::metrics(truth = syn_dat2$CholesterolLevel, estimate = .pred)

logistic_model_diag <- logistic_model %>%
  tidymodels::predict(new_data = syn_dat2, type = "prob") %>%
  tidymodels::roc_auc(truth = syn_dat2$AdverseEvent, .pred)

# Print the diagnostics
print(linear_model_diag)
print(logistic_model_diag)



# Load the required packages
library(dplyr) # for data manipulation
library(tidymodels) # for modeling

# MANUAL ADDITION:
syn_dat2 <- read.csv(here::here("data","syn_dat2.csv"))



# Specify a linear model with drug concentration as predictor and cholesterol level as outcome
linear_model_spec <- linear_reg() %>% 
  set_engine("lm") %>% 
  set_mode("regression")

# Fit the linear model
linear_model_fit <- fit(linear_model_spec, CholesterolLevel ~ DrugConcentration, data = syn_dat2)

# Print the linear model
print(linear_model_fit)

# Specify a logistic model with drug concentration as predictor and adverse events as outcome
logistic_model_spec <- logistic_reg() %>% 
  set_engine("glm") %>% 
  set_mode("classification")

# Fit the logistic model
# original
logistic_model_fit <- fit(logistic_model_spec, AdverseEvent ~ DrugConcentration, data = syn_dat2)
# manual edit
logistic_model_fit <- fit(logistic_model_spec, as.factor(AdverseEvent) ~ DrugConcentration, data = syn_dat2)

# Print the logistic model
print(logistic_model_fit)

# Model performance diagnostics
linear_model_diag <- linear_model_fit %>% 
  predict(new_data = syn_dat2) %>% 
  bind_cols(syn_dat2) %>% 
  metrics(truth = CholesterolLevel, estimate = .pred)

logistic_model_diag <- logistic_model_fit %>% 
  predict(new_data = syn_dat2, type = "prob") %>% 
  bind_cols(syn_dat2) %>% 
  roc_auc(truth = AdverseEvent, .pred)

# Print the diagnostics
print(linear_model_diag)
print(logistic_model_diag)

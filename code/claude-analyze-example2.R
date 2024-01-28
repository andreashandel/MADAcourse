# Load required libraries
library(tidyverse)
library(tidymodels)
library(broom)

# Read in the CSV data
# ORIGINAL
#data <- read_csv("syn_dat2.csv")
# MANUAL CHANGE
data <- read_csv(here::here('data',"syn_dat2.csv"))

# Linear model ------------------------------------------------------------------------

# Fit linear model 
lm_model <- linear_reg() %>%
  set_engine("lm") %>% 
  fit(CholesterolLevel ~ DrugConcentration, data = data)

# Model diagnostics
tidy(lm_model)  
glance(lm_model)
augment(lm_model, new_data = data)  
resid(lm_model)

# Logistic model -----------------------------------------------------------------------  

# Fit logistic regression model
logit_model <- logistic_reg() %>%
  set_engine("glm") %>%
  fit(AdverseEvent ~ DrugConcentration, data = data)

# Model diagnostics
tidy(logit_model)
glance(logit_model) 
predictions <- augment(logit_model, new_data = data)$.pred  
augment(logit_model, new_data = data, .pred = predictions)
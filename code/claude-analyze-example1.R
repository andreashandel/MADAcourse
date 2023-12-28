# Prompt for Claude
# Includes uploading of sun_dat2.csv



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

# Fit linear model with drug concentration predicting cholesterol level
lm_model <- linear_reg() %>% 
  set_engine("lm") %>%
  fit(CholesterolLevel ~ DrugConcentration, data = data)

# Model diagnostics
tidy(lm_model, conf.int = TRUE) # model estimates
glance(lm_model) # model fit stats like R^2, RMSE
augment(lm_model) # model predictions
resid(lm_model) # model residuals

# Logistic model -----------------------------------------------------------------------

# Fit logistic regression model with drug concentration predicting adverse events
logit_model <- logistic_reg() %>%
  set_engine("glm") %>% 
  fit(AdverseEvent ~ DrugConcentration, data = data)

# Model diagnostics 
tidy(logit_model, conf.int = TRUE)
glance(logit_model)  
augment(logit_model)

# Examine predicted probabilities
predictions <- predict(logit_model, data, type = "prob")[,2]  
augment(logit_model, .pred = predictions)
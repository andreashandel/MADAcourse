# R script to test a model with synthetic data


## ---- ex2-setup --------
# Load the readr package for reading csv data
library(readr)
library(dplyr)
library(here)
library(tidymodels)
library(vip)

# Read in the csv data 
set.seed(123)
data <- read_csv("syn_dat.csv")


## ---- ex2-change-data --------
# Make Cholesterol depend on blood pressure in a nonlinear manner
data$Drug <- runif(nrow(data),min = 100, max = 200)
# making up Cholesterol value as function of Drug
# this equation makes it such that cholesterol depends on drug in a nonlinear manner
data$Cholesterol2 <- sqrt(100^2 + 10* (mean(data$Drug) -  data$Drug)^2)
# plotting correlation between Drug and new cholesterol variables
ggplot(data,aes(x=Drug, y=Cholesterol2)) + geom_point()

## ---- ex2-process-data --------
# select variables of interest
# not strictly needed, but can sometimes make for more robust code to only keep what's necessary
data <- data %>%  
  select(Cholesterol2, Drug, BloodPressure, TreatmentGroup)

# Standardize continuous variables 
# Helps with interpretation of coefficients
data <- data %>% 
  mutate(
    BloodPressure = scale(BloodPressure),
    Drug = scale(Drug),
    Cholesterol2 = scale(Cholesterol2)
  )
# turn TreatmentGroup into a factor
data$TreatmentGroup <- as.factor(data$TreatmentGroup)

# check to make sure data looks ok before fitting
summary(data)

## ---- ex2-fit-model1 --------
# Fit linear model 
model1 <- linear_reg() %>%
  set_engine("lm") %>%
  parsnip::fit(Cholesterol2 ~ Drug + BloodPressure + TreatmentGroup, data = data)
broom::tidy(model1)
broom::glance(model1)

## ---- ex2-fit-model2 --------
# fit a random forest model 
# use the workflow approach from tidymodels
rf_mod <- rand_forest(mode = "regression") %>% 
  set_engine("ranger", importance = "impurity")
# the recipe, i.e., the model to fit
rf_recipe <- 
  recipe(Cholesterol2 ~ Drug + BloodPressure + TreatmentGroup, data = data) 

# set up the workflow
rf_workflow <- 
  workflow() %>% 
  add_model(rf_mod) %>% 
  add_recipe(rf_recipe)

# run the fit
model2 <- rf_workflow %>% 
      fit(data)

# get variable importance
imp <- model2 %>% 
  extract_fit_parsnip() %>% 
  vip()
print(imp)


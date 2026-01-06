# R script to test a model with synthetic data


## ---- setup --------
# Load the readr package for reading csv data
library(readr)
library(dplyr)
library(broom)
library(parsnip)
library(here)

# Read in the csv data 
data <- read_csv("syn_dat.csv")


## ---- process-data --------
# select variables of interest
# not strictly needed, but can sometimes make for more robust code to only keep what's necessary
data <- data %>%  
  select(Cholesterol, BloodPressure, TreatmentGroup)

# Standardize BloodPressure and Cholesterol
# Helps with interpretation of coefficients
data <- data %>% 
  mutate(
    BloodPressure = scale(BloodPressure),
    Cholesterol = scale(Cholesterol)
  )
# turn TreatmentGroup into a factor
data$TreatmentGroup <- as.factor(data$TreatmentGroup)

# check to make sure data looks ok before fitting
summary(data)


## ---- fit-model1 --------
# Fit linear model 
model1 <- linear_reg() %>%
  set_engine("lm") %>%
  parsnip::fit(Cholesterol ~ BloodPressure + TreatmentGroup, data = data)
tidy(model1)
glance(model1)

## ---- fit-model2 --------
# fit a model with interaction
model2 <- linear_reg() %>%
  set_engine("lm") %>%
  parsnip::fit(Cholesterol ~ BloodPressure + TreatmentGroup + BloodPressure*TreatmentGroup , data = data)
tidy(model2)
glance(model2)

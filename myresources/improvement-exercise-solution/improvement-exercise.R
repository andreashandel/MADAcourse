## ---- packages --------
library(tidymodels)
library(readr)
library(dplyr)
library(ggplot2)

## ---- load-data --------
dat <- readr::read_rds("mavoglurant.rds")
set.seed(1234)

## ---- split-data --------
# Put 3/4 of the data into the training set 
data_split <- initial_split(dat, prop = 3/4)

# Create data frames for the two sets:
train_data <- training(data_split)
test_data  <- testing(data_split)



mod <- linear_reg() %>% set_engine("lm")
wflow <- 
  workflow() %>% 
  add_model(mod) %>% 
  add_formula(Y ~ DOSE)
fit1 <- wflow %>% fit(data = train_data)

# get predictions for both train and test data
pred_train <- predict(fit1, train_data)
pred_test <- predict(fit1, test_data)

# compute RMSE for train data
rmse_train <- pred_train %>% 
  bind_cols(train_data) %>% 
  metrics(truth = Y, estimate = .pred)
print(rmse_train)

# compute of RMSE for test data
rmse_test <- pred_test %>% 
  bind_cols(test_data) %>% 
  metrics(truth = Y, estimate = .pred)
print(rmse_test)

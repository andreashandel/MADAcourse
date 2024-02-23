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


## ---- fit-data-linear --------
mod <- linear_reg() %>% set_engine("lm")
wflow <- 
  workflow() %>% 
  add_model(mod) %>% 
  add_formula(Y ~ DOSE)

fit1 <- wflow %>% fit(data = train_data)

pred_train <- predict(fit1, train_data)
pred_test <- predict(fit1, test_data)


rmse_train <- pred_train %>% 
  bind_cols(train_data) %>% 
  metrics(truth = Y, estimate = .pred)
print(rmse_train)

rmse_test <- pred_test %>% 
  bind_cols(test_data) %>% 
  metrics(truth = Y, estimate = .pred)
print(rmse_test)



lin_mod <- linear_reg() %>% set_engine("lm")
linfit1 <- lin_mod %>% fit(Y ~ DOSE, data = dat)
linfit2 <- lin_mod %>% fit(Y ~ ., data = dat)
# Compute the RMSE and R squared for each model
metrics_1 <- linfit1 %>% 
  predict(dat) %>% 
  bind_cols(dat) %>% 
  metrics(truth = Y, estimate = .pred)
metrics_2 <- linfit2 %>% 
  predict(dat) %>% 
  bind_cols(dat) %>% 
  metrics(truth = Y, estimate = .pred)
# Print the results
print(metrics_1)
print(metrics_2)


## ---- fit-data-logistic --------
logfit1 <- log_mod %>% fit(SEX ~ DOSE, data = dat)
logfit2 <- log_mod %>% fit(SEX ~ ., data = dat)
# Compute the accuracy and AUC for each model
m1_acc <- logfit1 %>% 
  predict(dat) %>% 
  bind_cols(dat) %>% 
  metrics(truth = SEX, estimate = .pred_class) %>% 
  filter(.metric == "accuracy") 
m1_auc <-  logfit1 %>%
      predict(dat, type = "prob") %>%
      bind_cols(dat) %>%
      roc_auc(truth = SEX, .pred_1)
m2_acc <- logfit2 %>% 
  predict(dat) %>% 
  bind_cols(dat) %>% 
  metrics(truth = SEX, estimate = .pred_class) %>% 
  filter(.metric %in% c("accuracy"))
m2_auc <-  logfit2 %>%
  predict(dat, type = "prob") %>%
  bind_cols(dat) %>%
  roc_auc(truth = SEX, .pred_1)
# Print the results
print(m1_acc)
print(m1_auc)
print(m2_acc)
print(m2_auc)

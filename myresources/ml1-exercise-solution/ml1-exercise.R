## ---- packages --------
library(tidymodels)
library(glmnet)
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

## ---- model1 --------
mod <- linear_reg() %>% set_engine("lm")
wflow1 <- 
  workflow() %>% 
  add_model(mod) %>% 
  add_formula(Y ~ DOSE)
fit1 <- wflow1 %>% fit(data = train_data)


## ---- model2 --------
wflow2 <- wflow1 %>% update_formula(Y ~ .)
fit2 <- wflow2 %>% fit(data = train_data)


## ---- preds --------
pred1 <- fit1 %>% predict(train_data)
pred2 <- fit2 %>% predict(train_data)


## ---- rmse --------
# Compute the RMSE and R squared for model 1
rmse_train_1 <-  bind_cols(train_data, pred1) %>% 
  rmse(truth = Y, estimate = .pred) %>% mutate(model = "model 1")

# Compute the RMSE and R squared for model 2
rmse_train_2 <- bind_cols(train_data, pred2) %>% 
  rmse(truth = Y, estimate = .pred) %>% mutate(model = "model 2")

# Compute RMSE for a dumb null model
rmse_train_0 <- rmse_vec(truth = train_data$Y, estimate = rep(mean(train_data$Y),nrow(train_data)))

# Print the results
metrics = data.frame(model = c("null","model 1","model 2"), rmse = c(rmse_train_0, rmse_train_1$.estimate, rmse_train_2$.estimate) )
print(metrics)

## ---- cross-validation --------
set.seed(1234)
folds <- vfold_cv(train_data, v = 10)

fit1_cv <- wflow1 %>% fit_resamples(folds)
fit2_cv <- wflow2 %>% fit_resamples(folds)
# pulls out the RMSE from what collect_metrics returns
rmse_cv_1 <- collect_metrics(fit1_cv)$mean[1]
rmse_cv_2 <- collect_metrics(fit2_cv)$mean[1]

# Print the results
metrics_cv = data.frame(model = c("null","model 1","model 2"), rmse = c(rmse_train_0, rmse_cv_1, rmse_cv_2) )
print(metrics_cv)
















## ---- obs-pred-plot --------
plot_data1 <- bind_cols(test_data, pred1) %>%
  rename(observed = Y, predicted = .pred)

plot_data2 <- bind_cols(test_data, pred2) %>%
  rename(observed = Y, predicted = .pred)

ggplot(plot_data1, aes(x = observed, y = predicted)) +
  geom_point() +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "red") +
  labs(x = "Observed", y = "Predicted", title = "Model 1: Predicted vs Observed") +
  theme_minimal()

ggplot(plot_data2, aes(x = observed, y = predicted)) +
  geom_point() +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "red") +
  labs(x = "Observed", y = "Predicted", title = "Model 2: Predicted vs Observed") +
  theme_minimal()



## ---- plot --------

bootstraps(dat)
















## ---- model3 --------
rec <- recipe(Y ~ ., data = train_data) %>%
  step_center(all_predictors(), -all_nominal()) %>%
  step_dummy(all_nominal()) %>%
  prep()

lasso_mod <- linear_reg(mode = "regression", penalty = tune(), mixture = 1) %>%
  set_engine("glmnet")

wflow3 <- workflow() %>%
  add_model(lasso_mod) %>%
  add_recipe(rec)

folds <- rsample::vfold_cv(train_data, v = 5)
my_grid <- tibble(penalty = 10^seq(-5, -1, length.out = 30))

fit3 <- wflow3 %>%
        tune_grid(resamples = folds, 
                  grid = my_grid, 
                  control = control_grid(verbose = FALSE, save_pred = TRUE), 
                  metrics = metric_set(rmse))


# Collect the metrics from the tuned model
tune_results <- fit3 %>% collect_metrics()

# Plot RMSE versus penalty
ggplot(tune_results, aes(x = penalty, y = mean)) +
  geom_line() +
  geom_point() +
  scale_x_log10(labels = scales::label_number()) +
  labs(x = "Penalty", y = "RMSE", title = "Model Performance vs Tuning Parameter")



  
best_mod <- fit3 %>% select_best("rmse")
print(best_mod)

# Update the workflow with the optimal penalty
final_wf <- finalize_workflow(wflow3, best_mod)

# Apply the workflow to the training data to get the final model
final_mod <- fit(final_wf, data = train_data) %>% extract_fit_parsnip()

# Plot performance (RMSE) against penalty
penalty_vs_rmse <- as.data.frame(final_mod$fit$glmnet.fit$lambda) %>%
  mutate(RMSE = fit3$mean_rmse) %>%
  ggplot(aes(x = log(penalty), y = RMSE)) +
  geom_line() +
  labs(x = "Log Penalty", y = "RMSE", title = "Performance vs. Penalty for LASSO") +
  theme_minimal()

print(penalty_vs_rmse)

  
best <- fit3 %>% show_best("rmse")

lr_plot <- 
  fit3 %>% 
  collect_metrics() %>% 
  ggplot(aes(x = penalty, y = mean)) + 
  geom_point() + 
  geom_line()


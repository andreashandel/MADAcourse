## ---- packages --------
library(tidyverse)
library(tidymodels)
library(here)
library(ggcorrplot)
library(glmnet)
library(ranger)


## ---- load-data --------
rngseed = 1234
df_raw <- readr::read_rds("mavoglurant.rds")



## ---- race-recoding --------
# These are the meanings of the numbers, which one can work out from the information 
# given in table 1 of this paper: https://link.springer.com/article/10.1007/s11095-014-1574-1
# matching their frequencies to the frequencies in our data gives the following:
# 1 = Caucasian , 2 = Black), 7 = Native American, 88 = Other 
df1 <- df_raw %>%
  mutate(RACE = forcats::fct_collapse(RACE,
                             `3` = c('7', '88')))




## ---- correlations --------
# remove categorical variables for correlation plot
cplot <- df1 |>
  # Drop non-numeric variables
  dplyr::select(dplyr::where(is.numeric)) |>
  # Compute the correlation matrix
  cor(method = "pearson") |>
  # Make the plot
  ggcorrplot::ggcorrplot(
    type = "full",
    lab = TRUE
  )
plot(cplot)



## ---- bmi --------
# it looks like weight is in kg and height in meters in this dataset
df1$BMI <- df1$WT / df1$HT^2
# check to make sure it looks reasonable
summary(df1$BMI)



## ---- model1 --------
set.seed(rngseed)
mod1 <- linear_reg(mode = "regression") %>% set_engine("lm")
wflow1 <- workflow() %>% 
  add_model(mod1) %>% 
  add_formula(Y ~ .)
fit1 <- wflow1 %>% fit(data = df1)

## ---- model2 --------
mod2 <- linear_reg(mode = "regression", penalty = 0.1, mixture = 1) %>%
  set_engine("glmnet")
wflow2 <- workflow() %>% 
  add_model(mod2) %>% 
  add_formula(Y ~ .)  
fit2 <- wflow2 %>% fit(data = df1)


## ---- model3 --------
mod3 <- rand_forest(mode = "regression") %>%
  set_engine("ranger")
wflow3 <- workflow() %>% 
  add_model(mod3) %>% 
  add_formula(Y ~ .) 
fit3 <- wflow3 %>% fit(data = df1)


## ---- preds --------
pred1 <- fit1 %>% predict(df1)
pred2 <- fit2 %>% predict(df1)
pred3 <- fit3 %>% predict(df1)


# Compute the RMSE 
rmse_train_1 <-  bind_cols(df1, pred1) %>% 
  rmse(truth = Y, estimate = .pred) 
rmse_train_2 <- bind_cols(df1, pred2) %>% 
  rmse(truth = Y, estimate = .pred) 
rmse_train_3 <- bind_cols(df1, pred3) %>% 
  rmse(truth = Y, estimate = .pred) 

# Print the results
metrics = data.frame(model = c("linear","LASSO","RF"), 
                     rmse = c(rmse_train_1$.estimate, 
                              rmse_train_2$.estimate,
                              rmse_train_3$.estimate) )

print(metrics)

# make a plot
pred1a <- data.frame(predicted = pred1$.pred, model = "linear")
pred2a <- data.frame(predicted = pred2$.pred, model = "LASSO")
pred3a <- data.frame(predicted = pred3$.pred, model = "RF")

plot_data <- bind_rows(pred1a,pred2a,pred3a) %>% 
  mutate(observed = rep(df1$Y,3)) 

p1 <- plot_data %>% ggplot() +
  geom_point(aes(x = observed, y = predicted, color = model, shape = model)) +
  labs(x = "Observed", y = "Predicted", title = "Predicted vs Observed") +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "black") +
  scale_x_continuous(limits=c(0,5000)) +
  scale_y_continuous(limits=c(0,5000)) +
  theme_minimal()
plot(p1)


## ---- lasso-tuning --------
lasso_tune <- linear_reg(penalty = tune(), mixture = 1) %>%  set_engine("glmnet")

wflow_m2_t1 <- workflow() %>% 
  add_model(lasso_tune) %>% 
  add_formula(Y ~ .)  

# make an object that one can use for tuning that's just the data
dfs <- apparent(df1)

# set up a grid of values to tune over
lasso_grid  <- tibble(penalty = 10^seq(-5, 2, length.out = 50))

lasso_tune <- tune_grid(
  wflow_m2_t1,
  resamples = dfs,
  grid = lasso_grid
)

# plot of performance
autoplot(lasso_tune, metric = "rmse")

# get best model
best_param <- select_best(lasso_tune, metric = "rmse")
best_lasso <- lasso_tune %>%
  filter_parameters(parameters = best_param) %>%
  collect_metrics()
print(best_lasso)


## ---- RF-tuning --------
rf_tune <- rand_forest(
  mtry = tune(),
  trees = 300,
  min_n = tune()
) |>
  set_mode("regression") |>
  set_engine("ranger")

wflow_m3_t1 <- workflow() %>% 
  add_model(rf_tune) %>% 
  add_formula(Y ~ .)  

# set up a grid of values to tune over
rf_grid  <- grid_regular(
              mtry(range = c(1, 7)),
              min_n(range = c(1, 21)), 
              levels = 7)

rf_tune <- tune_grid(
  wflow_m3_t1,
  resamples = dfs,
  grid = rf_grid
)

autoplot(rf_tune, metric = "rmse")

# look at best performing model
best_param <- select_best(rf_tune, metric = "rmse")
best_rf <- rf_tune %>%
  filter_parameters(parameters = best_param) %>%
  collect_metrics()
print(best_rf)


# set up CV
set.seed(rngseed)
folds <- vfold_cv(df1, v = 5, repeats = 5)

## ---- LASSO-tuning-CV --------
# tune LASSO with CV
lasso_tune_CV <- tune_grid(
  wflow_m2_t1,
  resamples = folds,
  grid = lasso_grid
)
autoplot(lasso_tune_CV)

# get best model
best_lasso_param <- select_best(lasso_tune_CV, metric = "rmse")
best_lasso <- lasso_tune_CV %>%
  filter_parameters(parameters = best_lasso_param) %>%
  collect_metrics()
print(best_lasso)


## ---- RF-tuning-CV --------
# tune RFwith CV
rf_tune_CV <- tune_grid(
  wflow_m3_t1,
  resamples = folds,
  grid = rf_grid
)
autoplot(rf_tune_CV)


# get best model
best_param <- select_best(rf_tune_CV, metric = "rmse")
best_rf <- rf_tune_CV %>%
  filter_parameters(parameters = best_param) %>%
  collect_metrics()
print(best_rf)


# ## ---- LASSO-exploration --------
# 
# # Finalize workflow with best values
# final_lasso_wf <- wflow_m2_t1 |>
#   finalize_workflow(best_param)
# # Fit model to training data
# lasso_train_fit <- final_lasso_wf |> fit(data = df1)
# 
# x <- extract_fit_engine(lasso_train_fit)
# 
# plot(x, "lambda")

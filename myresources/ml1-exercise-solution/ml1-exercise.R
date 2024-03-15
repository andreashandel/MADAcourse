## ---- packages --------
library(tidymodels)
#library(glmnet)
library(readr)
library(dplyr)
library(forcats)
library(ggplot2)


## ---- load-data --------
df_raw <- readr::read_rds("mavoglurant.rds")
set.seed(1234)


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
df1_tmp <- df1 %>% dplyr::select(-c(RACE,SEX))
cplot <- corrr::correlate(df1_tmp) %>% corrr::rplot(print_cor = TRUE)
ctab <- corrr::correlate(df1_tmp) %>% corrr::fashion()
plot(cplot)
print(ctab)



## ---- bmi --------
# it looks like weight is in kg and height in meters in this dataset
df1$BMI <- df1$WT / df1$HT^2
# check to make sure it looks reasonable
summary(df1$BMI)



## ---- model1 --------
mod1 <- linear_reg(mode = "regression") %>% set_engine("lm")
wflow1 <- 
  workflow() %>% 
  add_model(mod1) %>% 
  add_formula(Y ~ .)
fit1 <- wflow1 %>% fit(data = df1)



## ---- model2 --------
mod2 <- linear_reg(mode = "regression", penalty = 0.1, mixture = 1) %>%
  set_engine("glmnet")
wflow2 <- 
  workflow() %>% 
  add_model(mod2) %>% 
  add_formula(Y ~ .) %>% 
fit2 <- wflow2 %>% fit(data = df1)


## ---- model3 --------
mod3 <- rand_forest(mode = "regression") %>%
  set_engine("ranger")
wflow3 <- workflow() %>% 
  add_model(mod3) %>% 
  add_formula(Y ~ .) 
fit3 <- wflow3 %>% fit(data = df1)



folds <- rsample::vfold_cv(df, v = 5, repeat = 5)

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


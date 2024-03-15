## ---- packages --------
library(tidymodels)
library(glmnet)
library(readr)
library(dplyr)
library(ggplot2)

## ---- load-data --------
dat <- readr::read_rds("mavoglurant.rds")
set.seed(1234)

## ---- load-data --------
dat$RACE <- NULL

## ---- split-data --------
# Put 3/4 of the data into the training set 
data_split <- initial_split(dat, prop = 3/4)

# Create data frames for the two sets:
train_data <- training(data_split)
test_data  <- testing(data_split)
# record number of observations in each dataset, need that later
Ntrain = nrow(train_data)
Ntest = nrow(test_data)

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
# null model, only predicts the mean for everyone
pred0 <- rep(mean(train_data$Y),Ntrain)

## ---- rmse --------
# Compute the RMSE and R squared for model 1
rmse_train_1 <-  bind_cols(train_data, pred1) %>% 
  rmse(truth = Y, estimate = .pred) 

# Compute the RMSE and R squared for model 2
rmse_train_2 <- bind_cols(train_data, pred2) %>% 
  rmse(truth = Y, estimate = .pred) 

# Compute RMSE for a dumb null model
rmse_train_0 <-  rmse_vec(truth = train_data$Y, estimate = pred0) 

# Print the results
metrics = data.frame(model = c("null model","model 1","model 2"), 
                     rmse = c(rmse_train_0, 
                              rmse_train_1$.estimate, 
                              rmse_train_2$.estimate) )
print(metrics)

## ---- cross-validation --------
set.seed(1234)
folds <- vfold_cv(train_data, v = 10, repeats = 1)

fit1_cv <- wflow1 %>% fit_resamples(folds)
fit2_cv <- wflow2 %>% fit_resamples(folds)
# pulls out the RMSE from what collect_metrics returns
rmse_cv_1 <- collect_metrics(fit1_cv)$mean[1]
rmse_cv_2 <- collect_metrics(fit2_cv)$mean[1]

# Print the results
metrics_cv = data.frame(model = c("null","model 1","model 2"), 
                        rmse = c(rmse_train_0, rmse_cv_1, rmse_cv_2) )
print(metrics_cv)

## ---- obs-pred-plot --------
pred0a <- data.frame(predicted = pred0, model = "model 0")
pred1a <- data.frame(predicted = as.numeric(unlist(pred1)), model = "model 1")
pred2a <- data.frame(predicted = as.numeric(unlist(pred2)), model = "model 2")

plot_data <- bind_rows(pred0a,pred1a,pred2a) %>% 
  mutate(observed = rep(train_data$Y,3)) 

p1 <- plot_data %>% ggplot() +
  geom_point(aes(x = observed, y = predicted, color = model, shape = model)) +
  labs(x = "Observed", y = "Predicted", title = "Predicted vs Observed") +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "black") +
  scale_x_continuous(limits=c(0,5000)) +
  scale_y_continuous(limits=c(0,5000)) +
  theme_minimal()
plot(p1)






## ---- bootstrap --------
Nsamp = 100 #number of samples
# create samples
dat_bs <- train_data |> rsample::bootstraps(times = Nsamp, apparent = TRUE)

#set up empty arrays to store predictions for each sample
pred_bs = array(0, dim=c(Nsamp,Ntrain))

#loop over each bootstrap sample, fit model, then predict and record predictions
for (i in 1:Nsamp)
{
  dat_sample = rsample::analysis(dat_bs$splits[[i]])
  fit_bs <- wflow2 |> fit(data = dat_sample)
  pred_bs[i,] <- fit_bs %>% predict(train_data) %>% unlist()
}

#compute mean and 89% confidence interval for predictions
preds <- pred_bs |> apply(2, quantile,  c(0.055, 0.5, 0.945)) |>  t()

#make new plot
plot_data2 <- data.frame(mean = preds[,2], lb = preds[,1], 
                         ub = preds[,3], observed = rep(train_data$Y,3)) 

p2 <- plot_data2 %>% ggplot() +
  geom_point(aes(x = observed, y = mean)) +
  geom_point(aes(x = observed, y = lb), shape = 4, color = "red") +
  geom_point(aes(x = observed, y = ub), shape = 4,  color = "red") +
  labs(x = "Observed", y = "Predicted", title = "Predicted vs Observed") +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "black") +
  scale_x_continuous(limits=c(0,5000)) +
  scale_y_continuous(limits=c(0,5000)) +
  theme_minimal()
plot(p2)



## ---- final testing --------
predf <- fit2 %>% predict(test_data) %>%
         data.frame(predicted = as.numeric(unlist(predf)), model = "m2 test")

plot_f <- predf %>% mutate(observed = rep(test_data$Y,1)) 

p2 <- ggplot() +
  geom_point(aes(x = observed, y = predicted), data = plot_data, color="black") +
  geom_point(aes(x = observed, y = predicted), data = plot_f, color="red") +
  labs(x = "Observed", y = "Predicted", title = "Predicted vs Observed") +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "black") +
  scale_x_continuous(limits=c(0,5000)) +
  scale_y_continuous(limits=c(0,5000)) +
  theme_minimal()
plot(p2)


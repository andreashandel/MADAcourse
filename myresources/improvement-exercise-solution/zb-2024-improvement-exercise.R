
# MODEL FITTING PART ===========================================================
## ---- packages --------
library(tidymodels)
library(readr)
library(dplyr)
library(ggplot2)

## ---- load-data --------
rawdat <- readr::read_csv("Mavoglurant_A2121_nmpk.csv")

## ---- explore-data --------
summary(rawdat)
skimr::skim(rawdat)
p1 <- rawdat %>% ggplot() +
	geom_line( aes( x = TIME, y = DV, group = as.factor(ID), color = as.factor(DOSE)) ) +
	facet_wrap( ~ DOSE, scales = "free_y")
plot(p1)

## ---- process-data --------
# remove those with OCC = 2
dat1 <- rawdat %>% filter(OCC == 1)

# total drug as a sum
dat_y <-  dat1 %>% filter((AMT == 0)) %>%
	group_by(ID) %>% 
	dplyr::summarize(Y = sum(DV)) 

#keep only time = 0 entry, it contains all we need
dat_t0 <- dat1 %>% filter(TIME == 0)

# merge data  
dat_merge <- left_join(dat_y, dat_t0)

# keep only useful variables
# also convert SEX and RACE to factors
dat <- dat_merge %>% select(Y,DOSE,AGE,SEX,RACE,WT,HT) %>% mutate_at(vars(SEX,RACE), factor) 
readr::write_rds(dat,"mavoglurant.rds")


# fit the linear models with Y as outcome 
# first model has only DOSE as predictor
# second model has all variables as predictors
lin_mod <- linear_reg() %>% set_engine("lm")
linfit1 <- lin_mod %>% fit(Y ~ DOSE, data = dat)
linfit2 <- lin_mod %>% fit(Y ~ ., data = dat)

# Compute the RMSE and R squared for model 1
metrics_1 <- linfit1 %>% 
	predict(dat) %>% 
	bind_cols(dat) %>% 
	metrics(truth = Y, estimate = .pred)

# Compute the RMSE and R squared for model 2
metrics_2 <- linfit2 %>% 
	predict(dat) %>% 
	bind_cols(dat) %>% 
	metrics(truth = Y, estimate = .pred)

# Print the results
print(metrics_1)
print(metrics_2)


## ---- fit-data-logistic --------
# fit the logistic models with SEX as outcome 
# first model has only DOSE as predictor
# second model has all variables as predictors
log_mod <- logistic_reg() %>% set_engine("glm")
logfit1 <- log_mod %>% fit(SEX ~ DOSE, data = dat)
logfit2 <- log_mod %>% fit(SEX ~ ., data = dat)

# Compute the accuracy and AUC for model 1
m1_acc <- logfit1 %>% 
	predict(dat) %>% 
	bind_cols(dat) %>% 
	metrics(truth = SEX, estimate = .pred_class) %>% 
	filter(.metric == "accuracy") 
m1_auc <-  logfit1 %>%
	predict(dat, type = "prob") %>%
	bind_cols(dat) %>%
	roc_auc(truth = SEX, .pred_1)

# Compute the accuracy and AUC for model 2
m2_acc <- logfit2 %>% 
	predict(dat) %>% 
	bind_cols(dat) %>% 
	metrics(truth = SEX, estimate = .pred_class) %>% 
	filter(.metric %in% c("accuracy"))
m2_auc <-  logfit2 %>%
	predict(dat, type = "prob") %>%
	bind_cols(dat) %>%
	roc_auc(truth = SEX, .pred_1)

met <- metric_set(roc_auc, accuracy)

augment(logfit2, dat) |>
	met(truth = SEX, estimate = .pred_class, .pred_1)

# Print the results
print(m1_acc)
print(m2_acc)
print(m1_auc)
print(m2_auc)

# MODEL IMPROVEMENT PART =======================================================

# Remove the race variable
mi_dat <- dat |>
	dplyr::select(-RACE)

# Train/test split
dat_split <-
	rsample::initial_split(mi_dat, prop = 0.75)

dat_train <- training(dat_split)
dat_test <- testing(dat_split)

# Fit the models to training data only
linfit1 <- lin_mod %>% fit(Y ~ DOSE, data = dat_train)
linfit2 <- lin_mod %>% fit(Y ~ ., data = dat_train)

# Get the null model and preds
null_mod <- parsnip::null_model(mode = "regression") |> set_engine("parsnip")
null_fit <- null_mod |> fit(Y ~ ., data = dat_train)
null_preds <- augment(null_fit, dat_train)

# Get the predictions
linfit1_preds <- augment(linfit1, dat_train)
linfit2_preds <- augment(linfit2, dat_train)

# Get the RMSE
rmse(null_preds, truth = Y, estimate = .pred)
rmse(linfit1_preds, truth = Y, estimate = .pred)
rmse(linfit2_preds, truth = Y, estimate = .pred)

# Set up 10-fold cross validation
set.seed(309123)
folds <- vfold_cv(dat_train, v = 10)

# Set up the workflows
null_wf <- workflow() |>
	add_model(null_mod) |>
	add_formula(Y ~ .)

linfit1_wf <- workflow() |>
	add_model(lin_mod) |>
	add_formula(Y ~ DOSE)

linfit2_wf <- workflow() |>
	add_model(lin_mod) |>
	add_formula(Y ~ .)

# Set up the metrics
my_metrics <- metric_set(rmse)

# Evaluate performance of each model on resamples
null_res <-
	null_wf |>
	fit_resamples(resamples = folds, metrics = my_metrics)

linfit1_res <-
	linfit1_wf |>
	fit_resamples(resamples = folds, metrics = my_metrics)

linfit2_res <-
	linfit2_wf |>
	fit_resamples(resamples = folds, metrics = my_metrics)

# View the metrics
collect_metrics(null_res)
collect_metrics(linfit1_res)
collect_metrics(linfit2_res)

# We would still select the model will all predictors, but now we can see that
# the RMSE of linfit1 and linfit2 have SE's that overlap, indicating that the
# performance of linfit2 is not too much better. If we used, e.g., the 1-SE
# rule for selection, we would select the model with only dose.

# Run that code again to see new values
set.seed(156461)
folds <- vfold_cv(dat_train, v = 10)
null_res <-
	null_wf |>
	fit_resamples(resamples = folds, metrics = my_metrics)

linfit1_res <-
	linfit1_wf |>
	fit_resamples(resamples = folds, metrics = my_metrics)

linfit2_res <-
	linfit2_wf |>
	fit_resamples(resamples = folds, metrics = my_metrics)

# View the metrics
collect_metrics(null_res)
collect_metrics(linfit1_res)
collect_metrics(linfit2_res)

# Now linfit2 seems even a little bit better. This is a problem we could solve
# by adding repeats to our CV scheme -- in fact Frank Harrell suggests that
# for biomedical applications, 100 repeats of CV is often needed to ensure
# most of the random error is accounted for.

# Model predictions -------------------------------------------------------

# This section added by ZANE
comb_preds <- dplyr::bind_rows(
	"null" = null_preds,
	"lin1" = linfit1_preds,
	"lin2" = linfit2_preds,
	.id = "model"
)

# Plot predicted vs observed
comb_preds |>
	ggplot() +
	aes(x = Y, y = .pred) +
	geom_abline(slope = 1, intercept = 0) +
	geom_point() +
	facet_wrap(vars(model)) +
	coord_cartesian(xlim = c(0, 5000), ylim = c(0, 5000))

# Plot the residuals -- not because it said to, for my own curiousity
comb_preds |>
	ggplot() +
	aes(x = .pred, y = .resid) +
	geom_hline(yintercept = 0) +
	geom_point() +
	facet_wrap(vars(model)) +
	coord_cartesian(xlim = c(0, 5000), ylim = c(-2500, 2500))

# From the residuals plot, we can see that there is much more dispersion in
# the positive residuals than there is in the negative residuals, indicating
# that our model makes (on average) worse overpredictions than it does
# underpredictions -- but there are a roughly equal number of both. Since
# the residuals don't have a "white noise" pattern, there is some signal that
# we've failed to extract.

# No noticable autocorrelation in the residuals
linfit2_preds$.resid |> pacf()

# Model predictions and uncertainty ---------------------------------------

set.seed(324123)
# Make some bootstraps
B <- 100
dat_bs <- bootstraps(dat_train, times = B)

# Make a container for the fitting results
boot_res <- matrix(nrow = B, ncol = nrow(dat_train))

for (i in 1:B) {
	# Get the current bootstrap data set
	dat_sample <- rsample::analysis(dat_bs$splits[[i]])
	
	# Fit the model to the current set
	boot_fit <- lin_mod |> fit(Y ~ ., dat_sample)
	
	# And get the predictions on the WHOLE TRAINING DATA
	boot_preds <- predict(boot_fit, dat_train)$.pred
	
	# Store in the results container
	boot_res[i, ] <- boot_preds
}

# Look at the container to make sure it worked
# str(boot_res, max.level = 1)

# Get the quantiles
boot_quants <-
	boot_res |>
	apply(2, quantile,  c(0.055, 0.5, 0.945)) |> 
	t() |>
	`colnames<-`(c("lwr", "med", "upr"))

# Join back to the actual data
linfit2_preds_boot <-
	linfit2_preds |>
	bind_cols(boot_quants)

# Make the plot of medians vs. point estimates to illustrate what I said in the
# notes about using the point estimate instead of the median
with(linfit2_preds_boot, {plot(med ~ .pred); abline(0, 1)})
# They aren't visually too far off but they aren't the same.

# Final evaluation on test data -------------------------------------------

test_preds <- augment(linfit2, dat_test)

tt_rmse <- dplyr::bind_rows(
	"train" = rmse(linfit2_preds, truth = Y, estimate = .pred),
	"test" = rmse(test_preds, truth = Y, estimate = .pred),
	.id = "set"
) |>
	dplyr::mutate(
		lab = paste0("RMSE: ", sprintf("%.2f", .estimate))
	)

linfit2_train_test <-
	dplyr::bind_rows(
		"train" = linfit2_preds,
		"test" = test_preds,
		.id = "set"
	) |>
	dplyr::mutate(set = factor(set, levels = c("train", "test")))

linfit2_train_test |>
	ggplot() +
	aes(x = Y, y = .pred, color = set, shape = set) +
	geom_abline(
		slope = 1, intercept = 0,
		linetype = "dashed", color = "gray", linewidth = 1.25
	) +
	geom_point(size = 1.5, stroke = 1.5) +
	labs(
		x = "Observed",
		y = "Predicted",
		color = NULL,
		shape = NULL
	) +
	scale_color_manual(values = c("skyblue", "orange")) +
	scale_shape_manual(values = c(21, 24)) +
	coord_cartesian(xlim = c(0, 5000), ylim = c(0, 5000)) +
	guides(
		x = guide_axis(cap = "both"),
		y = guide_axis(cap = "both")
	) +
	theme(
		axis.line = element_line(),
		axis.ticks = element_line(),
		legend.position = "inside",
		legend.position.inside = c(0.15, 0.8),
		legend.background = element_rect()
	)

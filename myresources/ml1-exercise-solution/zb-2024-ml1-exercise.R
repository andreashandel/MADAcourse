###
# ML Models 1 assessment
# 2024-03-20
# Zane Billings
# Zane's solution to the ML 1 exercise for MADA 2024 before looking at
# Andreas' code.
###


# Preliminaries ----------------------------------------------------------------

library(tidyverse)
library(tidymodels)
library(here)
library(patchwork)

# Require packages that parsnip needs but won't error on until runtime
box::use(
	glmnet,
	ranger
)

rngseed <- 1234


# More processing --------------------------------------------------------------

dat <- readr::read_rds(("mavoglurant.rds"))
dat_clean <-
	dat |>
	dplyr::mutate(
		SEX = factor(SEX, levels = c(1, 2), labels = c("M", "F")),
		RACE = forcats::fct_recode(
			RACE,
			"W" = "1", "B" = "2", "O" = "7", "O" = "88"
		)
	)

# Pairwise correlations --------------------------------------------------------

# Make a plot of pearson correlations
dat_clean |>
	# Drop non-numeric variables
	dplyr::select(dplyr::where(is.numeric)) |>
	# Compute the correlation matrix
	cor(method = "pearson") |>
	# Make the plot
	ggcorrplot::ggcorrplot(
		type = "upper",
		lab = TRUE
	)

# Make a plot of spearman correlations
dat_clean |>
	# Drop non-numeric variables
	dplyr::select(dplyr::where(is.numeric)) |>
	# Compute the correlation matrix
	cor(method = "spearman") |>
	# Make the plot
	ggcorrplot::ggcorrplot(
		type = "upper",
		lab = TRUE
	)

# Feature engineering -----------------------------------------------------

# Calculate the BMI per patient
# For each patient, we know from the paper that the weight is in kg, and the
# heights are way too small to be inches or feet so we guess they are in meters.
dat_clean$BMI <- dat$WT / (dat$HT^2)

# Values match table 1 in the paper. So looks good.

# Model Building ----------------------------------------------------------

# Set up our model specs. We'll fit a null model, linear model, LASSO, and
# random forest.
model_specs <- list()

# First, the spec for the null model
model_specs[["Null Model"]] <-
	parsnip::null_model() |>
	parsnip::set_mode("regression") |>
	parsnip::set_engine("parsnip")

# Spec for OLS linear regression
model_specs[["OLS"]] <-
	parsnip::linear_reg() |>
	parsnip::set_mode("regression") |>
	parsnip::set_engine("lm")

# Spec for LASSO regression
model_specs[["LASSO"]] <-
	parsnip::linear_reg(mixture = 1) |>
	parsnip::set_mode("regression") |>
	parsnip::set_engine("glmnet")

# Spec for random forest
model_specs[["RF"]] <-
	parsnip::rand_forest() |>
	parsnip::set_mode("regression") |>
	parsnip::set_engine("ranger", seed = rngseed, num.threads = 2)

# Create a recipe including all predictors, the only preprocessing step we need
# to do is dummy variable creation.
model_rec <-
	recipes::recipe(formula = Y ~ ., data = dat_clean) |>
	recipes::step_dummy(recipes::all_nominal_predictors())

# Test the recipe
prepped_dat <-
	model_rec |>
	recipes::prep() |>
	recipes::juice()

# Now create workflowset
model_wfs <-
	# Was doing it manually but rememebred WFS exist
	# model_specs |>
	# purrr::map(
	# 	\(spec) workflows::workflow() |>
	# 		workflows::add_recipe(model_rec) |>
	# 		workflows::add_model(spec)
	# )
	workflowsets::workflow_set(
		preproc = list(model_rec),
		models = model_specs
	) |>
	# remove recipe_ from id name since there's only one
	dplyr::mutate(wflow_id = gsub("recipe_", "", wflow_id, fixed = TRUE))

## First fit -------------------------------------------------------------------
# Fit the models to the entire training set
model_wfs <-
	model_wfs |>
	workflowsets::update_workflow_model(
		"LASSO",
		parsnip::set_args(model_specs$LASSO, penalty = 0.1)
	)

first_fits <-
	model_wfs$wflow_id |>
	purrr::map(
		\(wf_id) model_wfs |>
			workflowsets::extract_workflow(wf_id) |>
			parsnip::fit(data = dat_clean)
	)

first_fit_preds <-
	purrr::map(
		first_fits,
		\(fit) parsnip::augment(fit, new_data = dat_clean)
	) |>
	purrr::list_rbind(names_to = "model") |>
	dplyr::mutate(
		# Recompute the .resid column for all models
		.resid = Y - .pred,
		# Make the model variable a factor
		model = factor(model) |> forcats::fct_inorder()
	)

# Get the RMSEs
first_fit_rmses <-
	first_fit_preds |>
	tidyr::nest(dat = -model) |>
	dplyr::mutate(
		met = purrr::map(dat, \(d) yardstick::rmse(d, truth = Y, estimate = .pred))
	) |>
	tidyr::unnest(met) 

knitr::kable(first_fit_rmses |> dplyr::select(-dat))

# Make the observed vs. predicted plots
first_fit_plots <-
	first_fit_rmses |>
	dplyr::mutate(
		plt = purrr::map(
			dat,
			\(d) ggplot2::ggplot(d) +
				ggplot2::aes(x = .pred, y = Y) +
				ggplot2::geom_abline(
					slope = 1, intercept = 0,
					color = "gray", linetype = "dashed", linewidth = 2
				) +
				ggplot2::geom_point(
					shape = 21,
					size = 2,
					stroke = 1.5
				) +
				ggplot2::coord_cartesian(
					xlim = c(800, 5700),
					ylim = c(800, 5700)
				)
		),
		# Add titles and RMSEs to the plots
		plt = purrr::pmap(
			list(plt, model, .estimate), 
			\(p, m, r) p +
				ggplot2::ggtitle(m) +
				ggplot2::annotate(
					geom = "label",
					x = 4750,
					y = 2000,
					label = paste0("RMSE: ", sprintf("%.2f", r)),
					size = 4
				)
		)
	)

purrr::reduce(first_fit_plots$plt, `+`)

# Tuning without CV -------------------------------------------------------

# Update the models for the parameters we want to tune
tuning_wfs <-
	model_wfs |>
	workflowsets::update_workflow_model(
		"LASSO",
		parsnip::set_args(model_specs$LASSO, penalty = tune::tune())
	) |>
	workflowsets::update_workflow_model(
		"RF",
		parsnip::set_args(
			model_specs$RF,
			trees = 500,
			min_n = tune::tune(),
			mtry = tune::tune()
		)
	)

# Create tuning grids
lasso_grid <- tidyr::expand_grid(penalty = 10 ^ seq(-5, 2, 0.5))
rf_grid <- dials::grid_regular(
	mtry(range(1, 7)),
	min_n(range(1, 21)),
	levels = 7
)
tuning_grids <- list(1, 1, lasso_grid, rf_grid)

# Add the tuning grids to the workflowset
tuning_wfs <-
	tuning_wfs |>
	workflowsets::option_add(grid = lasso_grid, id = "LASSO") |>
	workflowsets::option_add(grid = rf_grid, id = "RF")

# Create apparent resamples
apparent_rsmp <- rsample::apparent(dat_clean)

# Tune the models over the apparent resamples
apparent_res <-
	workflowsets::workflow_map(
		tuning_wfs,
		fn = "tune_grid",
		verbose = TRUE,
		seed = rngseed,
		resamples = apparent_rsmp,
		metrics = yardstick::metric_set(yardstick::rmse),
		control = tune::control_grid(verbose = TRUE)
	)

apparent_res |>
	dplyr::filter(wflow_id %in% c("LASSO", "RF")) |>
	dplyr::mutate(
		plt = purrr::map(result, \(x) autoplot(x)),
		plt = purrr::map2(
			plt, wflow_id,
			\(x, m) x +
				ggplot2::ggtitle(m) +
				ggplot2::scale_color_viridis_d()
		)
	) |>
	dplyr::pull(plt) |>
	purrr::reduce(`+`)

# Tuning with CV ---------------------------------------------------------
set.seed(rngseed)
cv_rsmp <- rsample::vfold_cv(dat_clean, v = 5, repeats = 5, strata = Y)
cv_res <-
	workflowsets::workflow_map(
		tuning_wfs,
		fn = "tune_grid",
		verbose = TRUE,
		seed = rngseed,
		resamples = cv_rsmp,
		metrics = yardstick::metric_set(yardstick::rmse),
		control = tune::control_grid(verbose = TRUE, save_workflow = TRUE)
	)

cv_res |>
	dplyr::filter(wflow_id %in% c("LASSO", "RF")) |>
	dplyr::mutate(
		plt = purrr::map(result, \(x) autoplot(x)),
		plt = purrr::map2(
			plt, wflow_id,
			\(x, m) x +
				ggplot2::ggtitle(m) +
				ggplot2::scale_color_viridis_d()
		)
	) |>
	dplyr::pull(plt) |>
	purrr::reduce(`+`)

# Get the overall best fit (unfortunately they won't implement this to
# work for each type of model :rolling-eyes:)
best_overall_wf <- cv_res |> fit_best()

# Finalize wfs -- this is the part where I remembered how annoying workflowsets
# actually are because the team refuses to implement new methods for them and
# you gotta do everything yourself, and it usually involves error handling
best_lasso_parms <-
	cv_res |>
	extract_workflow_set_result("LASSO") |>
	select_best()

final_lasso_wf <-
	cv_res |>
	extract_workflow("LASSO") |>
	finalize_workflow(best_lasso_parms)

final_lasso_fit <-
	fit(final_lasso_wf, data = dat_clean)

glmnet_fit <- parsnip::extract_fit_engine(final_lasso_fit)
plot(glmnet_fit, "lambda")

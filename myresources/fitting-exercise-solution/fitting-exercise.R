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

## ---- fit-data-linear --------
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
log_mod <- logistic_reg() %>% set_engine("glm")
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
  filter(.metric %in% c("accuracy", "roc_auc"))
m2_auc <-  logfit2 %>%
  predict(dat, type = "prob") %>%
  bind_cols(dat) %>%
  roc_auc(truth = SEX, .pred_1)
# Print the results
print(m1_acc)
print(m1_auc)
print(m2_acc)
print(m2_auc)

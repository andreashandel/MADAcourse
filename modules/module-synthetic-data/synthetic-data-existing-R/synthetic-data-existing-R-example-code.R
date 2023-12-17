# R script for simulated/artificial data examples


## ---- packages --------
library('dplyr')


## ---- setup --------
# setting a random number seed for reproducibility
set.seed(123)


## ---- loaddata --------
#assuming your R script is in the same folder
rawdat <- readRDS('SympAct_Any_Pos.Rda')


## ---- checkdata --------
dim(rawdat)
dplyr::glimpse(rawdat)  


## ---- scramble-data --------

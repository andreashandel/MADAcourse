# R script for simulated/artificial data examples


## ---- packages --------
library('dplyr')
library('ggplot2')
library('here')

## ---- setup --------
# setting a random number seed for reproducibility
set.seed(123)


## ---- loaddata --------
#assuming your R script is in the same folder
#rawdat <- readRDS('SympAct_Any_Pos.Rda')
# this is for my setup
rawdat <- readRDS(here::here('data','SympAct_Any_Pos.Rda'))

## ---- checkdata --------
dim(rawdat)
dplyr::glimpse(rawdat)  


## ---- reduce-data --------
dat <- rawdat |> dplyr::select("ActivityLevel","Sneeze","Nausea","Vomit")
head(dat,10)

## ---- scramble-data --------
# define a new data frame that will contain scrambled values
dat_sc <- dat
Nobs = nrow(dat) #number of observations
# loop over each variable, reshuffle entries
for (n in 1:ncol(dat))
{
  dat_sc[,n] <- sample(dat[,n], size = Nobs, replace = FALSE)
}

head(dat_sc,10)


## ---- compare-data1 --------
summary(dat)
summary(dat_sc)

## ---- compare-data2 --------
# cross-tabulation of 2 symptoms
tb1=table(dat$Nausea,dat$Vomit)
prop.table(tb1)*100 #as percentage
tb2=table(dat_sc$Nausea,dat_sc$Vomit)
prop.table(tb2)*100
# looking at possible correlation between activity level and Vomit
p1 <- dat |> ggplot(aes(x=Vomit,y=ActivityLevel)) + geom_boxplot()
plot(p1)
p2 <- dat_sc |> ggplot(aes(x=Vomit,y=ActivityLevel)) + geom_boxplot()
plot(p2)

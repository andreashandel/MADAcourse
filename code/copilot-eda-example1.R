# write code that loads data from a file
# the data is stored in the dat object
# the code should produce several plots of the variables stored in the dat object

library(here)
library(tidyverse)

# load data
dat <- read.csv(here::here("data","syn_dat.csv"))

# make a summary table of the data stored in the dat object
summary(dat)

# make a histogram of the Age variable
ggplot(dat, aes(x = Age)) + geom_histogram()

# make a scatter plot of BloodPressure versus Age, stratified by Gender


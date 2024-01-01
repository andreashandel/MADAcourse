# R script for to generate synthetic data based on existing data


## ---- packages --------
# make sure the packages are installed
# Load required packages
library(here)
library(dplyr)
library(ggplot2)
library(skimr)
library(gtsummary)

## ---- setup --------
# Set a seed for reproducibility
set.seed(123)
# Define the number of observations (patients) to generate
n_patients <- 100

## ---- summarize-data --------
dat <- readRDS(here::here("content/module-synthetic-data/synthetic-data-new-existing-r/syn_dat.rds"))
skimr::skim(dat)
gtsummary::tbl_summary(dat, statistic = list(
  all_continuous() ~ "{mean}/{median}/{min}/{max}/{sd}",
  all_categorical() ~ "{n} / {N} ({p}%)"
),)


## ---- explore-variables --------
# using base R to explore variable distributions
table(dat$Gender)
table(dat$TreatmentGroup)
table(dat$AdverseEvent)
hist(dat$Age)
hist(dat$BloodPressure)
hist(dat$Cholesterol)

## ---- explore-correlations --------
# explore some correlations between variables
table(dat$AdverseEvent, dat$TreatmentGroup)
plot(dat$Age, dat$BloodPressure)
ggplot(dat) + geom_histogram(aes(x = Cholesterol, fill = TreatmentGroup)) 
  

## ---- make-data --------
# Create an empty data frame with placeholders for variables
syn_dat <- data.frame(
  PatientID = numeric(n_patients),
  Age = numeric(n_patients),
  Gender = character(n_patients),
  TreatmentGroup = character(n_patients),
  EnrollmentDate = lubridate::as_date(character(n_patients)),
  BloodPressure = numeric(n_patients),
  Cholesterol = numeric(n_patients),
  AdverseEvent = integer(n_patients)
)

# Variable 1: Patient ID
# can be exactly the same as the original
syn_dat$PatientID <- 1:n_patients

# Variable 2: Age (numeric variable)
# creating normally distributed values with the mean and SD taken 
# from the real data
syn_dat$Age <- round(rnorm(n_patients, mean = mean(dat$Age), sd = sd(dat$Age)), 1)

# Variable 3: Gender (categorical variable)
# create with probabilities based on real data distribution
syn_dat$Gender <- sample(c("Male", "Female"), 
                         n_patients, replace = TRUE, 
                         prob = as.numeric(table(dat$Gender)/100))

# Variable 4: Treatment Group (categorical variable)
# create with probabilities based on real data distribution
syn_dat$TreatmentGroup <- sample(c("A", "B", "Placebo"), 
                                 n_patients, 
                                 replace = TRUE,
                                 prob = as.numeric(table(dat$TreatmentGroup)/100))

# Variable 5: Date of Enrollment (date variable)
# use same start and end dates as real data
syn_dat$EnrollmentDate <- lubridate::as_date(sample(seq(from = min(dat$EnrollmentDate), 
                                                        to = max(dat$EnrollmentDate), 
                                                        by = "days"), n_patients, replace = TRUE))

# Variable 6: Blood Pressure (numeric variable)
# use uniform distribution as indicated by histogram of real data
# use same min and max values as real data
syn_dat$BloodPressure <- round(runif(n_patients, 
                                     min = min(dat$BloodPressure), 
                                     max = max(dat$BloodPressure)), 1)

# Variable 7: Cholesterol Level (numeric variable)
# here, we re-create it based on the overall data distribution pattern
# since the data didn't quite look like a normal distribution, 
# here we'll just use it as its own distribution and sample right from the data
# note that this breaks the association with treatment group 
# for real data, we wouldn't know if there is any, but if we suspect, we could
# generate data with and without such associations and explore its impact on model performance
syn_dat$Cholesterol <- sample(dat$Cholesterol, 
                                    size = n_patients, 
                                    replace = TRUE)


# Variable 8: Adverse Event (binary variable, 0 = No, 1 = Yes)
# we implement this variable by taking into account different probabilities stratified by treatment
probA = as.numeric(table(dat$AdverseEvent,dat$TreatmentGroup)[,1])/sum(table(dat$AdverseEvent,dat$TreatmentGroup)[,1])
probB = as.numeric(table(dat$AdverseEvent,dat$TreatmentGroup)[,2])/sum(table(dat$AdverseEvent,dat$TreatmentGroup)[,2]) 
probP = as.numeric(table(dat$AdverseEvent,dat$TreatmentGroup)[,3])/sum(table(dat$AdverseEvent,dat$TreatmentGroup)[,3])

# this re-creates the correlation we find between those two variables
syn_dat$AdverseEvent[syn_dat$TreatmentGroup == "A"] <- sample(0:1, sum(syn_dat$TreatmentGroup == "A"), replace = TRUE, prob = probA)
syn_dat$AdverseEvent[syn_dat$TreatmentGroup == "B"] <- sample(0:1, sum(syn_dat$TreatmentGroup == "B"), replace = TRUE, prob = probB)
syn_dat$AdverseEvent[syn_dat$TreatmentGroup == "Placebo"] <- sample(0:1, sum(syn_dat$TreatmentGroup == "Placebo"), replace = TRUE, prob = probP)


## ---- check-data --------
# Print the first few rows of the generated data
head(syn_dat)
# quick summaries
summary(syn_dat)
dplyr::glimpse(syn_dat)  

# Frequency table for adverse events stratified by treatment
table(syn_dat$AdverseEvent,syn_dat$TreatmentGroup)


# ggplot2 boxplot for cholesterol by treatment group
ggplot(syn_dat, aes(x = TreatmentGroup, y = Cholesterol)) +
  geom_boxplot() +
  labs(x = "Treatment Group", y = "Cholesterol Level") +
  theme_bw()


# Save the simulated data to a CSV file
write.csv(syn_dat, "syn_dat_new.csv", row.names = FALSE)



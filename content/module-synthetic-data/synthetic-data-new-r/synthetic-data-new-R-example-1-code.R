# R script for simulated/artificial data examples


## ---- packages --------
# make sure the packages are installed
# Load required packages
library(dplyr)
library(purrr)
library(lubridate)
library(ggplot2)


## ---- setup --------
# Set a seed for reproducibility
set.seed(123)
# Define the number of observations (patients) to generate
n_patients <- 100


## ---- makedata --------

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
syn_dat$PatientID <- 1:n_patients

# Variable 2: Age (numeric variable)
syn_dat$Age <- round(rnorm(n_patients, mean = 45, sd = 10), 1)

# Variable 3: Gender (categorical variable)
syn_dat$Gender <- purrr::map_chr(sample(c("Male", "Female"), n_patients, replace = TRUE), as.character)

# Variable 4: Treatment Group (categorical variable)
syn_dat$TreatmentGroup <- purrr::map_chr(sample(c("A", "B", "Placebo"), n_patients, replace = TRUE), as.character)

# Variable 5: Date of Enrollment (date variable)
syn_dat$EnrollmentDate <- lubridate::as_date(sample(seq(from = lubridate::as_date("2022-01-01"), to = lubridate::as_date("2022-12-31"), by = "days"), n_patients, replace = TRUE))

# Variable 6: Blood Pressure (numeric variable)
syn_dat$BloodPressure <- round(runif(n_patients, min = 90, max = 160), 1)

# Variable 7: Cholesterol Level (numeric variable)
# Option 1: Cholesterol is independent of treatment
#syn_dat$Cholesterol <- round(rnorm(n_patients, mean = 200, sd = 30), 1)

# Option 2: Cholesterol is dependent on treatment
syn_dat$Cholesterol[syn_dat$TreatmentGroup == "A"] <- round(rnorm(sum(syn_dat$TreatmentGroup == "A"), mean = 160, sd = 10), 1)
syn_dat$Cholesterol[syn_dat$TreatmentGroup == "B"] <- round(rnorm(sum(syn_dat$TreatmentGroup == "B"), mean = 180, sd = 10), 1)
syn_dat$Cholesterol[syn_dat$TreatmentGroup == "Placebo"] <- round(rnorm(sum(syn_dat$TreatmentGroup == "Placebo"), mean = 200, sd = 10), 1)

# Variable 8: Adverse Event (binary variable, 0 = No, 1 = Yes)
# Option 1: Adverse events are independent of treatment
#syn_dat$AdverseEvent <- purrr::map_int(sample(0:1, n_patients, replace = TRUE, prob = c(0.8, 0.2)), as.integer)

# Option 2: Adverse events are influenced by treatment status
syn_dat$AdverseEvent[syn_dat$TreatmentGroup == "A"] <- purrr::map_int(sample(0:1, sum(syn_dat$TreatmentGroup == "A"), replace = TRUE, prob = c(0.5, 0.5)), as.integer)
syn_dat$AdverseEvent[syn_dat$TreatmentGroup == "B"] <- purrr::map_int(sample(0:1, sum(syn_dat$TreatmentGroup == "B"), replace = TRUE, prob = c(0.7, 0.3)), as.integer)
syn_dat$AdverseEvent[syn_dat$TreatmentGroup == "Placebo"] <- purrr::map_int(sample(0:1, sum(syn_dat$TreatmentGroup == "Placebo"), replace = TRUE, prob = c(0.9, 0.1)), as.integer)


# Print the first few rows of the generated data
head(syn_dat)

# Save the simulated data to a CSV and Rds file
write.csv(syn_dat, "syn_dat.csv", row.names = FALSE)
# if we wanted an RDS version
#saveRDS(syn_dat, here("data","syn_dat.Rds"))


## ---- checkdata --------
summary(syn_dat)
dplyr::glimpse(syn_dat)  

# Frequency table for adverse events stratified by treatment
table(syn_dat$AdverseEvent,syn_dat$TreatmentGroup)


# ggplot2 boxplot for cholesterol by treatment group
ggplot(syn_dat, aes(x = TreatmentGroup, y = Cholesterol)) +
  geom_boxplot() +
  labs(x = "Treatment Group", y = "Cholesterol Level") +
  theme_bw()




##############################################################
# R script for simulated/synthetic data generation
# Example that shows longitudinal data
##############################################################

##############################################################
# ChatGPT prompt to write first draft of code
# Note that this prompt was far from what I wanted, so 
# there were several iterations where I asked it to update the code
##############################################################
# write R code that generates a longitudinal and hierarchical dataset.
# The dataset should show drug concentrations, levels of cholesterol 
# and adverse events for patients over time.
# Patients should be in two treatment groups, receiving different doses of the drug on day 0.
# Each patient should have 10 samples taken over the course of 10 days.
# Add a lot of comments to your code to explain what you are doing.
# Assume that adverse events depend on drug concentration.


## ---- packages-ex2 --------
# make sure the packages are installed
# Load required packages
library(dplyr)
library(ggplot2)


## ---- setup-ex2 --------
# Set seed for reproducibility
set.seed(123)
# Number of patients in each treatment group
num_patients <- 20
# Number of days and samples per patient
num_days <- 7
num_samples_per_day <- 1


## ---- makedata-ex2 --------
# Treatment group levels
treatment_groups <- c("Low Dose", "High Dose")

# Generate patient IDs
patient_ids <- rep(1:num_patients, each = num_days)

# Generate treatment group assignments for each patient
treatment_assignments <- rep(sample(treatment_groups, num_patients, replace = TRUE), 
                             each = num_days)

# Generate day IDs for each patient
day_ids <- rep(1:num_days, times = num_patients)

# Function to generate drug concentrations with variability
generate_drug_concentrations <- function(day, dose_group, patient_id) {
  baseline_concentration <- ifelse(dose_group == "Low Dose", 8, 15)
  patient_variation <- rnorm(1, mean = 0, sd = 1)
  time_variation <- exp(-0.1*day)
  baseline_concentration * time_variation + patient_variation 
}


# Generate drug concentrations for each sample
drug_concentrations <- mapply(generate_drug_concentrations, 
                              day = rep(day_ids, each = num_samples_per_day), 
                              dose_group = treatment_assignments,
                              patient_id = rep(1:num_patients, each = num_days))


# Flatten the matrix to a vector
drug_concentrations <- as.vector(drug_concentrations)

# Generate cholesterol levels for each sample 
# (assuming a positive correlation with drug concentration)
cholesterol_levels <- drug_concentrations + 
  rnorm(num_patients * num_days * num_samples_per_day, mean = 0, sd = 5)

# Generate adverse events based on drug concentration 
# (assuming a higher chance of adverse events with higher concentration)
# Sigmoid function to map concentrations to probabilities
adverse_events_prob <- plogis(drug_concentrations / 10) 
adverse_events <- rbinom(num_patients * num_days * num_samples_per_day, 
                         size = 1, prob = adverse_events_prob)

# Create a data frame
syn_dat2 <- data.frame(
  PatientID = rep(patient_ids, each = num_samples_per_day),
  TreatmentGroup = rep(treatment_assignments, each = num_samples_per_day),
  Day = rep(day_ids, each = num_samples_per_day),
  DrugConcentration = drug_concentrations,
  CholesterolLevel = cholesterol_levels,
  AdverseEvent = adverse_events
)

## ---- checkdata-ex2 --------
# Print the first few rows of the generated dataset
print(head(syn_dat2))
summary(syn_dat2)
dplyr::glimpse(syn_dat2)  


## ---- plotdata-ex2 --------
# Plot drug concentrations over time for each individual using ggplot2
p1 <- ggplot(syn_dat2, aes(x = Day, y = DrugConcentration, 
                      group = as.factor(PatientID), color = TreatmentGroup)) +
  geom_line() +
  labs(title = "Drug Concentrations Over Time",
       x = "Day",
       y = "Drug Concentration",
       color = "TreatmentGroup") +
  theme_minimal()
plot(p1)

p2 <- ggplot(syn_dat2, aes(x = as.factor(AdverseEvent), y = DrugConcentration, 
                           fill = TreatmentGroup)) +
  geom_boxplot(width = 0.7, position = position_dodge(width = 0.8), color = "black") +
  geom_point(aes(color = TreatmentGroup), position = position_dodge(width = 0.8), 
             size = 3, shape = 16) +  # Overlay raw data points
  labs(
    x = "Adverse Events",
    y = "Drug Concentration",
    title = "Boxplot of Drug Concentration by Adverse Events and Treatment"
  ) +
  scale_color_manual(values = c("A" = "blue", "B" = "red")) +  # Customize color for each treatment
  theme_minimal() +
  theme(legend.position = "top")
plot(p2)

## ---- savedata-ex2 --------
# Save the simulated data to a CSV or Rds file
write.csv(syn_dat2, "syn_dat2.csv", row.names = FALSE)
saveRDS(syn_dat2, "syn_dat2.Rds")

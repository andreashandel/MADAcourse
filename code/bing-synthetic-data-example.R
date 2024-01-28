# Load necessary libraries
library(dplyr) # for data manipulation
library(purrr) # for functional programming
library(ggplot2) # for data visualization

# Set the number of patients
N <- 100

# Create a data frame for patients
set.seed(123) # for reproducibility
patients <- data.frame(
  ID = 1:N, # patient ID
  Age = sample(18:50, N, replace = TRUE), # age
  Treatment = sample(c("Placebo", "Low Dose", "High Dose"), N, replace = TRUE) # treatment group
)

# Function to simulate drug concentration and cholesterol level for each patient
simulate_data <- function(ID, Age, Treatment) {
  data.frame(
    ID = ID,
    Age = Age,
    Treatment = Treatment,
    Time = 0:13, # two weeks of data
    Drug_Concentration = 100 * 0.8^(0:13) * ifelse(Treatment == "Low Dose", 1, ifelse(Treatment == "High Dose", 2, 0)), # drug concentration
    Cholesterol = 200 - 0.5 * 100 * 0.8^(0:13) * ifelse(Treatment == "Low Dose", 1, ifelse(Treatment == "High Dose", 2, 0)) # cholesterol level
  )
}

# Apply the function to each patient
data <- mapply(simulate_data, patients$ID, patients$Age, patients$Treatment, SIMPLIFY = FALSE) %>% 
  bind_rows()

# Print the first few rows of the data
head(data)

# Plot the raw data for drug concentration as a function of time for all patients, stratified by treatment status
ggplot(data, aes(x = Time, y = Drug_Concentration, color = Treatment)) +
  geom_line() +
  labs(title = "Drug Concentration over Time", x = "Time (days)", y = "Drug Concentration")

# Plot the mean drug concentration for each group
data %>%
  group_by(Treatment, Time) %>%
  summarise(Mean_Drug_Concentration = mean(Drug_Concentration)) %>%
  ggplot(aes(x = Time, y = Mean_Drug_Concentration, color = Treatment)) +
  geom_line() +
  labs(title = "Mean Drug Concentration over Time", x = "Time (days)", y = "Mean Drug Concentration")

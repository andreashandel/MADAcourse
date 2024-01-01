# Prompt

# Write R code to perform an exploratory data analysis of the attached CSV file


# Load required libraries
library(tidyverse)
library(skimr)

# Read in the CSV data
# ORIGINAL
#df <- read_csv("syn_dat.csv")
# MANUAL UPDATE
df <- read.csv(here::here("data","syn_dat.csv"))

# Summary statistics
skim(df)

# Visualizations

# Histogram of age
ggplot(df, aes(x = Age)) +
  geom_histogram()

# Histogram of blood pressure 
ggplot(df, aes(x = BloodPressure)) +
  geom_histogram()

# Bar plot of adverse events by treatment group
ggplot(df, aes(x = TreatmentGroup, fill = factor(AdverseEvent))) +
  geom_bar(position="dodge")

# Scatterplot of cholesterol vs blood pressure
ggplot(df, aes(x = Cholesterol, y = BloodPressure)) + 
  geom_point()

# Calculate correlations
cor(df[c("Age", "BloodPressure", "Cholesterol")])

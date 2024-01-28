#Prompt

#Perform an exploratory data analysis using R code of the following dataset:
 
# PASTE content of syn_dat.csv here 


# Load necessary libraries
library(tidyverse)
library(lubridate)

# Load the data
# ORIGINAL: It told me to replace this wite the file to my actual dataset
# data <- read.csv("your_data.csv")
# MANUAL REPLACEMENT:
data <- read.csv(here::here("data","syn_dat.csv"))

# Convert EnrollmentDate to Date type
data$EnrollmentDate <- mdy(data$EnrollmentDate)

# Summary of the data
summary(data)

# Structure of the data
str(data)

# Check for missing values
sum(is.na(data))

# Descriptive statistics
data %>%
  group_by(TreatmentGroup) %>%
  summarise(
    count = n(),
    avg_age = mean(Age, na.rm = TRUE),
    avg_bp = mean(BloodPressure, na.rm = TRUE),
    avg_chol = mean(Cholesterol, na.rm = TRUE)
  )

# Boxplot for Age by TreatmentGroup
ggplot(data, aes(x=TreatmentGroup, y=Age)) +
  geom_boxplot() +
  labs(title="Boxplot of Age by Treatment Group")

# Histogram for BloodPressure
ggplot(data, aes(x=BloodPressure)) +
  geom_histogram(binwidth=5, fill="#69b3a2", color="#e9ecef", alpha=0.9) +
  labs(x="Blood Pressure", y="Count", title="Histogram of Blood Pressure")

# Scatterplot for Age and Cholesterol
ggplot(data, aes(x=Age, y=Cholesterol)) +
  geom_point() +
  labs(x="Age", y="Cholesterol", title="Scatterplot of Age and Cholesterol")

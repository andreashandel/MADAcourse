# Install and load necessary packages
if (!requireNamespace("dplyr", quietly = TRUE)) install.packages("dplyr")
if (!requireNamespace("ggplot2", quietly = TRUE)) install.packages("ggplot2")
if (!requireNamespace("patchwork", quietly = TRUE)) install.packages("patchwork")

library(dplyr)
library(ggplot2)
library(patchwork)

# Set seed for reproducibility
set.seed(123)

# Generate a dataset of 100 individuals
n_individuals <- 100

# Generate random ages between 18 and 49
ages <- sample(18:49, n_individuals, replace = TRUE)

# Generate random BMI values between 15 and 40
bmis <- sample(15:40, n_individuals, replace = TRUE)

# Assign smoking status (yes or no)
smoking <- sample(c("Yes", "No"), n_individuals, replace = TRUE, prob = c(0.2, 0.8))

# Create a data frame
data <- data.frame(Age = ages, BMI = ifelse(smoking == "Yes", bmis - 2, bmis), Smoking = smoking)

# Plot 1: Violin plot with BMI on the y-axis and smoking status on the x-axis
plot1 <- ggplot(data, aes(x = Smoking, y = BMI)) +
  geom_violin(fill = "lightblue", draw_quantiles = c(0.25, 0.5, 0.75)) +
  geom_jitter(aes(color = Smoking), width = 0.2, alpha = 0.7) +
  labs(title = "BMI by Smoking Status",
       x = "Smoking Status",
       y = "BMI") +
  theme_minimal()

# Plot 2: Scatterplot with age on the y-axis and BMI on the x-axis
plot2 <- ggplot(data, aes(x = BMI, y = Age, color = Smoking)) +
  geom_point(alpha = 0.7) +
  labs(title = "Scatterplot of Age and BMI",
       x = "BMI",
       y = "Age") +
  theme_minimal()

# Combine plots using patchwork
combined_plots <- plot1 + plot2

# Display the combined plots
combined_plots

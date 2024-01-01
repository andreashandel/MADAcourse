# Starting with the previous R code (bing-iterate-example-update2.R) 
# and providing the following prompt:

# The code below produces this error message:
#   
# Error in eval(ei, envir) : object 'sex' not found
# 
# Please fix it.





# Load necessary libraries
library(ggplot2)
library(dplyr)

# Set seed for reproducibility
set.seed(123)

# Generate sex variable with males and females randomly distributed
sex = sample(rep(c("male", "female"), each = 50))

# Generate a dataset of 100 individuals
data <- data.frame(
  # Use the previously generated sex variable
  sex = sex,
  
  # Generate ages from 18 to 49
  age = sample(18:49, 100, replace = TRUE),
  
  # Generate weight values from 100 to 500 pounds
  # Make sure that males are on average heavier than females
  weight = ifelse(sex == "male", runif(50, min = 300, max = 500), runif(50, min = 100, max = 300))
)

# Compute values for BMI as a function of weight with some random variation added
# Assume a height of 1.75 meters for simplicity
# BMI = weight(kg) / height(m)^2
# Convert weight from pounds to kg (1 pound = 0.453592 kg)
data$bmi <- (data$weight * 0.453592) / (1.75^2) + rnorm(100)

# View the first few rows of the dataset
head(data)

# Create a scatter plot
ggplot(data, aes(x = weight, y = bmi, color = sex)) +
  geom_point() +
  labs(x = "Weight", y = "BMI", color = "Sex") +
  theme_minimal() +
  ggtitle("Scatter plot of BMI against Weight stratified by Sex")


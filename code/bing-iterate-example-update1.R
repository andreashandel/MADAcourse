#Prompt:

#Write R code that generates a dataset of 100 individuals, half of them female,
#with ages from 18 to 49, weight from 100 to 500 pounds and BMI from 15 to 35.
#Assume that males are generally somewhat heavier than females. Also assume thet
#BMI and weight are positively correlated, based on the definition of BMI. Make
#a figure that shows weight on the x-axis, BMI on the y-axis, and stratification
#by sex. Add thorough documentation to the code.



# Load necessary libraries
library(ggplot2)
library(dplyr)

# Set seed for reproducibility
set.seed(123)

# Generate a dataset of 100 individuals
data <- data.frame(
  # Generate sex variable with half of them female
  sex = rep(c("male", "female"), each = 50),
  
  # Generate ages from 18 to 49
  age = sample(18:49, 100, replace = TRUE),
  
  # Generate weight values from 100 to 500 pounds
  # Assume that males are generally somewhat heavier than females
  weight = c(runif(50, min = 100, max = 400), runif(50, min = 200, max = 500)),
  
  # Generate BMI values from 15 to 35
  # Assume that BMI and weight are positively correlated
  bmi = c(runif(50, min = 15, max = 25), runif(50, min = 25, max = 35))
)

# View the first few rows of the dataset
head(data)

# Create a scatter plot
ggplot(data, aes(x = weight, y = bmi, color = sex)) +
  geom_point() +
  labs(x = "Weight", y = "BMI", color = "Sex") +
  theme_minimal() +
  ggtitle("Scatter plot of BMI against Weight stratified by Sex")

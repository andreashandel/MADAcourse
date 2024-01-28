#Prompt

#Write R code to perform an exploratory data analysis of a data frame called
#dat. The data frame contains the continuous variables age and BMI, and the
#categorical variables sex and favorite color. Write code that produces a
#summary table, univariate plots for each variable, and a bivariate plot of age
#vs BMI.


# Load necessary libraries
library(ggplot2)
library(dplyr)

# Summary table
summary(dat)

# Univariate plots
ggplot(dat, aes(x=age)) +
  geom_histogram(binwidth=5, fill="blue", color="black") +
  labs(title="Age Distribution", x="Age", y="Count")

ggplot(dat, aes(x=BMI)) +
  geom_histogram(binwidth=5, fill="blue", color="black") +
  labs(title="BMI Distribution", x="BMI", y="Count")

ggplot(dat, aes(x=sex)) +
  geom_bar(fill="blue", color="black") +
  labs(title="Sex Distribution", x="Sex", y="Count")

ggplot(dat, aes(x=favorite_color)) +
  geom_bar(fill="blue", color="black") +
  labs(title="Favorite Color Distribution", x="Favorite Color", y="Count")

# Bivariate plot of age vs BMI
ggplot(dat, aes(x=age, y=BMI)) +
  geom_point() +
  labs(title="Age vs BMI", x="Age", y="BMI")

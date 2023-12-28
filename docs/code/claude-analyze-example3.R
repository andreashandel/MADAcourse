# Load brms package
library(brms) 

# Read in the CSV data
# ORIGINAL
#data <- read_csv("syn_dat2.csv")
# MANUAL CHANGE
data <- read_csv(here::here('data',"syn_dat2.csv"))

# Set up formula
formula <- bf(
  brms::bf(
    CholesterolLevel ~ brms::brms(DrugConcentration, nl = TRUE),  
    PatientID,
    prior = brms::set_prior("normal(0,10)")
  )
)

# Fit model
model <- brms::brm(
  formula = formula,
  data = data, 
  chains = 4,
  cores = 4  
)

# Summarize model
brms::summary(model)
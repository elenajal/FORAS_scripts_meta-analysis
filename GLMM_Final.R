
##### Final version of Generalized linear mixed models. 

library(metafor)
library(lme4)
library(influence.ME)


file.choose()

Test <- read.csv2("C:\\Users\\Messi002\\Desktop\\Spreadsheet_R.csv")

Test$Sample_Size <- as.numeric(Test$Sample_Size)
Test$Resilient_trajectory <- as.numeric(Test$Resilient_trajectory)
Test$Recovery_trajectory <- as.numeric(Test$Recovery_trajectory)
Test$Chronic_ponto <- as.numeric(Test$Chronic_ponto)
Test$Worsening_trajectory <- as.numeric(Test$Worsening_trajectory)
Test$Partially_symptomatic_trajectory <- as.numeric(Test$Partially_symptomatic_trajectory)
Test$TP1_TPX <- as.numeric(Test$TP1_TPX)
Test$Trauma_TP1 <- as.numeric(Test$Trauma_TP1)
Test$Trauma_TPX <- as.numeric(Test$Trauma_TPX)
Test$Mean_age <- as.numeric(Test$Mean_age)
Test$Partner <- as.numeric(Test$Partner)
Test$Percentage_minority <- as.numeric (Test$Percentage_minority)
Test$Percentage_women <- as.numeric (Test$Percentage_women)
Test$High_education <- as.numeric(Test$High_education)
Test$Entropy <- as.numeric(Test$Entropy)
Test$N_trajectories <- as.numeric(Test$N_trajectories)
Test$TP_assessments <- as.numeric(Test$TP_assessments)
Test$Grolts <- as.numeric(Test$Grolts)


Test_clean <- Test[!is.na(Test$Sample_Size), ]

str(Test)

# Number of papers = 99

# Total number of samples / cohorts in dataset
total_number_of_samples <- nrow(Test)
print(total_number_of_samples)

total_sample_size <- sum(Test$Sample_Size, na.rm = TRUE)
print(total_sample_size)



# ============================
# 🚀 LOW SYMPTOM TRAJECTORY
# ============================

Test_clean <- Test

Test_clean <- subset(Test_clean, !is.na(Resilient_trajectory) & !is.na(Sample_Size))

Test_clean$Resilient_n <- round((Test_clean$Resilient_trajectory / 100) * Test_clean$Sample_Size)

extreme <- (Test_clean$Resilient_n == 0 | Test_clean$Resilient_n == Test_clean$Sample_Size)
Test_clean$Resilient_n[extreme] <- Test_clean$Resilient_n[extreme] + 0.5
Test_clean$Sample_Size[extreme] <- Test_clean$Sample_Size[extreme] + 1

Test_clean$Resilient_n <- as.integer(Test_clean$Resilient_n)

glmm_resilient <- rma.glmm(
  measure = "PLO",
  xi = Resilient_n,
  ni = Sample_Size,
  data = Test_clean
)

cat("\nResilient - ALL studies:",
    round(plogis(coef(glmm_resilient)), 3),
    "[", round(plogis(glmm_resilient$ci.lb), 3),
    "-", round(plogis(glmm_resilient$ci.ub), 3), "]\n")

summary(glmm_resilient)


#Number of individuals 
sum(Test_clean$Resilient_n, na.rm = TRUE)


unique(Test_clean$Study)


#########Sensitive Analysis 1 - excluding studies with extreme proportions 

resilient_sens <- subset(Test_clean, Resilient_trajectory < 90 & !is.na(Resilient_n) & !is.na(Sample_Size))

glmm_resilient_sens <- rma.glmm(
  measure = "PLO",
  xi = Resilient_n,
  ni = Sample_Size,
  data = resilient_sens
)



resilient_sens <- Test_clean[Test_clean$Resilient_Proportion < 0.90, ]
cat("Resilient - Excl. ≥90%:", round(plogis(coef(glmm_resilient_sens)), 3), 
    "[", round(plogis(glmm_resilient_sens$ci.lb), 3), "-", round(plogis(glmm_resilient_sens$ci.ub), 3), "]\n")
summary(glmm_resilient_sens)


########Sensitive Analysis 2 - Including only samples over 999 individuals 

resilient_large <- Test_clean[Test_clean$Sample_Size > 999, ]
glmm_resilient_large <- rma.glmm(measure = "PLO", xi = resilient_large$Resilient_n, ni = resilient_large$Sample_Size, data = resilient_large)
cat("Resilient - N > 999:", round(plogis(coef(glmm_resilient_large)), 3), 
    "[", round(plogis(glmm_resilient_large$ci.lb), 3), "-", round(plogis(glmm_resilient_large$ci.ub), 3), "]\n")
summary(glmm_resilient_large)



# ===============================
# 🔍 INFLUENTIAL STUDIES — LOW SYMPTOM TRAJECTORY
# ===============================

# Fit your GLMM using glmer
model_glmer <- glmer(cbind(Resilient_n, Sample_Size - Resilient_n) ~ 1 + (1 | Study),
                     data = Test_clean, family = binomial)

# Run influence analysis by Study
infl <- influence(model_glmer, group = "Study")

# Compute Cook's distance
cooks <- cooks.distance(infl)

# Plot it
plot(cooks, type = "h", lwd = 2,
     main = "Cook's Distance per Study",
     ylab = "Cook's Distance", xlab = "Study Index")
abline(h = 4 / length(cooks), col = "red", lty = 2)  # common cutoff
# Recreate Cook's distance object
cooks <- cooks.distance(infl)


# Or get all studies above the rule-of-thumb threshold
threshold <- 4 / length(cooks)
which(cooks > threshold)


Test_sens <- Test_clean[!Test_clean$Study %in% Test_clean$Study[c(3, 24, 33, 69)], ]

glmm_sens <- rma.glmm(
  measure = "PLO",
  xi = Test_sens$Resilient_n,
  ni = Test_sens$Sample_Size,
  data = Test_sens
)

summary(glmm_sens)


# Back-transform logit to proportion
plogis(1.0053)          # Point estimate
plogis(0.8470)          # Lower bound
plogis(1.1636)          # Upper bound








Test_clean[3, 24, 33, 69]

model_glmer <- glmer(cbind(Resilient_n, Sample_Size - Resilient_n) ~ 1 + (1 | Study),
                     data = Test_clean, family = binomial)
summary(model_glmer)
plogis(fixef(model_glmer)["(Intercept)"])
# Extract estimate and standard error
est <- fixef(model_glmer)["(Intercept)"]
se <- sqrt(vcov(model_glmer)["(Intercept)", "(Intercept)"])

# Compute 95% CI in logit scale
ci_lower <- est - 1.96 * se
ci_upper <- est + 1.96 * se

# Back-transform to probability scale
plogis(est)        # point estimate
plogis(ci_lower)   # lower bound
plogis(ci_upper)   # upper bound



# ---- Continuous moderators ----


mod_data <- Test_clean
mod_data$Sample_Size_100 <- mod_data$Sample_Size / 100
# Percentage of women
model <- glmer(cbind(Resilient_n, Sample_Size - Resilient_n) ~ Percentage_women + (1 | Study),
               data = subset(mod_data, !is.na(Percentage_women)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  # Estimated prevalence at Percentage_women = 0

b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Percentage_women"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))

# Mean age
model <- glmer(cbind(Resilient_n, Sample_Size - Resilient_n) ~ Mean_age + (1 | Study),
               data = subset(mod_data, !is.na(Mean_age)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  # Estimated prevalence at Mean_age = 0



b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Mean_age"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))


# Percentage of minorities
model <- glmer(cbind(Resilient_n, Sample_Size - Resilient_n) ~ Percentage_minority + (1 | Study),
               data = subset(mod_data, !is.na(Percentage_minority)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])


b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Percentage_minority"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))




# Partner
model <- glmer(cbind(Resilient_n, Sample_Size - Resilient_n) ~ Partner + (1 | Study),
               data = subset(mod_data, !is.na(Partner)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])

b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Partner"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))



# High education
model <- glmer(cbind(Resilient_n, Sample_Size - Resilient_n) ~ High_education + (1 | Study),
               data = subset(mod_data, !is.na(High_education)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["High_education"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))

# Number of timepoints
model <- glmer(cbind(Resilient_n, Sample_Size - Resilient_n) ~ TP_assessments + (1 | Study),
               data = subset(mod_data, !is.na(TP_assessments)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["TP_assessments"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))

# Number of trajectories
model <- glmer(cbind(Resilient_n, Sample_Size - Resilient_n) ~ N_trajectories + (1 | Study),
               data = subset(mod_data, !is.na(N_trajectories)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["N_trajectories"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))



# Time between trauma and T1
model <- glmer(cbind(Resilient_n, Sample_Size - Resilient_n) ~ Trauma_TP1 + (1 | Study),
               data = subset(mod_data, !is.na(Trauma_TP1)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Trauma_TP1"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))



# Time span of study
model <- glmer(cbind(Resilient_n, Sample_Size - Resilient_n) ~ TP1_TPX + (1 | Study),
               data = subset(mod_data, !is.na(TP1_TPX)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["TP1_TPX"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))

# Time between trauma and last assessment
model <- glmer(cbind(Resilient_n, Sample_Size - Resilient_n) ~ Trauma_TPX + (1 | Study),
               data = subset(mod_data, !is.na(Trauma_TPX)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Trauma_TPX"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))



# Sample size (scaled)
model <- glmer(cbind(Resilient_n, Sample_Size - Resilient_n) ~ Sample_Size_100 + (1 | Study),
               data = subset(mod_data, !is.na(Sample_Size_100)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Sample_Size_100"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))



#Entropy

model <- glmer(cbind(Resilient_n, Sample_Size - Resilient_n) ~ Entropy + (1 | Study),
               data = subset(mod_data, !is.na(Entropy)), family = binomial)

summary(model)

plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Entropy"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))




#Grolts


model <- glmer(cbind(Resilient_n, Sample_Size - Resilient_n) ~ Grolts + (1 | Study),
               data = subset(mod_data, !is.na(Grolts)), family = binomial)

summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Grolts"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))



# ---- Categorical moderators ----

# DSM-5 vs DSM-IV
model <- glmer(cbind(Resilient_n, Sample_Size - Resilient_n) ~ factor(Diagnostic_DSM) + (1 | Study),
               data = subset(mod_data, Diagnostic_DSM %in% c("4", "5")), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  # DSM-IV (reference)
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Diagnostic_DSM)5"])  # DSM-5

# Occupational trauma
model <- glmer(cbind(Resilient_n, Sample_Size - Resilient_n) ~ factor(Occupational_trauma) + (1 | Study),
               data = subset(mod_data, Occupational_trauma %in% c("Yes", "No")), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  # Reference (e.g., No)
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Occupational_trauma)Yes"])


# Developmental age
model <- glmer(cbind(Resilient_n, Sample_Size - Resilient_n) ~ factor(Developmental_age) + (1 | Study),
               data = subset(mod_data, Developmental_age %in% c("Adult", "Youth")), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  # Adult
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Developmental_age)Youth"])

# Country income
model <- glmer(cbind(Resilient_n, Sample_Size - Resilient_n) ~ factor(Location) + (1 | Study),
               data = subset(mod_data, !is.na(Location)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  # Reference group (e.g., High income)

# US vs non-US
model <- glmer(cbind(Resilient_n, Sample_Size - Resilient_n) ~ factor(Location_US) + (1 | Study),
               data = subset(mod_data, !is.na(Location_US)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  # Non-US
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Location_US)US"])

# LGMM vs LCGA
model <- glmer(cbind(Resilient_n, Sample_Size - Resilient_n) ~ factor(Trajectory_analysis) + (1 | Study),
               data = subset(mod_data, !is.na(Trajectory_analysis)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  # Reference model (e.g., LCGA)

# PTSD assessment: Interview vs Self
model <- glmer(cbind(Resilient_n, Sample_Size - Resilient_n) ~ factor(Scale_moderator) + (1 | Study),
               data = subset(mod_data, Scale_moderator %in% c("Interview", "Self")), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  # Interview
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Scale_moderator)Self"])

# Interpersonal vs non-interpersonal trauma
model <- glmer(cbind(Resilient_n, Sample_Size - Resilient_n) ~ factor(Trauma_exposure) + (1 | Study),
               data = subset(mod_data, Trauma_exposure %in% c("Inter", "Non")), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  # Interpersonal
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Trauma_exposure)Non"])

# Trauma type: Combat, Natural, Injury
model <- glmer(cbind(Resilient_n, Sample_Size - Resilient_n) ~ factor(Trauma_type) + (1 | Study),
               data = subset(mod_data, Trauma_type %in% c("Combat", "Natural", "Injury")), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  # Reference trauma type (alphabetically first unless redefined)
# Combat (referência)
plogis(fixef(model)["(Intercept)"])
# ≈ 0.792 → 79.2%

# Injury
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Trauma_type)Injury"])
# ≈ plogis(1.3396 - 0.6071) = plogis(0.7325) ≈ 0.675 → 67.5%

# Natural
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Trauma_type)Natural"])
# ≈ plogis(1.3396 - 0.6605) = plogis(0.6791) ≈ 0.663 → 66.3%




# Military population
model <- glmer(cbind(Resilient_n, Sample_Size - Resilient_n) ~ factor(Military) + (1 | Study),
               data = subset(mod_data, !is.na(Military)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  # No (if reference)
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Military)Yes"])


# Discrete
model <- glmer(cbind(Resilient_n, Sample_Size - Resilient_n) ~ factor(Discrete) + (1 | Study),
               data = subset(mod_data, Discrete %in% c("Yes", "No")), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Discrete)Yes"])

# Health workers + First respondents versus other

mod_data$Health_First <- relevel(factor(mod_data$Health_First), ref = "Yes")
model <- glmer(cbind(Resilient_n, Sample_Size - Resilient_n) ~ factor(Health_First) + (1 | Study),
               data = subset(mod_data, Health_First %in% c("Yes", "No")), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Health_First)No"])


# ============================
# 🌿 RECOVERY
# ============================


Test_clean <- Test[!is.na(Test$Sample_Size), ]


Test_clean$Recovery_n <- round((Test_clean$Recovery_trajectory / 100) * Test_clean$Sample_Size)
Test_clean$Recovery_Proportion <- Test_clean$Recovery_n / Test_clean$Sample_Size

extreme <- !is.na(Test_clean$Recovery_n) & (Test_clean$Recovery_n == 0 | Test_clean$Recovery_n == Test_clean$Sample_Size)
Test_clean$Recovery_n[extreme] <- Test_clean$Recovery_n[extreme] + 0.5
Test_clean$Sample_Size[extreme] <- Test_clean$Sample_Size[extreme] + 1
Test_clean$Recovery_n <- as.integer(Test_clean$Recovery_n)

glmm_recovery <- rma.glmm(measure = "PLO", xi = Test_clean$Recovery_n, ni = Test_clean$Sample_Size, data = Test_clean)
cat("\nRecovery - ALL studies:", round(plogis(coef(glmm_recovery)), 3), 
    "[", round(plogis(glmm_recovery$ci.lb), 3), "-", round(plogis(glmm_recovery$ci.ub), 3), "]\n")
summary(glmm_recovery)

sum(Test_clean$Recovery_n, na.rm = TRUE)
unique(Test_clean$Study[!is.na(Test_clean$Recovery_trajectory)])


####### Sensitive Analysis. Eliminate extreme proportions
recovery_sens <- Test_clean[Test_clean$Recovery_Proportion < 0.90, ]
glmm_recovery_sens <- rma.glmm(measure = "PLO", xi = recovery_sens$Recovery_n, ni = recovery_sens$Sample_Size, data = recovery_sens)
cat("Recovery - Excl. ≥90%:", round(plogis(coef(glmm_recovery_sens)), 3), 
    "[", round(plogis(glmm_recovery_sens$ci.lb), 3), "-", round(plogis(glmm_recovery_sens$ci.ub), 3), "]\n")
summary(glmm_recovery_sens)

##############Sensitive analysis 2 Recovery - Include studies with over 999 individuals 

recovery_large <- Test_clean[Test_clean$Sample_Size > 999, ]
glmm_recovery_large <- rma.glmm(measure = "PLO", xi = recovery_large$Recovery_n, ni = recovery_large$Sample_Size, data = recovery_large)
cat("Recovery - N > 999:", round(plogis(coef(glmm_recovery_large)), 3), 
    "[", round(plogis(glmm_recovery_large$ci.lb), 3), "-", round(plogis(glmm_recovery_large$ci.ub), 3), "]\n")
summary(glmm_recovery_large)



# ===============================
# ===============================
# ===============================
# 🔍 RECOVERY TRAJECTORY — INFLUENTIAL STUDIES + REFIT
# ===============================

# ===============================
# ✅ CORRECTED: RECOVERY TRAJECTORY — REMOVE INFLUENTIAL ROWS (BY INDEX)
# ===============================



model_glmer_recovery <- glmer(cbind(Recovery_n, Sample_Size - Recovery_n) ~ 1 + (1 | Study),
                              data = Test_clean, family = binomial)

infl_recovery <- influence(model_glmer_recovery, group = "Study")

cooks_recovery <- cooks.distance(infl_recovery)

threshold <- 4 / length(cooks_recovery)
influential_idx <- which(cooks_recovery > threshold)
threshold <- 4 / length(cooks)
which(cooks > threshold)


rows_to_remove <- c(3, 24, 33, 69)
Test_clean_noinf <- Test_clean[-rows_to_remove, ]

glmm_recovery_noinf <- rma.glmm(
  measure = "PLO",
  xi = Recovery_n,
  ni = Sample_Size,
  data = Test_clean_noinf
)

# View summary
summary(glmm_recovery_noinf)


cat("Prevalence (proportion scale):",
    round(plogis(coef(glmm_recovery_noinf)), 3),
    "[", round(plogis(glmm_recovery_noinf$ci.lb), 3), "-", round(plogis(glmm_recovery_noinf$ci.ub), 3), "]\n")

excluded_studies <- Test_clean$Study[c(3, 24, 33, 69)]
excluded_studies


# ===============================
# 🌿 Recovery – Continuous Moderators
# ===============================

# Prepare moderator dataset for recovery moderation analysis
mod_data <- Test_clean
mod_data$Sample_Size_100 <- mod_data$Sample_Size / 100

# Percentage of women
model <- glmer(cbind(Recovery_n, Sample_Size - Recovery_n) ~ Percentage_women + (1 | Study),
               data = subset(mod_data, !is.na(Percentage_women)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Percentage_women"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))


# Mean age
model <- glmer(cbind(Recovery_n, Sample_Size - Recovery_n) ~ Mean_age + (1 | Study),
               data = subset(mod_data, !is.na(Mean_age)), family = binomial)

summary(model)

plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Mean_age"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))

# Percentage of minorities
model <- glmer(cbind(Recovery_n, Sample_Size - Recovery_n) ~ Percentage_minority + (1 | Study),
               data = subset(mod_data, !is.na(Percentage_minority)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Percentage_minority"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))



# Partner
model <- glmer(cbind(Recovery_n, Sample_Size - Recovery_n) ~ Partner + (1 | Study),
               data = subset(mod_data, !is.na(Partner)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Partner"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))


# High education
model <- glmer(cbind(Recovery_n, Sample_Size - Recovery_n) ~ High_education + (1 | Study),
               data = subset(mod_data, !is.na(High_education)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["High_education"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))



# Number of timepoints
model <- glmer(cbind(Recovery_n, Sample_Size - Recovery_n) ~ TP_assessments + (1 | Study),
               data = subset(mod_data, !is.na(TP_assessments)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["TP_assessments"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))

# Number of trajectories
model <- glmer(cbind(Recovery_n, Sample_Size - Recovery_n) ~ N_trajectories + (1 | Study),
               data = subset(mod_data, !is.na(N_trajectories)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["N_trajectories"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))


# Time between trauma and T1
model <- glmer(cbind(Recovery_n, Sample_Size - Recovery_n) ~ Trauma_TP1 + (1 | Study),
               data = subset(mod_data, !is.na(Trauma_TP1)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Trauma_TP1"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))


# Time span of study
model <- glmer(cbind(Recovery_n, Sample_Size - Recovery_n) ~ TP1_TPX + (1 | Study),
               data = subset(mod_data, !is.na(TP1_TPX)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["TP1_TPX"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))




# Time from trauma to last assessment
model <- glmer(cbind(Recovery_n, Sample_Size - Recovery_n) ~ Trauma_TPX + (1 | Study),
               data = subset(mod_data, !is.na(Trauma_TPX)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Trauma_TPX"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))

# Sample size (scaled)
model <- glmer(cbind(Recovery_n, Sample_Size - Recovery_n) ~ Sample_Size_100 + (1 | Study),
               data = subset(mod_data, !is.na(Sample_Size_100)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Sample_Size_100"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))

#Entropy
model <- glmer(cbind(Recovery_n, Sample_Size - Recovery_n) ~ Entropy + (1 | Study),
               data = subset(mod_data, !is.na(Entropy)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Entropy"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))






# Prevalência quando Entropy = 0
p0 <- plogis(fixef(model)["(Intercept)"])

# Marginal effect for 0.1 increase in Entropy
marginal_effect_01 <- b1 * 0.1 * p0 * (1 - p0)

# Resultado em pontos percentuais
marginal_effect_01 * 100

# Grolts
model <- glmer(cbind(Recovery_n, Sample_Size - Recovery_n) ~ Grolts + (1 | Study),
               data = subset(mod_data, !is.na(Grolts)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Grolts"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))




# ===============================
# 🌿 Recovery – Categorical Moderators
# ===============================

# DSM-5 vs DSM-IV
model <- glmer(cbind(Recovery_n, Sample_Size - Recovery_n) ~ factor(Diagnostic_DSM) + (1 | Study),
               data = subset(mod_data, Diagnostic_DSM %in% c("4", "5")), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  # DSM-IV
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Diagnostic_DSM)5"])

# Occupational trauma
model <- glmer(cbind(Recovery_n, Sample_Size - Recovery_n) ~ factor(Occupational_trauma) + (1 | Study),
               data = subset(mod_data, Occupational_trauma %in% c("Yes", "No")), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  # No
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Occupational_trauma)Yes"])


# Developmental age
model <- glmer(cbind(Recovery_n, Sample_Size - Recovery_n) ~ factor(Developmental_age) + (1 | Study),
               data = subset(mod_data, Developmental_age %in% c("Adult", "Youth")), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  # Adult
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Developmental_age)Youth"])

# Country income
model <- glmer(cbind(Recovery_n, Sample_Size - Recovery_n) ~ factor(Location) + (1 | Study),
               data = subset(mod_data, !is.na(Location)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  # Reference (e.g., High)
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Location)ML"])




# US vs Non-US
model <- glmer(cbind(Recovery_n, Sample_Size - Recovery_n) ~ factor(Location_US) + (1 | Study),
               data = subset(mod_data, !is.na(Location_US)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  # Non-US
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Location_US)US"])

# LGMM vs LCGA
model <- glmer(cbind(Recovery_n, Sample_Size - Recovery_n) ~ factor(Trajectory_analysis) + (1 | Study),
               data = subset(mod_data, !is.na(Trajectory_analysis)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  # LCGA (if reference)
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Trajectory_analysis)LGMM"])



# PTSD assessment method
model <- glmer(cbind(Recovery_n, Sample_Size - Recovery_n) ~ factor(Scale_moderator) + (1 | Study),
               data = subset(mod_data, Scale_moderator %in% c("Interview", "Self")), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  # Interview
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Scale_moderator)Self"])

# Interpersonal vs non-interpersonal trauma
model <- glmer(cbind(Recovery_n, Sample_Size - Recovery_n) ~ factor(Trauma_exposure) + (1 | Study),
               data = subset(mod_data, Trauma_exposure %in% c("Inter", "Non")), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  # Interpersonal
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Trauma_exposure)Non"])

# Trauma type
model <- glmer(cbind(Recovery_n, Sample_Size - Recovery_n) ~ factor(Trauma_type) + (1 | Study),
               data = subset(mod_data, Trauma_type %in% c("Combat", "Natural", "Injury")), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  # Combat (if reference)
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Trauma_type)Injury"])
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Trauma_type)Natural"])

# Military sample
model <- glmer(cbind(Recovery_n, Sample_Size - Recovery_n) ~ factor(Military) + (1 | Study),
               data = subset(mod_data, !is.na(Military)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  # Civilian
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Military)Yes"])



# Discrete trauma

mod_data$Discrete <- relevel(factor(mod_data$Discrete), ref = "Yes")
model <- glmer(cbind(Recovery_n, Sample_Size - Recovery_n) ~ factor(Discrete) + (1 | Study),
               data = subset(mod_data, Discrete %in% c("Yes", "No")), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Discrete)No"])


# Health + First responders versus other 

model <- glmer(cbind(Recovery_n, Sample_Size - Recovery_n) ~ factor(Health_First) + (1 | Study),
               data = subset(mod_data, Discrete %in% c("Yes", "No")), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Heath_First)Yes"])



# ============================
# ⚠️ WORSENING
# ============================
Test_clean <- Test[!is.na(Test$Sample_Size), ]

Test_clean$Worsening_n <- round((Test_clean$Worsening_trajectory / 100) * Test_clean$Sample_Size)
Test_clean$Worsening_Proportion <- Test_clean$Worsening_n / Test_clean$Sample_Size
extreme <- !is.na(Test_clean$Worsening_n) & (Test_clean$Worsening_n == 0 | Test_clean$Worsening_n == Test_clean$Sample_Size)
Test_clean$Worsening_n[extreme] <- Test_clean$Worsening_n[extreme] + 0.5
Test_clean$Sample_Size[extreme] <- Test_clean$Sample_Size[extreme] + 1
Test_clean$Worsening_n <- as.integer(Test_clean$Worsening_n)

glmm_worsening <- rma.glmm(measure = "PLO", xi = Test_clean$Worsening_n, ni = Test_clean$Sample_Size, data = Test_clean)
cat("\nWorsening - ALL studies:", round(plogis(coef(glmm_worsening)), 3), 
    "[", round(plogis(glmm_worsening$ci.lb), 3), "-", round(plogis(glmm_worsening$ci.ub), 3), "]\n")
summary(glmm_worsening)

sum(Test_clean$Worsening_n, na.rm = TRUE)
unique(Test_clean$Study[!is.na(Test_clean$Worsening_trajectory)])



worsening_sens <- Test_clean[Test_clean$Worsening_Proportion < 0.90, ]
glmm_worsening_sens <- rma.glmm(measure = "PLO", xi = worsening_sens$Worsening_n, ni = worsening_sens$Sample_Size, data = worsening_sens)
cat("Worsening - Excl. ≥90%:", round(plogis(coef(glmm_worsening_sens)), 3), 
    "[", round(plogis(glmm_worsening_sens$ci.lb), 3), "-", round(plogis(glmm_worsening_sens$ci.ub), 3), "]\n")
summary(glmm_worsening_sens)


worsening_large <- Test_clean[Test_clean$Sample_Size > 999, ]
glmm_worsening_large <- rma.glmm(measure = "PLO", xi = worsening_large$Worsening_n, ni = worsening_large$Sample_Size, data = worsening_large)
cat("Worsening - N > 999:", round(plogis(coef(glmm_worsening_large)), 3), 
    "[", round(plogis(glmm_worsening_large$ci.lb), 3), "-", round(plogis(glmm_worsening_large$ci.ub), 3), "]\n")
summary(glmm_worsening_large)



# ===============================
# ⚠️ WORSENING TRAJECTORY — INFLUENTIAL STUDY CHECK
# ===============================

# STEP 1: Fit null model for worsening trajectory
model_glmer_worsening <- glmer(cbind(Worsening_n, Sample_Size - Worsening_n) ~ 1 + (1 | Study),
                               data = Test_clean, family = binomial)

# STEP 2: Run influence diagnostics by Study
infl_worsening <- influence(model_glmer_worsening, group = "Study")

# STEP 3: Compute Cook's distance
cooks_worsening <- cooks.distance(infl_worsening)

# STEP 4: Plot Cook's distance
plot(cooks_worsening, type = "h", lwd = 2,
     main = "Cook's Distance per Study (Worsening)",
     ylab = "Cook's Distance", xlab = "Study Index")
abline(h = 4 / length(cooks_worsening), col = "red", lty = 2)

# STEP 5: Identify influential studies
threshold <- 4 / length(cooks_worsening)
which(cooks_worsening > threshold)     # returns the row indices
which.max(cooks_worsening)             # returns the single most influential one


# Remover os estudos 29 e 43 pela posição na base
Test_sens_worsening <- Test_clean[-c(29, 43), ]

# Rodar o modelo GLMM
glmm_worsening_sens <- rma.glmm(
  measure = "PLO",
  xi = Test_sens_worsening$Worsening_n,
  ni = Test_sens_worsening$Sample_Size,
  data = Test_sens_worsening
)

summary(glmm_worsening_sens)

Test_clean$Study[c(29, 43)]

cat("Prevalence (proportion scale):",
    round(plogis(-2.2795), 3),
    "[", round(plogis(-2.5144), 3), "-", round(plogis(-2.0446), 3), "]\n")


cat("Prevalence (proportion scale):",
    round(plogis(-2.4059), 3),
    "[", round(plogis(-2.6190), 3), "-", round(plogis(-2.1929), 3), "]\n")


Test_clean_noinf <- Test_clean[-c(27, 40), ]

model_glmer_worsening_noinf <- glmer(cbind(Worsening_n, Sample_Size - Worsening_n) ~ 1 + (1 | Study),
                                     data = Test_clean_noinf, family = binomial)

est <- fixef(model_glmer_worsening_noinf)["(Intercept)"]
se <- sqrt(vcov(model_glmer_worsening_noinf)["(Intercept)", "(Intercept)"])
ci_lower <- est - 1.96 * se
ci_upper <- est + 1.96 * se

plogis(est)
plogis(ci_lower)
plogis(ci_upper)

summary(model_glmer_worsening_noinf)

Test_clean$Study[c(27, 40)]


# ===============================
# ⚠️ WORSENING TRAJECTORY — MODERATORS
# ===============================
mod_data <- Test_clean
mod_data$Sample_Size_100 <- mod_data$Sample_Size / 100

# ===============================
# 📊 CONTINUOUS MODERATORS
# ===============================

# Percentage of women
model <- glmer(cbind(Worsening_n, Sample_Size - Worsening_n) ~ Percentage_women + (1 | Study),
               data = subset(mod_data, !is.na(Percentage_women)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Percentage_women"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))

# Mean age
model <- glmer(cbind(Worsening_n, Sample_Size - Worsening_n) ~ Mean_age + (1 | Study),
               data = subset(mod_data, !is.na(Mean_age)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Mean_age"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))

# Percentage of minorities
model <- glmer(cbind(Worsening_n, Sample_Size - Worsening_n) ~ Percentage_minority + (1 | Study),
               data = subset(mod_data, !is.na(Percentage_minority)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b1 <- fixef(model)["Percentage_minority"]
p0 <- plogis(fixef(model)["(Intercept)"])
b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))



# Partner
model <- glmer(cbind(Worsening_n, Sample_Size - Worsening_n) ~ Partner + (1 | Study),
               data = subset(mod_data, !is.na(Partner)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b1 <- fixef(model)["Partner"]
p0 <- plogis(fixef(model)["(Intercept)"])
b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))



# High education
model <- glmer(cbind(Worsening_n, Sample_Size - Worsening_n) ~ High_education + (1 | Study),
               data = subset(mod_data, !is.na(High_education)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b1 <- fixef(model)["High_education"]
p0 <- plogis(fixef(model)["(Intercept)"])
b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))



# TP assessments
model <- glmer(cbind(Worsening_n, Sample_Size - Worsening_n) ~ TP_assessments + (1 | Study),
               data = subset(mod_data, !is.na(TP_assessments)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b1 <- fixef(model)["TP_assessemnts"]
p0 <- plogis(fixef(model)["(Intercept)"])
b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))


# Number of trajectories
model <- glmer(cbind(Worsening_n, Sample_Size - Worsening_n) ~ N_trajectories + (1 | Study),
               data = subset(mod_data, !is.na(N_trajectories)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b1 <- fixef(model)["N_trajectories"]
p0 <- plogis(fixef(model)["(Intercept)"])
b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))




# Trauma_TP1
model <- glmer(cbind(Worsening_n, Sample_Size - Worsening_n) ~ Trauma_TP1 + (1 | Study),
               data = subset(mod_data, !is.na(Trauma_TP1)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b1 <- fixef(model)["Trauma_TP1"]
p0 <- plogis(fixef(model)["(Intercept)"])
b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))


# TP1_TPX
model <- glmer(cbind(Worsening_n, Sample_Size - Worsening_n) ~ TP1_TPX + (1 | Study),
               data = subset(mod_data, !is.na(TP1_TPX)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b1 <- fixef(model)["TP1_TPX"]
p0 <- plogis(fixef(model)["(Intercept)"])
b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))




# Trauma_TPX
model <- glmer(cbind(Worsening_n, Sample_Size - Worsening_n) ~ Trauma_TPX + (1 | Study),
               data = subset(mod_data, !is.na(Trauma_TPX)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b1 <- fixef(model)["Trauma_TPX"]
p0 <- plogis(fixef(model)["(Intercept)"])
b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))


# Sample size (scaled)
model <- glmer(cbind(Worsening_n, Sample_Size - Worsening_n) ~ Sample_Size_100 + (1 | Study),
               data = subset(mod_data, !is.na(Sample_Size_100)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b1 <- fixef(model)["Sample_Size_100"]
p0 <- plogis(fixef(model)["(Intercept)"])
b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))




# Entropy
model <- glmer(cbind(Worsening_n, Sample_Size - Worsening_n) ~ Entropy + (1 | Study),
               data = subset(mod_data, !is.na(Entropy)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Entropy"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))


# Grolts
model <- glmer(cbind(Worsening_n, Sample_Size - Worsening_n) ~ Grolts + (1 | Study),
               data = subset(mod_data, !is.na(Grolts)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Grolts"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))





# ===============================
# 🧾 CATEGORICAL MODERATORS
# ===============================

# DSM-5 vs DSM-IV
model <- glmer(cbind(Worsening_n, Sample_Size - Worsening_n) ~ factor(Diagnostic_DSM) + (1 | Study),
               data = subset(mod_data, Diagnostic_DSM %in% c("4", "5")), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  # DSM-IV
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Diagnostic_DSM)5"])

# Occupational trauma
model <- glmer(cbind(Worsening_n, Sample_Size - Worsening_n) ~ factor(Occupational_trauma) + (1 | Study),
               data = subset(mod_data, Occupational_trauma %in% c("Yes", "No")), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  # No
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Occupational_trauma)Yes"])


# Developmental age
model <- glmer(cbind(Worsening_n, Sample_Size - Worsening_n) ~ factor(Developmental_age) + (1 | Study),
               data = subset(mod_data, Developmental_age %in% c("Adult", "Youth")), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  # Adult
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Developmental_age)Youth"])

# Country income
model <- glmer(cbind(Worsening_n, Sample_Size - Worsening_n) ~ factor(Location) + (1 | Study),
               data = subset(mod_data, !is.na(Location)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Location)ML"])




# US vs non-US
model <- glmer(cbind(Worsening_n, Sample_Size - Worsening_n) ~ factor(Location_US) + (1 | Study),
               data = subset(mod_data, !is.na(Location_US)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  # Non-US
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Location_US)US"])

# LGMM vs LCGA
model <- glmer(cbind(Worsening_n, Sample_Size - Worsening_n) ~ factor(Trajectory_analysis) + (1 | Study),
               data = subset(mod_data, !is.na(Trajectory_analysis)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Trajectory_analysis)LGMM"])


# PTSD scale method
model <- glmer(cbind(Worsening_n, Sample_Size - Worsening_n) ~ factor(Scale_moderator) + (1 | Study),
               data = subset(mod_data, Scale_moderator %in% c("Interview", "Self")), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  # Interview
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Scale_moderator)Self"])

# Trauma exposure type
model <- glmer(cbind(Worsening_n, Sample_Size - Worsening_n) ~ factor(Trauma_exposure) + (1 | Study),
               data = subset(mod_data, Trauma_exposure %in% c("Inter", "Non")), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  # Interpersonal
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Trauma_exposure)Non"])

# Trauma type
model <- glmer(cbind(Worsening_n, Sample_Size - Worsening_n) ~ factor(Trauma_type) + (1 | Study),
               data = subset(mod_data, Trauma_type %in% c("Combat", "Natural", "Injury")), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Trauma_type)Injury"])
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Trauma_type)Natural"])

# Military population
model <- glmer(cbind(Worsening_n, Sample_Size - Worsening_n) ~ factor(Military) + (1 | Study),
               data = subset(mod_data, !is.na(Military)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Military)Yes"])


# Discrete
model <- glmer(cbind(Worsening_n, Sample_Size - Worsening_n) ~ factor(Discrete) + (1 | Study),
               data = subset(mod_data, !is.na(Discrete)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Discrete)Yes"])



# Health workers + First respondents versus other

mod_data$Health_First <- relevel(factor(mod_data$Health_First), ref = "Yes")
model <- glmer(cbind(Worsening_n, Sample_Size - Worsening_n) ~ factor(Health_First) + (1 | Study),
               data = subset(mod_data, Health_First %in% c("Yes", "No")), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Health_First)No"])



# ===============================
# 🩸 CHRONIC TRAJECTORY — OVERALL & SENSITIVITY ANALYSES
# ===============================

# Step 1: Compute count and proportion
Test_clean$Chronic_n <- round((Test_clean$Chronic_ponto / 100) * Test_clean$Sample_Size)
Test_clean$Chronic_Proportion <- Test_clean$Chronic_n / Test_clean$Sample_Size

# Step 2: Continuity correction for 0% or 100%
extreme <- !is.na(Test_clean$Chronic_n) & 
  (Test_clean$Chronic_n == 0 | Test_clean$Chronic_n == Test_clean$Sample_Size)
Test_clean$Chronic_n[extreme] <- Test_clean$Chronic_n[extreme] + 0.5
Test_clean$Sample_Size[extreme] <- Test_clean$Sample_Size[extreme] + 1
Test_clean$Chronic_n <- as.integer(Test_clean$Chronic_n)

# ========== OVERALL PREVALENCE ==========
glmm_chronic <- rma.glmm(measure = "PLO", xi = Test_clean$Chronic_n, ni = Test_clean$Sample_Size, data = Test_clean)
summary(glmm_chronic)
plogis(coef(glmm_chronic))        # point estimate
plogis(glmm_chronic$ci.lb)        # lower CI
plogis(glmm_chronic$ci.ub)        # upper CI
sum(Test_clean$Chronic_n, na.rm = TRUE)
unique(Test_clean$Study[!is.na(Test_clean$Chronic_ponto)])


# ========== SENSITIVITY: Exclude prevalence ≥ 90% ==========
chronic_sens <- Test_clean[Test_clean$Chronic_Proportion < 0.90, ]
glmm_chronic_sens <- rma.glmm(measure = "PLO", xi = chronic_sens$Chronic_n, ni = chronic_sens$Sample_Size, data = chronic_sens)
summary(glmm_chronic_sens)
plogis(coef(glmm_chronic_sens))
plogis(glmm_chronic_sens$ci.lb)
plogis(glmm_chronic_sens$ci.ub)

# ========== SENSITIVITY: Sample size > 999 ==========
chronic_large <- Test_clean[Test_clean$Sample_Size > 999, ]
glmm_chronic_large <- rma.glmm(measure = "PLO", xi = chronic_large$Chronic_n, ni = chronic_large$Sample_Size, data = chronic_large)
summary(glmm_chronic_large)
plogis(coef(glmm_chronic_large))
plogis(glmm_chronic_large$ci.lb)
plogis(glmm_chronic_large$ci.ub)


model_glmer_chronic <- glmer(cbind(Chronic_n, Sample_Size - Chronic_n) ~ 1 + (1 | Study),
                             data = Test_clean, family = binomial)

infl_chronic <- influence(model_glmer_chronic, group = "Study")

cooks_chronic <- cooks.distance(infl_chronic)

plot(cooks_chronic, type = "h", lwd = 2,
     main = "Cook's Distance per Study (Chronic)",
     ylab = "Cook's Distance", xlab = "Study Index")
abline(h = 4 / length(cooks_chronic), col = "red", lty = 2)

threshold <- 4 / length(cooks_chronic)
which(cooks_chronic > threshold)
which.max(cooks_chronic)

Test_sens_chronic <- Test_clean[-c(5, 15, 26, 34, 59, 62, 69), ]

glmm_chronic_sens <- rma.glmm(
  measure = "PLO",
  xi = Test_sens_chronic$Chronic_n,
  ni = Test_sens_chronic$Sample_Size,
  data = Test_sens_chronic
)

summary(glmm_chronic_sens)
cat("Prevalence (proportion scale):",
    round(plogis(-2.2795), 3),
    "[", round(plogis(-2.5144), 3), "-", round(plogis(-2.0446), 3), "]\n")

Test_clean$Study[c(5, 15, 26, 34, 59, 62, 69)]



# ===============================
# 📊 CONTINUOUS MODERATORS
# ===============================

mod_data <- Test_clean
mod_data$Sample_Size_100 <- mod_data$Sample_Size / 100

# Percentage of women
model <- glmer(cbind(Chronic_n, Sample_Size - Chronic_n) ~ Percentage_women + (1 | Study),
               data = subset(mod_data, !is.na(Percentage_women)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Percentage_women"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))


# Mean age
model <- glmer(cbind(Chronic_n, Sample_Size - Chronic_n) ~ Mean_age + (1 | Study),
               data = subset(mod_data, !is.na(Mean_age)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Mean_age"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))




# Percentage of minorities
model <- glmer(cbind(Chronic_n, Sample_Size - Chronic_n) ~ Percentage_minority + (1 | Study),
               data = subset(mod_data, !is.na(Percentage_minority)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Percentage_minority"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))




# Partner
model <- glmer(cbind(Chronic_n, Sample_Size - Chronic_n) ~ Partner + (1 | Study),
               data = subset(mod_data, !is.na(Partner)), family = binomial)
summary(model)

plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Partner"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))

# High education
model <- glmer(cbind(Chronic_n, Sample_Size - Chronic_n) ~ High_education + (1 | Study),
               data = subset(mod_data, !is.na(High_education)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["High_education"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))




# TP assessments
model <- glmer(cbind(Chronic_n, Sample_Size - Chronic_n) ~ TP_assessments + (1 | Study),
               data = subset(mod_data, !is.na(TP_assessments)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["TP_assessemnt"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))




# Number of trajectories
model <- glmer(cbind(Chronic_n, Sample_Size - Chronic_n) ~ N_trajectories + (1 | Study),
               data = subset(mod_data, !is.na(N_trajectories)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["N_trajectories"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))





# Trauma_TP1
model <- glmer(cbind(Chronic_n, Sample_Size - Chronic_n) ~ Trauma_TP1 + (1 | Study),
               data = subset(mod_data, !is.na(Trauma_TP1)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Trauma_TP1"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))



# TP1_TPX
model <- glmer(cbind(Chronic_n, Sample_Size - Chronic_n) ~ TP1_TPX + (1 | Study),
               data = subset(mod_data, !is.na(TP1_TPX)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["TP1_TPX"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))





# Trauma_TPX
model <- glmer(cbind(Chronic_n, Sample_Size - Chronic_n) ~ Trauma_TPX + (1 | Study),
               data = subset(mod_data, !is.na(Trauma_TPX)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Trauma_TPX"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))

# Sample size (scaled)
model <- glmer(cbind(Chronic_n, Sample_Size - Chronic_n) ~ Sample_Size_100 + (1 | Study),
               data = subset(mod_data, !is.na(Sample_Size_100)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Sample_size_100"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))





# Entropy
model <- glmer(cbind(Chronic_n, Sample_Size - Chronic_n) ~ Entropy + (1 | Study),
               data = subset(mod_data, !is.na(Entropy)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Entropy"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))



# Grolts
model <- glmer(cbind(Chronic_n, Sample_Size - Chronic_n) ~ Grolts + (1 | Study),
               data = subset(mod_data, !is.na(Grolts)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Grolts"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))



# ===============================
# 🧾 CATEGORICAL MODERATORS
# ===============================

# DSM-5 vs DSM-IV
model <- glmer(cbind(Chronic_n, Sample_Size - Chronic_n) ~ factor(Diagnostic_DSM) + (1 | Study),
               data = subset(mod_data, Diagnostic_DSM %in% c("4", "5")), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  # DSM-IV
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Diagnostic_DSM)5"])

# Occupational trauma
model <- glmer(cbind(Chronic_n, Sample_Size - Chronic_n) ~ factor(Occupational_trauma) + (1 | Study),
               data = subset(mod_data, Occupational_trauma %in% c("Yes", "No")), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Occupational_trauma)Yes"])


# Developmental age
model <- glmer(cbind(Chronic_n, Sample_Size - Chronic_n) ~ factor(Developmental_age) + (1 | Study),
               data = subset(mod_data, Developmental_age %in% c("Adult", "Youth")), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  # Adult
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Developmental_age)Youth"])


# Country income
model <- glmer(cbind(Chronic_n, Sample_Size - Chronic_n) ~ factor(Location) + (1 | Study),
               data = subset(mod_data, !is.na(Location)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Location)ML"])



# US vs non-US
model <- glmer(cbind(Chronic_n, Sample_Size - Chronic_n) ~ factor(Location_US) + (1 | Study),
               data = subset(mod_data, !is.na(Location_US)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Location_US)US"])

# LGMM vs LCGA
model <- glmer(cbind(Chronic_n, Sample_Size - Chronic_n) ~ factor(Trajectory_analysis) + (1 | Study),
               data = subset(mod_data, !is.na(Trajectory_analysis)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Trajectory_analysis)LGMM"])



# PTSD scale method
model <- glmer(cbind(Chronic_n, Sample_Size - Chronic_n) ~ factor(Scale_moderator) + (1 | Study),
               data = subset(mod_data, Scale_moderator %in% c("Interview", "Self")), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Scale_moderator)Self"])


# Trauma exposure type
model <- glmer(cbind(Chronic_n, Sample_Size - Chronic_n) ~ factor(Trauma_exposure) + (1 | Study),
               data = subset(mod_data, Trauma_exposure %in% c("Inter", "Non")), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  # Interpersonal
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Trauma_exposure)Non"])


# Trauma type
model <- glmer(cbind(Chronic_n, Sample_Size - Chronic_n) ~ factor(Trauma_type) + (1 | Study),
               data = subset(mod_data, Trauma_type %in% c("Combat", "Natural", "Injury")), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Trauma_type)Injury"])
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Trauma_type)Natural"])

# Military population
model <- glmer(cbind(Chronic_n, Sample_Size - Chronic_n) ~ factor(Military) + (1 | Study),
               data = subset(mod_data, !is.na(Military)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Military)Yes"])


# Discrete
model <- glmer(cbind(Chronic_n, Sample_Size - Chronic_n) ~ factor(Discrete) + (1 | Study),
               data = subset(mod_data, !is.na(Discrete)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Discrete)Yes"])


# Health + First responders versus Other 
model <- glmer(cbind(Chronic_n, Sample_Size - Chronic_n) ~ factor(Health_First) + (1 | Study),
               data = subset(mod_data, !is.na(Health_First)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Health_First)Yes"])


###################### MODERATE TRAJECTORY

Test_clean <- Test_clean[!is.na(Test_clean$Partially_symptomatic_trajectory), ]


Test_clean$Partially_n <- round((Test_clean$Partially_symptomatic_trajectory / 100) * Test_clean$Sample_Size)
Test_clean$Partially_Proportion <- Test_clean$Partially_n / Test_clean$Sample_Size

extreme <- !is.na(Test_clean$Partially_n) & 
  (Test_clean$Partially_n == 0 | Test_clean$Partially_n == Test_clean$Sample_Size)
Test_clean$Partially_n[extreme] <- Test_clean$Partially_n[extreme] + 0.5
Test_clean$Sample_Size[extreme] <- Test_clean$Sample_Size[extreme] + 1
Test_clean$Partially_n <- as.integer(Test_clean$Partially_n)

# GLMM - ALL STUDIES
glmm_partially <- rma.glmm(measure = "PLO", xi = Test_clean$Partially_n, ni = Test_clean$Sample_Size, data = Test_clean)
cat("\nPartially Symptomatic - ALL studies:", round(plogis(coef(glmm_partially)), 3), 
    "[", round(plogis(glmm_partially$ci.lb), 3), "-", round(plogis(glmm_partially$ci.ub), 3), "]\n")
summary(glmm_partially)



#Number of individuals 
sum(Test_clean$Partially_n, na.rm = TRUE)
unique(Test_clean$Study[!is.na(Test_clean$Partially_symptomatic_trajectory)])




# Sensitivity 1: Exclude extreme prevalence ≥ 90%
partially_sens <- Test_clean[Test_clean$Partially_Proportion < 0.90, ]
glmm_partially_sens <- rma.glmm(measure = "PLO", xi = partially_sens$Partially_n, ni = partially_sens$Sample_Size, data = partially_sens)
cat("Partially Symptomatic - Excl. ≥90%:", round(plogis(coef(glmm_partially_sens)), 3), 
    "[", round(plogis(glmm_partially_sens$ci.lb), 3), "-", round(plogis(glmm_partially_sens$ci.ub), 3), "]\n")
summary(glmm_partially_sens)



# Sensitivity 2: Only Sample Size > 999
partially_large <- Test_clean[Test_clean$Sample_Size > 999, ]
glmm_partially_large <- rma.glmm(measure = "PLO", xi = partially_large$Partially_n, ni = partially_large$Sample_Size, data = partially_large)
cat("Partially Symptomatic - N > 999:", round(plogis(coef(glmm_partially_large)), 3), 
    "[", round(plogis(glmm_partially_large$ci.lb), 3), "-", round(plogis(glmm_partially_large$ci.ub), 3), "]\n")
summary(glmm_partially_large)
unique(partially_large$Study)



model_glmer_partially <- glmer(cbind(Partially_n, Sample_Size - Partially_n) ~ 1 + (1 | Study),
                               data = Test_clean, family = binomial)

infl_partially <- influence(model_glmer_partially, group = "Study")
cooks_partially <- cooks.distance(infl_partially)

plot(cooks_partially, type = "h", lwd = 2,
     main = "Cook's Distance per Study (Partially Symptomatic)",
     ylab = "Cook's Distance", xlab = "Study Index")
abline(h = 4 / length(cooks_partially), col = "red", lty = 2)

threshold <- 4 / length(cooks_partially)
which(cooks_partially > threshold)
which.max(cooks_partially)


partially_sens <- Test_clean[!Test_clean$Study %in% Test_clean$Study[c(4, 25)], ]

glmm_partially_sens <- rma.glmm(
  measure = "PLO",
  xi = partially_sens$Partially_n,
  ni = partially_sens$Sample_Size,
  data = partially_sens
)

summary(glmm_partially_sens)

cat("Prevalence (proportion scale):",
    round(plogis(-1.0400), 3),
    "[", round(plogis(-1.5482), 3), "-", round(plogis(-0.5318), 3), "]\n")


Test_clean$Study[c(4, 25)]



# ===============================
# 🟡 MODERATE — CONTINUOUS MODERATORS
# ===============================
mod_data <- Test_clean
mod_data$Sample_Size_100 <- mod_data$Sample_Size / 100

# Percentage of women
model <- glmer(cbind(Partially_n, Sample_Size - Partially_n) ~ Percentage_women + (1 | Study),
               data = subset(mod_data, !is.na(Percentage_women)), family = binomial)
summary(model)

plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Percentage_women"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))

# Mean age
model <- glmer(cbind(Partially_n, Sample_Size - Partially_n) ~ Mean_age + (1 | Study),
               data = subset(mod_data, !is.na(Mean_age)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Mean_age"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))



# Percentage of minorities
model <- glmer(cbind(Partially_n, Sample_Size - Partially_n) ~ Percentage_minority + (1 | Study),
               data = subset(mod_data, !is.na(Percentage_minority)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Pencentage_minority"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))





# Partner
model <- glmer(cbind(Partially_n, Sample_Size - Partially_n) ~ Partner + (1 | Study),
               data = subset(mod_data, !is.na(Partner)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])




# High education
model <- glmer(cbind(Partially_n, Sample_Size - Partially_n) ~ High_education + (1 | Study),
               data = subset(mod_data, !is.na(High_education)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b1 <- fixef(model)["High_education"]; p0 <- plogis(fixef(model)["(Intercept)"])
b1 * p0 * (1 - p0) * 100

# TP assessments
model <- glmer(cbind(Partially_n, Sample_Size - Partially_n) ~ TP_assessments + (1 | Study),
               data = subset(mod_data, !is.na(TP_assessments)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["TP_assessments"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))

# Number of trajectories
model <- glmer(cbind(Partially_n, Sample_Size - Partially_n) ~ N_trajectories + (1 | Study),
               data = subset(mod_data, !is.na(N_trajectories)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["N_trajecrories"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))

# Trauma_TP1
model <- glmer(cbind(Partially_n, Sample_Size - Partially_n) ~ Trauma_TP1 + (1 | Study),
               data = subset(mod_data, !is.na(Trauma_TP1)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])


plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Trauma_TP1"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))


# TP1_TPX
model <- glmer(cbind(Partially_n, Sample_Size - Partially_n) ~ TP1_TPX + (1 | Study),
               data = subset(mod_data, !is.na(TP1_TPX)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["TP1_TPX"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))

# Trauma_TPX
model <- glmer(cbind(Partially_n, Sample_Size - Partially_n) ~ Trauma_TPX + (1 | Study),
               data = subset(mod_data, !is.na(Trauma_TPX)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Trauma_TPX"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))

# Sample size (per 100)
model <- glmer(cbind(Partially_n, Sample_Size - Partially_n) ~ Sample_Size_100 + (1 | Study),
               data = subset(mod_data, !is.na(Sample_Size_100)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Sample_Size_100"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))


# Entropy (effect per 0.1 point)
model <- glmer(cbind(Partially_n, Sample_Size - Partially_n) ~ Entropy + (1 | Study),
               data = subset(mod_data, !is.na(Entropy)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Entropy"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))

# Grolts
model <- glmer(cbind(Partially_n, Sample_Size - Partially_n) ~ Grolts + (1 | Study),
               data = subset(mod_data, !is.na(Grolts)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])

b0 <- fixef(model)["(Intercept)"]
b1 <- fixef(model)["Grolts"]
p0 <- plogis(b0)
delta <- b1 * p0 * (1 - p0) * 100
cat("Marginal Delta:", round(delta, 2))


#######Categorical moderators moderate

# DSM-5 vs DSM-IV
model <- glmer(cbind(Partially_n, Sample_Size - Partially_n) ~ factor(Diagnostic_DSM) + (1 | Study),
               data = subset(mod_data, Diagnostic_DSM %in% c("4", "5")), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  # DSM-IV
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Diagnostic_DSM)5"])

# Occupational trauma
model <- glmer(cbind(Partially_n, Sample_Size - Partially_n) ~ factor(Occupational_trauma) + (1 | Study),
               data = subset(mod_data, Occupational_trauma %in% c("Yes", "No")), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Occupational_trauma)Yes"])


# Developmental age
model <- glmer(cbind(Partially_n, Sample_Size - Partially_n) ~ factor(Developmental_age) + (1 | Study),
               data = subset(mod_data, Developmental_age %in% c("Adult", "Youth")), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  # Adult
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Developmental_age)Youth"])

table(mod_data$Developmental_age[mod_data$Developmental_age %in% c("Adult", "Youth")])



# Country income
model <- glmer(cbind(Partially_n, Sample_Size - Partially_n) ~ factor(Location) + (1 | Study),
               data = subset(mod_data, !is.na(Location)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Location)ML"])
table(mod_data$Location[mod_data$Location %in% c("High", "ML")])



# US vs non-US
model <- glmer(cbind(Partially_n, Sample_Size - Partially_n) ~ factor(Location_US) + (1 | Study),
               data = subset(mod_data, !is.na(Location_US)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Location_US)US"])
table(unique(mod_data[!is.na(mod_data$Location_US), c("Study", "Location_US")])$Location_US)



# LGMM vs LCGA
model <- glmer(cbind(Partially_n, Sample_Size - Partially_n) ~ factor(Trajectory_analysis) + (1 | Study),
               data = subset(mod_data, !is.na(Trajectory_analysis)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Trajectory_analysis)LGMM"])
table(unique(mod_data[!is.na(mod_data$Trajectory_analysis), c("Study", "Trajectory_analysis")])$Trajectory_analysis)



# PTSD scale method
model <- glmer(cbind(Partially_n, Sample_Size - Partially_n) ~ factor(Scale_moderator) + (1 | Study),
               data = subset(mod_data, Scale_moderator %in% c("Interview", "Self")), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Scale_moderator)Self"])


# Trauma exposure type
model <- glmer(cbind(Partially_n, Sample_Size - Partially_n) ~ factor(Trauma_exposure) + (1 | Study),
               data = subset(mod_data, Trauma_exposure %in% c("Inter", "Non")), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])  # Interpersonal
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Trauma_exposure)Non"])


# Trauma type
model <- glmer(cbind(Partially_n, Sample_Size - Partially_n) ~ factor(Trauma_type) + (1 | Study),
               data = subset(mod_data, Trauma_type %in% c("Combat", "Natural", "Injury")), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Trauma_type)Injury"])
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Trauma_type)Natural"])

# Military population
model <- glmer(cbind(Partially_n, Sample_Size - Partially_n) ~ factor(Military) + (1 | Study),
               data = subset(mod_data, !is.na(Military)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Military)Yes"])


# Discrete
model <- glmer(cbind(Partially_n, Sample_Size - Partially_n) ~ factor(Discrete) + (1 | Study),
               data = subset(mod_data, !is.na(Discrete)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Discrete)Yes"])


# Health + First responders versus Other 
model <- glmer(cbind(Partially_n, Sample_Size - Partially_n) ~ factor(Health_First) + (1 | Study),
               data = subset(mod_data, !is.na(Health_First)), family = binomial)
summary(model)
plogis(fixef(model)["(Intercept)"])
plogis(fixef(model)["(Intercept)"] + fixef(model)["factor(Health_First)Yes"])







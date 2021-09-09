# SMITH Data Use Project NTpro BNP – Vorhofflimmern
# Ansprechpartner SMITH PheP	Dr. Frank Meineke, IMISE, Universität Leipzig
# Biometrie	Dr. Samira Zeynalova, IMISE, Universität Leipzig
# Kliniker 	Prof. Dr. med. Rolf Wachter, UKL
# Frage: Ist NT-proBNP ein Marker bei Vorhofflimmern?
# Hintergrund: laut mehreren epidemiologischen Studien scheint Nt-proBNP der stärkste Biomarker für das Auftreten von Vorhofflimmern zu sein
# Benötigte Variablen (Vereinfachte Version): Station/ Abteilung, Diagnose als ICD, NTproBNP (Laborparameter), Alter, Geschlecht
library("base")
library("Epi")
library("gmodels")
library("readxl")
library("stats")


xlsxFile <- dataFile

tmp <- readxl::read_excel(xlsxFile)

#Kollektiv:
Ntprobnp_df <- subset(tmp, Station == "kardiologie" & NTproBNP >= 0)

#Variable Vorhofflimmern (AF- Atrial Fibrillation) bilden

Ntprobnp_df$AF <-
  as.numeric(grepl("I48.0|I48.1|I48.2|I48.9", Ntprobnp_df$Diagnose))

table(Ntprobnp_df$AF, dnn = "gültige Fälle für AF")

# Analyse
# ROC AF-NTproBNP
ROC(
  test = Ntprobnp_df$NTproBNP,
  stat = Ntprobnp_df$AF,
  plot = "ROC",
  main = "NTproBNP(Gesamt)"
)
# Erläuterung zur Grafik: Sens- Sensitivity; Spec- Spezifität, PV+ - Anteil der Falsch negativen für AF unter allen Testnegativen,
# PV- Anteil der falsch positiven unter aller Testpositiven

# Verschiedene CUT-Points für NTproBNP bilden
# Cut=100
Ntprobnp_df$NtproBNP_cut100 <- NA

for (i in c(1:nrow(Ntprobnp_df))) {
  if (Ntprobnp_df$NTproBNP[i] >= 0 &
    Ntprobnp_df$NTproBNP[i] < 100)
    Ntprobnp_df$NtproBNP_cut100[i] <- 0
  else
    Ntprobnp_df$NtproBNP_cut100[i] <- 1

}
ROC(
  test = Ntprobnp_df$NtproBNP_cut100,
  stat = Ntprobnp_df$AF,
  plot = "ROC",
  main = "NtproBNP_cut100 BY AF"
)
# Sens- Sensitivity; Spec- Spezifität, PV+ - Anteil der Falsch negativen für AF unter allen Testnegativen
# PV- Anteil der falsch positiven unter aller Testpositiven
CrossTable(
  Ntprobnp_df$AF,
  Ntprobnp_df$NtproBNP_cut100,
  prop.c = TRUE,
  digits = 2,
  prop.chisq = FALSE,
  format = "SPSS"
)
table100 <- xtabs(~Ntprobnp_df$NtproBNP_cut100 + Ntprobnp_df$AF)
Test_100 <- rowSums(table100)
Krank_100 <- colSums(table100)

# Sensitivity
Sensitivity_100 <- table100[2, 2] / Krank_100[2]
Sensitivity_100

# Spezifität
specifity100 <- table100[1, 1] / Krank_100[1]
specifity100

# PPW-Der positive prädiktive Wert
PPW_100 <- table100[2, 2] / Test_100[2]
PPW_100

# NPW-Der negative prädiktive Wert
NPW_100 <- table100[1, 1] / Test_100[1]
NPW_100

# Cut=200
Ntprobnp_df$NtproBNP_cut200 <- NA

for (i in c(1:nrow(Ntprobnp_df))) {
  if (Ntprobnp_df$NTproBNP[i] >= 0 &
    Ntprobnp_df$NTproBNP[i] < 200)
    Ntprobnp_df$NtproBNP_cut200[i] <- 0
  else
    Ntprobnp_df$NtproBNP_cut200[i] <- 1
}
ROC(
  test = Ntprobnp_df$NtproBNP_cut200,
  stat = Ntprobnp_df$AF,
  plot = "ROC",
  main = "NtproBNP_cut200 BY AF"
)

# Sens- Sensitivity; Spec- Spezifität, PV+ - Anteil der Falsch negativen für AF unter allen Testnegativen,
# PV- Anteil der falsch positiven unter aller Testpositiven
CrossTable(
  Ntprobnp_df$AF,
  Ntprobnp_df$NtproBNP_cut200,
  prop.c = TRUE,
  digits = 2,
  prop.chisq = FALSE,
  format = "SPSS"
)
table200 <- xtabs(~Ntprobnp_df$NtproBNP_cut200 + Ntprobnp_df$AF)
Test_200 <- rowSums(table200)
Krank_200 <- colSums(table200)

# Sensitivität
Sensitivity_200 <- table200[2, 2] / Krank_200[2]
Sensitivity_200

# Spezifität
specifity200 <- table200[1, 1] / Krank_200[1]
specifity200

# PPW-Der positive prädiktive Wert
PPW_200 <- table200[2, 2] / Test_200[2]
PPW_200

# NPW-Der negative prädiktive Wert
NPW_200 <- table200[1, 1] / Test_200[1]
NPW_200

# Cut=300
Ntprobnp_df$NtproBNP_cut300 <- NA

for (i in c(1:nrow(Ntprobnp_df))) {
  if (Ntprobnp_df$NTproBNP[i] >= 0 &
    Ntprobnp_df$NTproBNP[i] < 300)
    Ntprobnp_df$NtproBNP_cut300[i] <- 0
  else
    Ntprobnp_df$NtproBNP_cut300[i] <- 1
}

Epi::ROC(
  test = Ntprobnp_df$NtproBNP_cut300,
  stat = Ntprobnp_df$AF,
  plot = "ROC",
  main = "NtproBNP_cut300 BY AF"
)
# Sens- Sensitivity; Spec- Spezifität, PV+ - Anteil der Falsch negativen für AF unter allen Testnegativen,
# PV- Anteil der falsch positiven unter aller Testpositiven
gmodels::CrossTable(
  Ntprobnp_df$AF,
  Ntprobnp_df$NtproBNP_cut300,
  prop.c = TRUE,
  digits = 2,
  prop.chisq = FALSE,
  format = "SPSS"
)

table300 <- xtabs(~Ntprobnp_df$NtproBNP_cut300 + Ntprobnp_df$AF)
Test_300 <- rowSums(table300)
Krank_300 <- colSums(table300)

# Sensitivität
Sensitivity_300 <- table300[2, 2] / Krank_300[2]
Sensitivity_300

# Spezifität
specifity300 <- table300[1, 1] / Krank_300[1]
specifity300

# PPW-Der positive prädiktive Wert
PPW_300 <- table300[2, 2] / Test_300[2]
PPW_300

# NPW-Der negative prädiktive Wert
NPW_300 <- table300[1, 1] / Test_300[1]
NPW_300

# Cut=400
Ntprobnp_df$NtproBNP_cut400 <- NA

for (i in c(1:nrow(Ntprobnp_df))) {
  if (Ntprobnp_df$NTproBNP[i] >= 0 &
    Ntprobnp_df$NTproBNP[i] < 400)
    Ntprobnp_df$NtproBNP_cut400[i] <- 0
  else
    Ntprobnp_df$NtproBNP_cut400[i] <- 1

}
Epi::ROC(
  test = Ntprobnp_df$NtproBNP_cut400,
  stat = Ntprobnp_df$AF,
  plot = "ROC",
  main = "NtproBNP_cut400 BY AF"
)
# Sens- Sensitivity; Spec- Spezifität, PV+ - Anteil der Falsch negativen für AF unter allen Testnegativen,
# PV- Anteil der falsch positiven unter aller Testpositiven
gmodels::CrossTable(
  Ntprobnp_df$AF,
  Ntprobnp_df$NtproBNP_cut400,
  prop.c = TRUE,
  digits = 2,
  prop.chisq = FALSE,
  format = "SPSS"
)
table400 <- xtabs(~Ntprobnp_df$NtproBNP_cut400 + Ntprobnp_df$AF)
Test_400 <- rowSums(table400)
Krank_400 <- colSums(table400)

# Sensitivität
Sensitivity_400 <- table400[2, 2] / Krank_400[2]
Sensitivity_400

# Spezifität
specifity400 <- table400[1, 1] / Krank_400[1]
specifity400

# PPW-Der positive prädiktive Wert
PPW_400 <- table400[2, 2] / Test_400[2]
PPW_400

# NPW-Der negative prädiktive Wert
NPW_400 <- table400[1, 1] / Test_400[1]
NPW_400

# Cut=500
Ntprobnp_df$NtproBNP_cut500 <- NA
for (i in c(1:nrow(Ntprobnp_df))) {
  if (Ntprobnp_df$NTproBNP[i] >= 0 &
    Ntprobnp_df$NTproBNP[i] < 500)
    Ntprobnp_df$NtproBNP_cut500[i] <- 0
  else
    Ntprobnp_df$NtproBNP_cut500[i] <- 1

}
Epi::ROC(
  test = Ntprobnp_df$NtproBNP_cut500,
  stat = Ntprobnp_df$AF,
  plot = "ROC",
  main = "NtproBNP_cut500 BY AF"
)
gmodels::CrossTable(
  Ntprobnp_df$AF,
  Ntprobnp_df$NtproBNP_cut500,
  prop.c = TRUE,
  digits = 2,
  prop.chisq = FALSE,
  format = "SPSS"
)
table500 <- xtabs(~Ntprobnp_df$NtproBNP_cut500 + Ntprobnp_df$AF)
Test_500 <- rowSums(table500)
Krank_500 <- colSums(table500)

# Sensitivität
Sensitivity_500 <- table500[2, 2] / Krank_500[2]
Sensitivity_500

# Spezifität
specifity500 <- table500[1, 1] / Krank_500[1]
specifity500

# PPW-Der positive pr?diktive Wert
PPW_500 <- table500[2, 2] / Test_500[2]
PPW_500

# NPW-Der negative pr?diktive Wert
NPW_500 <- table500[1, 1] / Test_500[1]
NPW_500

# Multivariate Analyse, AF in Abh?ngigkeit von NTproBNP, adjustiert mit Alter und Geschlecht
logit <- stats::glm(AF ~ NTproBNP + Alter + Geschlecht,
                    family = binomial,
                    data = Ntprobnp_df)
print(summary(logit))

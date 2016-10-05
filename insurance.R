##################################################
"Khaled Ben Abdallah - Assurances Belges"
##################################################


##################################################
"2.1 Import des coordonnées factorielles 
et représentation du premier plan factoriel"
##################################################

votre_dossier = "YOUR_FOLDER"
setwd(votre_dossier)
cooord_assur_bel = read.csv("ACM_coordonnees.csv", header = TRUE)

#Supprimer colonnes vides
cooord_assur_bel <- Filter(function(x)!all(is.na(x)), cooord_assur_bel)

plot(cooord_assur_bel[,1:2], habillage=1)
title(main = "Assurés sur le premier plan factoriel")

##################################################
"2.2 Modèle logistique"
##################################################

install.packages("sas7bdat")
library(sas7bdat)
classification_sinistre = read.sas7bdat("../classification_sinistre.sas7bdat")

#Ajouter la colonne à prédire 
cooord_assur_bel <- cbind(cooord_assur_bel, SINISTRALITE=classification_sinistre[,2])

#Verifier type var à expliquer : catégoriel
is.factor(cooord_assur_bel$SINISTRALITE)

#Construire le modèle 
modele <- glm(SINISTRALITE ~.,family=binomial(link='logit'),data=cooord_assur_bel)

#Résultats 
summary(modele)

#la valeur prédite 
SIN_predit <- predict(modele, type = 'resinstall.packages("ROCR")ponse')

##################################################
"2.3 Pourcentage de mal classés et courbe ROC"
##################################################

#Matrice de confusion 
prop.table(table(cooord_assur_bel$SINISTRALITE, SIN_predit > 0.5))*100

#Courbe ROC 

library(ROCR)
ROCRpred <- prediction(SIN_predit, cooord_assur_bel$SINISTRALITE)
ROCRperf <- performance(ROCRpred, 'tpr','fpr')
plot(ROCRperf, colorize = TRUE)

#AUC
AUC.tmp <- performance(ROCRpred ,"auc")









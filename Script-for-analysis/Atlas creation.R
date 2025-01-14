# This script is part of the manuscript "Establishment of an optimized and automated workflow for whole brain probing of neuronal activity. Cabrera et al."
# This script creates different Atlases for analysis

#### LOAD LIBRARIES ###########################################################################################################
library("readxl")
library("dplyr")
library("svDialogs")
library("tidyr")

#### LOCATE AND IMPORT AVAILABLE ATLASES  ###########################################################################

#Define excel file location containing organisation of the three Allen atlas resolutions (i.e. "Definition_Allen_atlas_resolutions.xlsx") 
full_list_of_brain_structures_allen_atlas <- read_excel("C:/.../Definition_Allen_atlas_resolutions.xlsx",skip = 1)

#Import "Major Division", "Summary Structures" and "FullList" atlases
full_list_of_brain_structures_allen_atlas["Major Division"][is.na(full_list_of_brain_structures_allen_atlas["Major Division"])] <- "N"
Atlas_extract=full_list_of_brain_structures_allen_atlas[full_list_of_brain_structures_allen_atlas$`Major Division` == 'Y',]
Majordivisions = Atlas_extract$`full structure name` 
Atlas_Majordivisions <- Alldata %>% filter(Name %in% Majordivisions)

full_list_of_brain_structures_allen_atlas['"Summary Structure" Level for Analyses'][is.na(full_list_of_brain_structures_allen_atlas['"Summary Structure" Level for Analyses'])] <- "N"
Atlas_extract=full_list_of_brain_structures_allen_atlas[full_list_of_brain_structures_allen_atlas$'"Summary Structure" Level for Analyses' == 'Y',]
SummaryStructures = Atlas_extract$`full structure name`
Atlas_SummaryStructures <- Alldata %>% filter(Name %in% SummaryStructures)

full_list_of_brain_structures_allen_atlas["Structure independently delineated (not merged to form parents)"][is.na(full_list_of_brain_structures_allen_atlas["Structure independently delineated (not merged to form parents)"])] <- "N"
test=full_list_of_brain_structures_allen_atlas[full_list_of_brain_structures_allen_atlas$`Structure independently delineated (not merged to form parents)` == 'Y',]
Fulllist = test$`full structure name`
Atlas_Fulllist <- Alldata %>% filter(Name %in% Fulllist) 

##################################################
#### ATLAS CREATION  #############################
##################################################

#ATLASES WITH SUB-REGIONS BASED ON SUMMARY STRUCTURES ATLAS 

#Cerebral Cortex
Atlas_extract = full_list_of_brain_structures_allen_atlas[grepl("/688/", full_list_of_brain_structures_allen_atlas$structure_id_path) & full_list_of_brain_structures_allen_atlas$`"Summary Structure" Level for Analyses` == 'Y', ]
SummaryStructuresCerebralCortex = Atlas_extract$`full structure name`
Atlas_SummaryStructures_CerebralCortex <- Alldata %>% filter(Name %in% SummaryStructuresCerebralCortex)

#Isocortex
Atlas_extract = full_list_of_brain_structures_allen_atlas[grepl("/315/", full_list_of_brain_structures_allen_atlas$structure_id_path) & full_list_of_brain_structures_allen_atlas$`"Summary Structure" Level for Analyses` == 'Y', ]
SummaryStructuresIsocortex = Atlas_extract$`full structure name`
Atlas_SummaryStructures_Isocortex <- Alldata %>% filter(Name %in% SummaryStructuresIsocortex)

#Thalamus
Atlas_extract = full_list_of_brain_structures_allen_atlas[grepl("/549/", full_list_of_brain_structures_allen_atlas$structure_id_path) & full_list_of_brain_structures_allen_atlas$`"Summary Structure" Level for Analyses` == 'Y', ]
SummaryStructuresThalamus = Atlas_extract$`full structure name`
Atlas_SummaryStructures_Thalamus <- Alldata %>% filter(Name %in% SummaryStructuresThalamus)

#Hypothalamus
Atlas_extract = full_list_of_brain_structures_allen_atlas[grepl("/1097/", full_list_of_brain_structures_allen_atlas$structure_id_path) & full_list_of_brain_structures_allen_atlas$`"Summary Structure" Level for Analyses` == 'Y', ]
SummaryStructuresHypothalamus = Atlas_extract$`full structure name`
Atlas_SummaryStructures_Hypothalamus <- Alldata %>% filter(Name %in% SummaryStructuresHypothalamus)

#OLF
Atlas_extract = full_list_of_brain_structures_allen_atlas[grepl("/698/", full_list_of_brain_structures_allen_atlas$structure_id_path) & full_list_of_brain_structures_allen_atlas$`"Summary Structure" Level for Analyses` == 'Y', ]
SummaryStructuresOLF = Atlas_extract$`full structure name`
Atlas_SummaryStructures_OLF <- Alldata %>% filter(Name %in% SummaryStructuresOLF)

#Hippocampal formation
Atlas_extract = full_list_of_brain_structures_allen_atlas[grepl("/1089/", full_list_of_brain_structures_allen_atlas$structure_id_path) & full_list_of_brain_structures_allen_atlas$`"Summary Structure" Level for Analyses` == 'Y', ]
SummaryStructuresHPF = Atlas_extract$`full structure name`
Atlas_SummaryStructures_HPF <- Alldata %>% filter(Name %in% SummaryStructuresHPF)

#Cortical subplate
Atlas_extract = full_list_of_brain_structures_allen_atlas[grepl("/703/", full_list_of_brain_structures_allen_atlas$structure_id_path) & full_list_of_brain_structures_allen_atlas$`"Summary Structure" Level for Analyses` == 'Y', ]
SummaryStructuresCTXsp = Atlas_extract$`full structure name`
Atlas_SummaryStructures_CTXsp <- Alldata %>% filter(Name %in% SummaryStructuresCTXsp)

#Cerebral nuclei
Atlas_extract = full_list_of_brain_structures_allen_atlas[grepl("/623/", full_list_of_brain_structures_allen_atlas$structure_id_path) & full_list_of_brain_structures_allen_atlas$`"Summary Structure" Level for Analyses` == 'Y', ]
SummaryStructuresCerebralNuclei = Atlas_extract$`full structure name`
Atlas_SummaryStructures_CerebralNuclei <- Alldata %>% filter(Name %in% SummaryStructuresCerebralNuclei)

#Cerebral nuclei
Atlas_extract = full_list_of_brain_structures_allen_atlas[grepl("/1009/", full_list_of_brain_structures_allen_atlas$structure_id_path) & full_list_of_brain_structures_allen_atlas$`"Summary Structure" Level for Analyses` == 'Y', ]
SummaryStructuresFiberTracts = Atlas_extract$`full structure name`
Atlas_SummaryStructures_FiberTracts <- Alldata %>% filter(Name %in% SummaryStructuresFiberTracts)

#ADD TAILOR MADE ATLASES HERE
#Refer to troubleshootings for defining new atlases.

AtlasSubstructures <-subset(Alldata, Alldata$Name=="Mammillary body" | Alldata$Name=="Lateral hypothalamic area" | Alldata$Name=="Dentate gyrus" | Alldata$Name=="Field CA1" | Alldata$Name=="Hippocampal region" | Alldata$Name=="Thalamus" | Alldata$Name=="Hypothalamus")


#LIST ATLASES TO BE SHOWNED IN INTERACTIVE WINDOW (R SCRIPT)
Qatlas <- c("Atlas_Majordivisions", "Atlas_SummaryStructures", "Atlas_Fulllist", 
            "Atlas_SummaryStructures_CerebralCortex", "Atlas_SummaryStructures_Isocortex", "Atlas_SummaryStructures_Thalamus", 
            "Atlas_SummaryStructures_Hypothalamus", "Atlas_SummaryStructures_OLF","Atlas_SummaryStructures_HPF", "Atlas_SummaryStructures_CTXsp", 
            "Atlas_SummaryStructures_CerebralNuclei", "Atlas_SummaryStructures_FiberTracts", "AtlasSubstructures")
res <- dlg_list(Qatlas, multiple = F, title = " Which Atlas to use?")$res
NameAtlas <- res
Alldata2 <- get(res) 
Alldata2 <- Alldata2 %>% drop_na()   #values corresponding to selected atlas will appear in a new dataframe named "Alldata2"

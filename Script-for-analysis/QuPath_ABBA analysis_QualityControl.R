# This script is part of the manuscript "Establishment of an optimized and automated workflow for whole brain probing of neuronal activity. Cabrera et al."
# This script is for quality control of QuPath/ABBA registration and cell detection
# It creates a figures that allows identifying missing or aberrant sections for subsequent refinement

#### LOAD LIBRARIES ###########################################################################################################
library("factoextra")
library("ggplot2")
library("gridExtra")
library("e1071")
library("psych")
library("viridis")
library("data.table")
library("dplyr")
library("ggpubr")

#### LOCATING AND LOADING DATA ################################################################################################
path <-"C:/folder1/folder2/.../folder csv files/" #indicate folder location
List<-dir(path, pattern = "*.csv") #make a list of all csv files contained within the folder and run the loop below
for (file in 1:as.numeric(length(List))){
inputfile <- List[file]
nop <- as.numeric(gsub("\\D+", "", inputfile))
data <- read.csv(file=paste0(path,inputfile), header=TRUE, sep=",",fileEncoding="UTF-8-BOM")

#### FORMATING DATAFRAME ######################################################################################################
#select necessary columns
keeps <- c("Image", "Name", "Parent", "Num.Detections", "Num.artéfact", "Num.cfos", "Area.µm.2") 
data1=data[keeps]

#format dataframe
data1$Image <- as.factor(data1$Image)
data1$Name <- as.factor(data1$Name)
data1$Parent <- as.factor(data1$Parent)
data1$Num.Detections <- as.numeric(data1$Num.Detections)
data1$Num.artéfact <- as.numeric(data1$Num.artéfact)
data1$Num.cfos <- as.numeric(data1$Num.cfos)
data1$Area.µm.2 <- as.numeric(data1$Area.µm.2)
data1 <- na.omit(data1)
data1 <- subset(data1, Num.Detections !=0)

#create a new column containing cfos cell density
data1$density <- data1$Num.cfos/data1$Area.µm.2*1000000
data1$density <- as.numeric(data1$density)

#create a new column containing slide number (extracted from Image name)
data1$Slices <- substring(data1$Image, regexpr("*N", data1$Image)+2)

#######################################################################################################################
#### SELECT ATLAS OR REGIONS OF INTEREST TO BE ANALALYZED #############################################################
#######################################################################################################################
#Define gray matter regions
AtlasGM <- subset(data1, data1$Parent== "Cerebral cortex" | data1$Parent== "Cerebral nuclei" | data1$Parent== "Mibrain") #to keep relevant regions defining "gray matter" (see panels A and B) 
#Define white matter (WM) regions
AtlasWM <- subset(data1, data1$Name== "corpus callosum, body" | data1$Name== "corpus callosum, anterior forceps" | data1$Name== "anterior commissure, olfactory limb" | data1$Name== "internal capsule") #to keep relevant regions defining "white matter" tracts (see panel D) 
#Define ventricular system (VS) regions
AtlasVS <- subset(data1, data1$Parent== "ventricular systems") #to keep only relevant rows for ventricular system (See panel E)
#Define simplified Atlas regions
SimplAtlas <- subset(data1, data1$Name== "Thalamus" | data1$Name== "Isocortex" | data1$Name== "Olfactory area"
          | data1$Name== "Hippocampal formation" | data1$Name== "Cortical subplate"
          | data1$Name== "Striatum" | data1$Name== "Pallidum" | data1$Name== "Thalamus" 
          | data1$Name== "Hypothalamus" | data1$Name== "Midbrain" | data1$Name== "Cerebellum"
          | data1$Name== "Hindbrain") #to keep relevant regions defining the "simplified atlas" (See panel F)

#######################################################################################################################
#### QUALITY CONTROL ##################################################################################################
#######################################################################################################################
# THE FOLLOWING 3 GRAPHS ARE FOR DETECTING MISSING SECTIONS, BROKEN SECTIONS OR MALFUNCTIONING CLASSIFIER
#create a plot with sum cfos per section (QC Goal: to detect broken or missing sections) 
Sumd <- aggregate(Num.cfos~Slices, AtlasGM, sum)   
p1 <- ggplot(Sumd, aes(x = as.double(Slices), y=Num.cfos, fill=as.double(Slices)))+
  geom_col(position = "dodge")+ 
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))+
  scale_fill_viridis(5)+
  ylim(0, 45000)+
  ggtitle("Num c-Fos+ cells/section")
#create a plot with density cfos per section (QC Goal: to detect broken or missing sections) 
Meandensity <- aggregate(density~Slices, AtlasGM, mean) 
p2 <- ggplot(Meandensity, aes(x = as.double(Slices), y=density, fill=as.double(Slices)))+
  geom_col(position = "dodge")+ 
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))+
  ylim(0, 1550)+
  ggtitle("Density c-Fos+ cells/section")
#create a plot representing % of artefact per section among total number of detected cells (QC Goal: to detect Classifier malfunction)
Sumtot <- aggregate(Num.Detections~Slices, AtlasGM, sum)
Sumartefact <- aggregate(Num.artéfact~Slices, AtlasGM, sum)    
Sumartefact$percentage <-Sumartefact$Num.artéfact/Sumtot$Num.Detections*100
p3 <- ggplot(Sumartefact, aes(x= as.double(Slices), y=percentage, fill=as.double(Slices)))+
  geom_col(position = "dodge")+
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))+
  scale_fill_viridis(5)+
  ggtitle("% artifact/section")

#####################################################################################################################
# THE FOLLOWING 2 GRAPHS ALLOW DETECTING SUBOPTIMAL ATLAS REGISTRATION (values >5% indicate sections requiring attention for registration refinement)  

# to calculate % of cfos cells within ventricles
SumVS <- aggregate(Num.cfos~Slices, AtlasVS, sum)
SumVS <- merge(Sumd, SumVS, by = "Slices")
SumVS$percentage <-SumVS$Num.cfos.y/SumVS$Num.cfos.x*100  
p4 <- ggplot(SumVS, aes(x= as.double(Slices), y=percentage, fill=as.double(Slices)))+
  geom_col(position = "dodge")+
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))+
  geom_hline(yintercept=5, linetype="dotdash", color = "red", size = 1)+
  scale_fill_viridis(5)+
  ggtitle("% c-Fos+ cells in VS (values >5% require attention)")
# to calculate % of cfos cells within fiber tracts 
Sumtract <- aggregate(Num.cfos~Slices, AtlasWM, sum)
Sumtract$percentage <-Sumtract$Num.cfos/Sumd$Num.cfos*100  
p5 <- ggplot(Sumtract, aes(x= as.double(Slices), y=percentage, fill=as.double(Slices)))+
  geom_col(position = "dodge")+
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))+
  geom_hline(yintercept=5, linetype="dotdash", color = "red", size = 1)+
  scale_fill_viridis(5)+
  ggtitle("% c-Fos+ cells in WM (values >5% require attention)")

#####################################################################################################################
# THE FOLLOWING GRAPH SHOWS CFOS DENSITY IN REGION OF SIMPLIFIED ATLAS  
# to calculate cell density per region of interest and represent results in a plot
Meandensity <- aggregate(density~Name, SimplAtlas, mean)#create a dataframe with sum per section (here only for Atlas1 regions)
p6 <- ggplot(Meandensity, aes(x = Name, y=density, fill=Name))+
  geom_col(position = "dodge")+ 
  theme(axis.text.x = element_blank())+
  ylim(0, 1550)+
  ggtitle("density cfos in main brain regions (cells/mm2)")

#####################################################################################################################
# REPRESENT QC RESULTS 

# show all graphs side by side for optimal QC and indicate animal number
plottosave <- ggarrange(p1, p2, p3, p5,p4, p6, nrow = 2, ncol = 3, align = "hv", labels = c("a", "b", "c", "d", "e", "f"))
titre <- paste("Animal ", nop)
plottosave <- annotate_figure(plottosave, top = text_grob(paste("Animal ", nop), face = "bold", size = 15))
plottosave 
# save all plot sin appropriate folder
setwd("/folder1/.../quality control saving folder/") # specify folder to save png files all png files
ggsave(paste(nop, ".png"), plot = last_plot(), width = 20, height = 12)
}


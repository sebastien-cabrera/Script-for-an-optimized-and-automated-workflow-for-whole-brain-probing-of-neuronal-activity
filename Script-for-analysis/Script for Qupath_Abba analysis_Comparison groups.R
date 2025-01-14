# This script is part of the manuscript "Establishment of an optimized and automated workflow for whole brain probing of neuronal activity. Cabrera et al."
# This script is for Qupath_Abba quantifications comparisons between experimental groups. 
# Different atlases (defined in "R Script Atlas creation.R") allow exploring cell quantification at different resolutions, in the forms of bargraphs.
# It creates csv files for statistical comparisons between experimental groups, as well as 3d representations of cell density and proportion between groups (Using BrainRender, refer to "3d-rendering script")

#### LOAD LIBRARIES ###########################################################################################################
library("ggplot2")
library("factoextra")
library("gridExtra")
library("e1071")
library("psych")
library("viridis")
library("data.table")
library("plyr")
library("dplyr")
library("broom")
library("tidystats")
library("ggpubr")
library("rempsyc")
library(rstatix)


#### LOCATING AND LOADING DATA ################################################################################################
path_for_importation <-"C:/Users/Eq.Raineteau_2023/Desktop/Sebastien_C/Cfos_project_seb/Csv files/Dossier NewMeanIJ csv/Wakefulness_paradoxical/" # Indicate csv files location
path_for_exportation <- "C:/folder1/folder2/.../density_cfos csv folder/"  
path_for_stat_test <- "C:/folder1/folder2/.../significiative structures csv folder/"               #Indicate location of folder to export result


Alldata <- data.frame()  # Create dataframe for importing individual animals csv files
List_1st_group<- dir(path_for_importation, pattern = "*_WF.csv")            #List csv files of experimental group 1 (here group "WF", i.e. "wakefulness"). 
for (file in 1:as.numeric(length(List_1st_group))){         #Loop to import selected columns ("Image", "Name"...) corresponding csv files in dataframe. 
  inputfile <- List_1st_group[file]                                               
  dataList_1st_group <- read.csv(file=paste0(path_for_importation,inputfile), header=TRUE, sep=",",fileEncoding="UTF-8-BOM")[ ,c("Image", "Name", "Parent", "Num.cfos","Num.artefact", "Area.µm.2")]
  dataList_1st_group$Condition <- "Wakefulness"             #A column "condition" is created (here "Wakefulness")
  Alldata <- rbind(Alldata, dataList_1st_group)
}
List_2nd_group<-dir(path_for_importation, pattern = "*_PS.csv")             #List csv files of experimental group 2 (here group "SP", i.e. "Paradoxical Sleep")
for (file in 1:as.numeric(length(List_2nd_group))){
  inputfile <- List_2nd_group[file]
  dataList_2nd_group <- read.csv(file=paste0(path_for_importation,inputfile), header=TRUE, sep=",",fileEncoding="UTF-8-BOM")[ ,c("Image", "Name", "Parent", "Num.cfos","Num.artefact", "Area.µm.2")]
  dataList_2nd_group$Condition <- "Paradoxical Sleep"
  Alldata <- rbind(Alldata, dataList_2nd_group)
}

#### FORMATING DATAFRAME ######################################################################################################
#Format dataframe
Alldata$Image <- as.factor(Alldata$Image)
Alldata$Name <- as.character(Alldata$Name)
Alldata$Parent <- as.factor(Alldata$Parent)
Alldata$Num.cfos <- as.numeric(Alldata$Num.cfos)
Alldata$Num.artefact <- as.numeric(Alldata$Num.artefact)
Alldata$Area.µm.2 <- as.numeric(Alldata$Area.µm.2)

#Create a new column containing animal ID (Here extracted from "Image")        
Alldata$AnimalID <- substr(Alldata$Image, 1, 7)

#Create a new column containing section number (Here extracted from "Image")
Alldata$Section <- substring(Alldata$Image, regexpr("*N_", Alldata$Image)+2)
Alldata$Section <- as.numeric(Alldata$Section)

#Create a new column with density_cfos (detected cells/mm2)
Alldata$density_cfos <- Alldata$Num.cfos/Alldata$Area.µm.2*1000000
Alldata$density_cfos <- as.numeric(Alldata$density_cfos)

#To generated histogram of "cell density_cfos per section per animal"
Meandensity_section_animal <- aggregate(density_cfos~(AnimalID + Section), Alldata, mean)              #Calculate cell density_cfos/section/animal
ggplot(Meandensity_section_animal, aes(x = Section, y=density_cfos, fill=AnimalID))+                   #Create corresponding bargraph (discrepancies of section number/animal can be corrected, see line 67-69)
  geom_col(position = "dodge")+
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))

# #Eliminate sections (if required)
# Alldata <- subset(Alldata, Alldata$Section!= " ")  #indicate number of section to be removed   
# Alldata <- subset(Alldata, Alldata$Section!= " ")
# Alldata <- subset(Alldata, Alldata$Name!="PathAnnotationObject")

#Separate experimental groups to calculate proportion
Analysis_Condition1<- subset(Alldata, Alldata$Condition=="Wakefulness")
Analysis_Condition2<- subset(Alldata, Alldata$Condition=="Paradoxical Sleep")

#Add column proportion for 1st experimental group
Analysis_Condition1=Analysis_Condition1 %>%
  group_by(AnimalID,Section) %>%
  mutate(max = across(Num.cfos),max(Num.cfos)) %>%
  ungroup()  %>%
  dplyr::rowwise() %>%
  mutate(Proportion=ifelse(
    endsWith(Name, "root"),Num.cfos/Num.cfos,     #Calculate proportion for each section based on root value
    Num.cfos/`max(Num.cfos)`))%>%
  ungroup()
colnames(Analysis_Condition1)
Analysis_Condition1=subset(Analysis_Condition1, select=c("Image","Name", "Parent","Num.artefact","Num.cfos","Area.µm.2","Condition" ,"AnimalID","Section","density_cfos","Proportion"))
Analysis_Condition1=as.data.frame(Analysis_Condition1)

#Add column proportion for 2nd experimental group
Analysis_Condition2=Analysis_Condition2 %>%
  group_by(AnimalID,Section) %>%
  mutate(max = across(Num.cfos),max(Num.cfos)) %>%
  ungroup()  %>%
  dplyr::rowwise() %>%
  mutate(Proportion=ifelse(
    endsWith(Name, "root"),Num.cfos/Num.cfos,
    Num.cfos/`max(Num.cfos)`))%>%
  ungroup()
colnames(Analysis_Condition2)
Analysis_Condition2=subset(Analysis_Condition2, select=c("Image","Name", "Parent","Num.artefact","Num.cfos","Area.µm.2","Condition" ,"AnimalID","Section","density_cfos","Proportion"))
Analysis_Condition2=as.data.frame(Analysis_Condition2)

#Merge the two dataframes (calculation of proportion allow comparing groups with important differences in level activity)
Alldata <- full_join(Analysis_Condition1,Analysis_Condition2) 

###########################################################################################################
####### MANUALLY SELECT ATLAS OF INTEREST #################################################################
###########################################################################################################

source(file = "C:/folder1/.../Atlas creation.R")   # Open interface with listing of available atlases.
Selected_Atlas_Name <- res 
#Select "Major Division" for a gross overview of brain regions
#Select "Summary Structures" to include subregions (e.g. cortical areas)
#Select "FullList" to select highest level of hierarchy (e.g. cortical layers)
#Select "Summary Structures_Isocortex" to restrict analysis only to this structure
#...

#Selecting an atlas creates a new dataframe "Alldata2" for subsequent analysis steps
############################################################################################
####### MAKE BAR GRAPHS WITH SEM  ##########################################################
############################################################################################

sem<-function(x,digits= 3,na.rm=FALSE)      #Formula for SEM calculation and application
{
  if(na.rm==TRUE) {x<-x[!is.na(x)]}
  return(round(sd(x)/sqrt(length(x)),digits))
}
data_sem <- function(data, varname, groupnames){
  require(plyr)
  summary_func <- function(x, col){
    c(mean = mean(x[[col]], na.rm=TRUE),
      sem = sem(x[[col]], na.rm=TRUE))
  }
  data_sum<-ddply(data, groupnames, .fun=summary_func,
                  varname)
  data_sum <- plyr::rename(data_sum, c("mean" = varname))
  return(data_sum)
}

#PRODUCES BARGRAPHS TO COMPARE c-FOS CELL NUMBER PER GROUPS USING SELECTED ATLAS   ##############################################
ggplot(Alldata2, aes(x = as.double(Section), y=Num.cfos, fill=Condition))+
  geom_col(position = "dodge", show.legend = T)+ 
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))

#PRODUCES BARGRAPHS TO COMPARE c-FOS CELL DENSITY PER GROUPS USING SELECTED ATLAS  ##############################################
ggplot(Alldata2, aes(x = as.double(Section), y=density_cfos, fill=AnimalID))+
  geom_col(position = "dodge", show.legend = T)+ 
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))

#PRODUCES BARGRAPHS TO COMPARE PROPORTION BETWEEN EXPERIMENTAL GROUPS (DISTRIBUTION OF c-FOS CELL PER GROUPS USING SELECTED ATLAS) #########################
ggplot(Alldata2, aes(x = as.double(Section), y=Proportion, fill=Condition))+
  geom_col(position = "dodge", show.legend = T)+ 
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))

################################################################################
###   INTRA AND INTERGROUP ANALYSES AND GENERATION OF CSV FOR BRAINRENDER    ###
################################################################################

#Production of csv file for representation of raw number of c-Fos positive cells using BrainRender

dfAnimal_raw <- aggregate(Num.cfos ~ (Condition+ AnimalID+ Name), data = Alldata2, mean) #Data represented per animal
dfAnimal_raw$denscfos <- dfAnimal_raw$Num.cfos       #representation of mean value per structures/conditions/animal
# Raw data : don't use it to brainrender
write.csv(dfAnimal_raw, paste0(path_for_exportation,"MeanROI_condition1_condition2_raw_", Selected_Atlas_Name, ".csv"), row.names = FALSE)


df_rawdata_per_animal <- data_sem(dfAnimal_raw, varname="Num.cfos",    #Data represented per group
                groupnames=c("Condition", "Name"))
ggplot(df_rawdata_per_animal, aes(x = Name, y=Num.cfos, fill=Condition))+  #Create bargraph comparing proportion between experimental groups
  geom_bar(stat="identity", color="black", 
           position=position_dodge())+ 
  geom_errorbar(aes(ymin=Num.cfos-sem, ymax=Num.cfos+sem), width=.2,
                position=position_dodge(.9)) +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1), panel.background = element_blank())+
  scale_fill_manual(values=c("black", "grey", "white"))  #Colors can be changed to match Allen Atlas pallet 

df_rawdata_per_animal$denscfos <- df_rawdata_per_animal$Num.cfos 
write.csv(df_rawdata_per_animal, paste0(path_for_exportation,"results_condition1_condition2_raw_", Selected_Atlas_Name, ".csv"), row.names = FALSE) 



#Production of csv file for representation of cell density_cfos/experimental group using BrainRender (i.e Qualitative representation)

dfAnimal_density <- aggregate(density_cfos ~ (Condition+ AnimalID+ Name), data = Alldata2, mean) #Data represented by animal
dfAnimal_density$denscfos <- dfAnimal_density$density_cfos            #representation of mean value per structures/conditions/animal
write.csv(dfAnimal_density, paste0(path_for_exportation, "MeanROI_condition1_condition2_density_", Selected_Atlas_Name, ".csv"), row.names = FALSE)


df_density_cfos <- data_sem(dfAnimal_density, varname="density_cfos",    #Data represented by group
                groupnames=c("Condition", "Name"))
ggplot(df_density_cfos, aes(x = Name, y=density_cfos, fill=Condition))+  #Create bargraph comparing proportion between experimental groups
  geom_bar(stat="identity", color="black", 
           position=position_dodge())+ 
  geom_errorbar(aes(ymin=density_cfos-sem, ymax=density_cfos+sem), width=.2,
                position=position_dodge(.9)) +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1), panel.background = element_blank())+
  scale_fill_manual(values=c("black","grey","white"))  #Colors can be changed to match Allen Atlas pallet 

df_density_cfos$denscfos <- df_density_cfos$density_cfos 
write.csv(df_density_cfos, paste0(path_for_exportation, "results_condition1_condition2_raw_", Selected_Atlas_Name, ".csv"), row.names = FALSE) 

#Production of csv file for comparison of cell proportion/experimental group using BrainRender (i.e Quantitative representation)

dfAnimal_proportion <- aggregate(Proportion ~ (Condition+ AnimalID+ Name), data = Alldata2, mean) #Data represented by animal
dfAnimal_proportion$denscfos <- dfAnimal_proportion$Proportion         #representation of mean value per structures/conditions/animal
write.csv(dfAnimal_proportion, paste0(path_for_exportation, "MeanROI_condition1_condition2_proportion_", Selected_Atlas_Name, ".csv"), row.names = FALSE)


df_Proportion <- data_sem(dfAnimal_proportion, varname="Proportion",    #Data represented by group
                groupnames=c("Condition", "Name"))
ggplot(df_Proportion, aes(x = Name, y=Proportion, fill=Condition))+  #Create bargraph comparing proportion between experimental groups
  geom_bar(stat="identity", color="black", 
           position=position_dodge())+ 
  geom_errorbar(aes(ymin=Proportion-sem, ymax=Proportion+sem), width=.2,
                position=position_dodge(.9)) +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1), panel.background = element_blank())+
  scale_fill_manual(values=c("black","grey","white"))  #Colors can be changed to match Allen Atlas pallet 

df_Proportion$densProportion_cfos <- df_density_cfos$Proportion 
write.csv(df_Proportion, paste0(path_for_exportation, "results_three_proportion_", Selected_Atlas_Name, ".csv"), row.names = FALSE) 


################################################################################
#######    INTERGROUP STATISTICAL ANALYSIS   ###################################
################################################################################
###Statistical analysis for raw number of c-Fos positive cells###

#Prepare table for statistical analysis
Alldata2_raw <- subset(Alldata2, Alldata2$Num.cfos!= 0) #remove all rows with null value
Alldata2group_raw <-dplyr::group_by(Alldata2_raw, Condition, AnimalID, Name) #Group regions of interest/animals/condition
Alldata2group_raw <- dplyr::summarise(Alldata2group_raw, avg = mean(Num.cfos, na.rm=T))   #Calculate mean cfos number for regions of interest/condition

#Remove regions of interest with less than 3 values
SelectedAtlas_raw <- Alldata2group_raw %>%
  group_by(Condition, Name) %>%
  filter(n() >=2) %>%
  ungroup()

#Remove regions of interest only present in one condition
SelectedAtlas_raw <- SelectedAtlas_raw %>% 
  group_by(Name) %>%
  filter(n_distinct(Condition) >1) %>%
  ungroup()

#Calculate t-test
ttest_Atlas_raw <- dplyr::group_by(SelectedAtlas_raw, Condition, Name) #Group results for selected atlas

P_val_raw = {ttest_Atlas_raw %>%                    #Calculate t-test values
    group_by(Name) %>%
    t_test(avg~Condition)} 
P_val_raw                                          #Display statistical values
write.csv(P_val_raw, paste0(path_for_stat_test, "All_p_val_condition1VScondition2_raw_", Selected_Atlas_Name, ".csv"), row.names = FALSE)

Signif_ROI_raw <- subset(P_val_raw, P_val_raw$p < 0.05) #Select ROI with p_value < 0.05
Signif_ROI_raw$p_value_stat <-Signif_ROI_raw$p
write.csv(Signif_ROI_raw, paste0(path_for_stat_test, "SignificativeROI_condition1VScondition2_raw_", Selected_Atlas_Name, ".csv"), row.names = FALSE)


###Statistical analysis for Density ###

#Prepare table for statistical analysis
Alldata2_density <- subset(Alldata2, Alldata2$density_cfos!= 0) #remove all rows with null value
Alldata2group_density <-dplyr::group_by(Alldata2_density, Condition, AnimalID, Name) #Group regions of interest/animals/condition
Alldata2group_density <- dplyr::summarise(Alldata2group_density, avg = mean(density_cfos, na.rm=T))   #Calculate density_cfos for regions of interest/condition

#Remove regions of interest with less than 3 values
SelectedAtlas_density <- Alldata2group_density %>%
  group_by(Condition, Name) %>%
  filter(n() >=2) %>%
  ungroup()

#Remove regions of interest only present in one condition
SelectedAtlas_density <- SelectedAtlas_density %>% 
  group_by(Name) %>%
  filter(n_distinct(Condition) >1) %>%
  ungroup()

#Calculate t-test
ttest_Atlas_density <- dplyr::group_by(SelectedAtlas_density, Condition, Name) #Group results for selected atlas

P_val_density = {ttest_Atlas_density %>%                    #Calculate t-test values
    group_by(Name) %>%
    t_test(avg~Condition)} 
P_val_density                                          #Display statistical values

Signif_ROI_d <- subset(P_val_density, P_val_density$p < 0.05) #Select ROI with p_value < 0.05
Signif_ROI_d$p_value_stat <-Signif_ROI_d$p
write.csv(Signif_ROI_d, paste0(path_for_stat_test, "SignificativeROI_condition1VScondition2_density_", Selected_Atlas_Name, ".csv"), row.names = FALSE)     
write.csv(P_val_density, paste0(path_for_stat_test, "All_p_val_condition1VScondition2_density_", Selected_Atlas_Name, ".csv"), row.names = FALSE)      

###Statistical analysis for Proportion ###
#Prepare table for statistical analysis
Alldata2_proportion <- subset(Alldata2, Alldata2$Proportion!= 0) #remove all rows with null value
Alldata2group_proportion <-dplyr::group_by(Alldata2_proportion, Condition, AnimalID, Name) #Group regions of interest/animals/condition
Alldata2group_proportion <- dplyr::summarise(Alldata2group_proportion, avg = mean(Proportion, na.rm=T))   #Calculate mean proportion for regions of interest/condition

#Remove regions of interest with less than 3 values
SelectedAtlas_proportion <- Alldata2group_proportion %>%
  group_by(Condition, Name) %>%
  filter(n() >=2) %>%
  ungroup()

#Remove regions of interest only present in one condition
SelectedAtlas_proportion <- SelectedAtlas_proportion %>% 
  group_by(Name) %>%
  filter(n_distinct(Condition) >1) %>%
  ungroup()

#Calculate t-test
ttest_Atlas_proportion <- dplyr::group_by(SelectedAtlas_proportion, Condition, Name) #Group results for selected atlas

P_val_proportion = {ttest_Atlas_proportion %>%                    #Calculate t-test values
    group_by(Name) %>%
    t_test(avg~Condition)} 
P_val_proportion                                       #Display statistical values

Signif_ROI_proportion <- subset(P_val_proportion, P_val_proportion$p < 0.05) #Select ROI with p_value < 0.05
Signif_ROI_proportion$p_value_stat <-Signif_ROI_proportion$p
write.csv(Signif_ROI_proportion, paste0(path_for_stat_test, "SignificativeROI_condition1VScondition2_proportion_", Selected_Atlas_Name, ".csv"), row.names = FALSE)      
write.csv(P_val_proportion, paste0(path_for_stat_test, "All_p_val_condition1VScondition2_proportion_", Selected_Atlas_Name, ".csv"), row.names = FALSE)      

###Extract top10 activated structures (as shown by densities) for each experimental group###

#First experimental group#
AlldataGroup1 <- subset(Alldata2,Alldata2$Condition=="Wakefulness")
top10AnalysisGroup1<- AlldataGroup1 %>%
  group_by(Name) %>%
  filter(Num.cfos > 10 & Area.µm.2 > 1000)  %>%  #Remove aberrant ROI based on number of cells and size
  summarize_at(vars(density_cfos), list(new=mean)) %>%
  top_n(10, new) %>% arrange(desc(new))
top10AnalysisGroup1   #display results
 
###2nd experimental group###
AlldataGroup2 <- subset(Alldata2,Alldata2$Condition=="Paradoxical Sleep")
top10AnalysisGroup2 <- AlldataGroup2 %>%
  group_by(Name) %>%
  filter(Num.cfos > 10 & Area.µm.2 > 1000)  %>%
  summarize_at(vars(density_cfos), list(new=mean)) %>%
  top_n(10, new) %>% arrange(desc(new))
top10AnalysisGroup2   #display results

#########################################################################
#####    ANALYSIS FOR USER DEFINED ROI    ###############################
#########################################################################

##### specific ROI for raw number of c-Fos positive cells  #####

#Start from unprocessed "Alldata" dataframe to extract ROI (e.g. "Ammon's horn")
dataStructure_raw <- subset(Alldata, Alldata$Parent=="Ammon's horn")   
df_rawdata_per_animal_stat <- data_sem(dataStructure_raw, varname="Num.cfos",  #Calculate SEM for selected variable (here cfos number cells)
                 groupnames=c("Condition", "Name"))
ggplot(df_rawdata_per_animal_stat, aes(x = Name, y=Num.cfos, fill=Condition))+ #Create bargraph comparing proportion between experimental groups
  geom_bar(stat="identity", color="black", 
           position=position_dodge())+ 
  geom_errorbar(aes(ymin=Num.cfos-sem, ymax=Num.cfos+sem), width=.2,
                position=position_dodge(.9)) +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1), panel.background = element_blank())+
  scale_fill_manual(values=c("#48b095", "#00381d"))      #Colors can be changed to match Allen Atlas pallet 

### Intergroup statistical analysis for selected region  ###

#Prepare table for statistical analysis
dataStructure_raw <- subset(dataStructure_raw, dataStructure_raw$Num.cfos!= 0) #remove all rows with null value
dataStructure_raw_group <-dplyr::group_by(dataStructure_raw, Condition, AnimalID, Name) #Group chosen structure sub-regions/animals/condition
dataStructure_raw_group <- dplyr::summarise(dataStructure_raw_group, avg = mean(Num.cfos, na.rm=T)) #Calculate mean cfos cell for chosen structure sub-regions/condition

#Remove ROIs with less than 3 values
SelectedRegion_raw <- dataStructure_raw_group %>%
  group_by(Condition, Name) %>%
  filter(n() >=2) %>%
  ungroup()

#Remove ROIs only present in one condition
SelectedRegion_raw <- SelectedRegion_raw %>% 
  group_by(Name) %>%
  filter(n_distinct(Condition) >1) %>%
  ungroup()

#Calculate t-test
ttest_Atlas_raw <- dplyr::group_by(SelectedRegion_raw, Condition, Name) #Group results for selected region

P_val_subR_raw = {ttest_Atlas_raw %>%                         #Calculate t-test values
    group_by(Name) %>%
    t_test(avg~Condition)} 
P_val_subR_raw                                            #Display statistical values
write.csv(P_val_subR_raw, paste0(path_for_stat_test, "__xxxnamexxx__", Selected_Atlas_Name, ".csv"), row.names = FALSE)      

Signif_subR_raw <- subset(P_val_subR_raw, P_val_subR_raw$p < 0.05) #Select ROI with p_value < 0.05
Signif_subR_raw$p_value_stat <-Signif_subR_raw$p
Signif_subR_raw
write.csv(Signif_subR_raw, paste0(path_for_stat_test, "__xxxnamexxx__", Selected_Atlas_Name, ".csv"), row.names = FALSE)      


##### for density_cfos    #####

#Start from unprocessed "Alldata" dataframe to extract ROI (e.g. "Ammon's horn")
dataStructure_density <- subset(Alldata, Alldata$Parent=="Ammon's horn")   
df_density_cfos_stat <- data_sem(dataStructure_density, varname="density_cfos",      #Calculate SEM for selected variable (here density_cfos)
                 groupnames=c("Condition", "Name"))
ggplot(df_density_cfos_stat, aes(x = Name, y=density_cfos, fill=Condition))+ #Create bargraph comparing proportion between experimental groups
  geom_bar(stat="identity", color="black", 
           position=position_dodge())+ 
  geom_errorbar(aes(ymin=density_cfos-sem, ymax=density_cfos+sem), width=.2,
                position=position_dodge(.9)) +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1), panel.background = element_blank())+
  scale_fill_manual(values=c("#48b095", "#00381d"))      #Colors can be changed to match Allen Atlas pallet 

### Intergroup statistical analysis for selected region  ###

#Prepare table for statistical analysis
dataStructure_density <- subset(dataStructure_density, dataStructure_density$density_cfos!= 0) #remove all rows with null value
dataStructure_density_group <-dplyr::group_by(dataStructure_density, Condition, AnimalID, Name) #Group chosen structure sub-regions/animals/condition
dataStructure_density_group <- dplyr::summarise(dataStructure_density_group, avg = mean(density_cfos, na.rm=T)) #Calculate mean density_cfos for chosen structure sub-regions/condition

#Remove ROIs with less than 3 values
SelectedRegion_density <- dataStructure_density_group %>%
  group_by(Condition, Name) %>%
  filter(n() >=2) %>%
  ungroup()

#Remove ROIs only present in one condition
SelectedRegion_density <- SelectedRegion_density %>% 
  group_by(Name) %>%
  filter(n_distinct(Condition) >1) %>%
  ungroup()

#Calculate t-test
ttest_Atlas_density <- dplyr::group_by(SelectedRegion_density, Condition, Name) #Group results for selected region

P_val_subR_density = {ttest_Atlas_density %>%                         #Calculate t-test values
    group_by(Name) %>%
    t_test(avg~Condition)} 
P_val_subR_density                                            #Display statistical values
write.csv(P_val_subR_density, paste0(path_for_stat_test, "__xxxnamexxx__", Selected_Atlas_Name, ".csv"), row.names = FALSE)      

Signif_subR_density <- subset(P_val_subR_density, P_val_subR_density$p < 0.05) #Select ROI with p_value < 0.05
Signif_subR_density$p_value_stat <-Signif_subR_density$p
Signif_subR_density
write.csv(Signif_subR_density, paste0(path_for_stat_test, "__xxxnamexxx__", Selected_Atlas_Name, ".csv"), row.names = FALSE)      


##### for proportion #####

#Start from unprocessed "Alldata" dataframe to extract ROI (e.g. "Ammon's horn")
dataStructure_proportion <- subset(Alldata, Alldata$Parent=="Ammon's horn")   
df_Proportion_stat <- data_sem(dataStructure_proportion, varname="Proportion",      #Calculate SEM for selected variable (here proportion)
                 groupnames=c("Condition", "Name"))
ggplot(df_Proportion_stat, aes(x = Name, y=Proportion, fill=Condition))+ #Create bargraph comparing proportion between experimental groups
  geom_bar(stat="identity", color="black", 
           position=position_dodge())+ 
  geom_errorbar(aes(ymin=Proportion-sem, ymax=Proportion+sem), width=.2,
                position=position_dodge(.9)) +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1), panel.background = element_blank())+
  scale_fill_manual(values=c("#48b095", "#00381d"))      #Colors can be changed to match Allen Atlas pallet 

### Intergroup statistical analysis for selected region  ###

#Prepare table for statistical analysis
dataStructure1_p <- subset(dataStructure_proportion, dataStructure_proportion$Proportion!= 0) #remove all rows with null value
dataStructure_proportion_group <-dplyr::group_by(dataStructure_proportion, Condition, AnimalID, Name) #Group chosen structure sub-regions/animals/condition
dataStructure_proportion_group <- dplyr::summarise(dataStructure_proportion_group, avg = mean(Proportion, na.rm=T)) #Calculate mean proportion for chosen structure sub-regions/condition

#Remove ROIs with less than 3 values
SelectedRegion_proportion <- dataStructure_proportion_group %>%
  group_by(Condition, Name) %>%
  filter(n() >=2) %>%
  ungroup()

#Remove ROIs only present in one condition
SelectedRegion_proportion <- SelectedRegion_proportion %>% 
  group_by(Name) %>%
  filter(n_distinct(Condition) >1) %>%
  ungroup()

#Calculate t-test
ttest_Atlas_proportion <- dplyr::group_by(SelectedRegion_proportion, Condition, Name) #Group results for selected region

P_val_subR_proportion = {ttest_Atlas_proportion %>%                         #Calculate t-test values
    group_by(Name) %>%
    t_test(avg~Condition)} 
P_val_subR_proportion                                            #Display statistical values
write.csv(P_val_subR_proportion, paste0(path_for_stat_test, "__xxxnamexxx__", Selected_Atlas_Name, ".csv"), row.names = FALSE)      

Signif_subR_proportion <- subset(P_val_subR_proportion, P_val_subR_proportion$p < 0.05) #Select ROI with p_value < 0.05
Signif_subR_proportion$p_value_stat <-Signif_subR_proportion$p
Signif_subR_proportion
write.csv(Signif_subR_proportion, paste0(path_for_stat_test, "__xxxnamexxx__", Selected_Atlas_Name, ".csv"), row.names = FALSE)      


##############
##### END ####
##############

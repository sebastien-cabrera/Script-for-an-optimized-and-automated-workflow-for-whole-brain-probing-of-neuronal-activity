# Establishment of an optimized and automated workflow for whole brain probing of neuronal activity

Behaviors are encoded by widespread neural circuits within the brain that change with age and experience. Immunodetection of the immediate early gene c-Fos has been successfully used for decades to reveal neural 
circuits active during specific tasks or conditions. Our objectives here were to develop and benchmark a workflow that circumvents classical temporal and spatial limitations associated with c-Fos quantification. 
We combined c-Fos immunohistochemistry with c-Fos driven Cre-dependent tdTomato expression in the TRAP2 mice, to visualize and perform a direct comparison of neural circuits activated at different times or during 
different tasks. By using open-source software (QuPath and ABBA), we established a workflow that optimize and automate cell detection, cell classification (e.g. c-Fos vs. c-Fos/tdTomato) and whole brain registration.
We demonstrate that this workflow, based on fully automatic scripts, allows accurate cell number quantification with minimal interindividual variability. Further, interrogation of brain atlases at different scales 
(from simplified to detailed) allows gradually zooming on brain regions to explore spatial distribution of activated cells. We illustrate the potential of this approach by comparing patterns of neuronal activation 
in various contexts (two vigilance states, complex behavioral tasks…), in separate groups of mice or at two time points in the same animals. Finally, we explore software (BrainRender) for intuitive representation 
of the results. Altogether, this automated workflow accessible to all labs with some expertise in histology, allows an unbiased, fast and accurate analysis of the whole brain activity pattern at the cellular level,
in various contexts.

# Corresponding Authors
Cabrera Sébastien  (sebastien.cabrera@etu.univ-lyon1.fr; sebastien-75@wanadoo.fr)

Raineteau Olivier  (olivier.raineteau@inserm.fr)

Mandairon Nathalie (nathalie.mandairon@univ-lyon1.fr)

Luppi Pierre-Hervé (pierre-herve.luppi@cnrs.fr)

![Figure-1](https://github.com/user-attachments/assets/c65fd11b-33ef-43aa-9506-edc3dc939c8c)

# Provided Scripts 
**"Script for analysis" section** 
  
  <ins> 3D data representation Script.py </ins>

The “3D-rendering” script allows to represent the data of the analysis in 3D using a mouse brain template. The “3D-rendering” script is written in Python (v.3.9.18) and is based on BrainRender9, (https://github.com/brainglobe/brainrender). It requires a CSV input file listing c-Fos cells “density”, “proportion”, “raw number” or “p-values” in order to represent results at the chosen Atlas resolution. Installation procedure and documentation will be available on the team’s GitHub.

After library importation and the definitions of the script functions, Dialog Boxes are generated to define the type of representation, the conditions and the cell population to represent. Based on the items selected by the user, the data frame is extracted from the file previously defined.

In the case of a representation of one condition by cell density, relevant data are filtered from the data frame. For comparing 2 conditions, the script makes a ratio with those: Condition1 / (Condition1 + Condition2). This allows us to create a scale to visualize the differences between the 2 conditions. Finally, 3D representation is generated in a new window.

<ins> Atlas creation.R </ins>

This script allows creation of several personalized Atlases, for cell detection analysis, as “MajorDivision”, “Summary_Structure” or “Full_List”. It works in collaboration with the “Definition_Allen_atlas_resolutions” excel file. When it is called on “Script for QuPath_ABBA analysis_Comparing groups”, a window will open asking which atlas user wants to use. Once selected, the script will implement structures appearing on the chosen atlas on analysis data. Moreover, is possible to create new more specific atlases (see troubleshooting for more information).

<ins> Atlas creation.R </ins>

This excel file gathers all the structures/sub-structures listed in the Allen Atlas and organizes them according to the three predefined atlases; "Full_Atlas", "Summary_Structure" and "MajorDivision". Thus, when MajorDivision is selected for example, only structures checked in MajorDivision column will be selected in the “Script for QuPath ABBA analysis Comparing groups” script.

<ins> QuPath_ABBA analysis_QualityControl.R </ins>

In this script, data extracted from a single animal are processed for quality control. As a first step, 3 graphs are produced for representing the number and the density of c-Fos/section, as well as the proportion of detected artifacts. While the first two graphs inform the experimenter on missing and/or broken sections, the last graph allows validating the classifier and/or identifying sections with dust (corresponding to high percentage of artifacts). In a second step, the percentage of c-Fos detected cells in two regions devoid of neurons, i.e. ventricular systems and white matter tracts, is calculated. A value >5% (indicated by a dotted red line) is indicative of a suboptimal registration of the section onto the reference atlas. Finally, the density of c-Fos detected cells in regions of the simplified atlas are plotted. All plots are presented on a single page, so that sections showing aberrant cell numbers can be easily identified.

<ins> Script for QuPath_Abba analysis_Comparison groups.R </ins>

This script allows importing quantification performed in single animals to group them under specific experimental conditions. Following import, an atlas is selected allowing group analysis or comparison using cell density, proportion or raw number. The script allows calculation of statistics and exportation of obtained values in a csv file for 3D data representation using BrainRender, as described below.
\
\
\
\
**"Script-for-automatic-detection" section**

<ins> Automatic_threshold_application_(QuPath).groovy </ins>

This script allows automatic thresholding using QuPath, as follows. All objects are suppressed before an automatic brain section contour is created to extract median fluorescence intensities for all the sections of the series. Individual section values are then used to optimize “Cell detection” (see QuPath website for more information, https://qupath.github.io/) using fixed parameters (i.e. cell diameter, sphericity…). To separate cells of interest from artifacts, an automatic classifier based on machine learning was applied. This classifier should be implemented for each project.

<ins> Automatic_threshold_application_(ImageJ).groovy </ins>

This script follows the same workflow as the previous one but introduces the use of imageJ automatic thresholding methods. It necessitates calling "macro-threshold-auto-c-Fos.ijm" (see below). 

<ins> macro-threshold-auto-c-Fos.ijm </ins>

this script allows choosing the imageJ automatic thresholding method to use (i.e. Mean, Otsu, Percentile…) for automatic cell detection. For threshold calculation, 60 rectangles (1000*1000 pixels) are randomly generated on each section, which allow extracting signal mean intensities which are saved within an ‘output’ .txt folder. ImageJ values are then used by the QuPath software to apply the value. To limit influences of artifactual values (i.e. corresponding to rectangles partly located beside the section or containing brightly fluorescent dusts), an interval for the mean validation is imposed after the 10th rectangle is calculated. To be brief, the intensity value of the 11th selected rectangle must be between 0.1 and 1,9 * mean of 10 first rectangles. If the value is validated, it will be included in the calculation and this interval will evolve as the control progresses. All valid intensity values are accumulated to generate one and only mean (named “reamean” in the script). For each section, this process is repeated 4 times, and the mean of these repetitions determines the threshold used. On average, around 30-40 rectangles are selected over 60 to participate in threshold value elaboration. When the number of rectangles validated is inferior to 20, the script defines the threshold as 10000000 in order to stop the analysis for visual inspection of the sections.


//This macro is part of the manuscript "Establishment of an optimized and automated workflow for whole brain probing of neuronal activity. Cabrera et al."
//This macro is used to perform cell detection using ImageJ thresholding method indicated at line 25.

{
//Define path where the 50 rectangles for threshold definition will be load. 
//WARNING : this path needs to be indicated in Qupath script ("Automatic_threshold_application_(ImageJ)", line 10)
open("/Users/Eq.Raineteau_2023/Desktop/Script Mean Image J-Qupath/Output/region.tif");
title = getTitle();
run("Split Channels");
title_c1 = "C1-"+title;
title_c2 = "C2-"+title;
selectWindow(title_c1);
close();                       //For adding/removing channels refer to troubleshootings section
selectWindow(title_c2);
run("Duplicate...", "title=["+title_c2+"-bckgdradius50]");   //Image pre-processing
selectWindow(title_c2+"-bckgdradius50");
run("Subtract Background...", "rolling=50");
run("Duplicate...", "title=["+title_c2+"-bckgdradius50-gaussianF]");
selectWindow(title_c2+"-bckgdradius50-gaussianF");
//run("Gaussian Blur...");
run("Gaussian Blur...", "sigma=1.5 scaled");
run("Duplicate...", "title=["+title_c2+"-bckgdradius50-gaussianF1-5um-threshold]");
run("Tile");
selectWindow(title_c2+"-bckgdradius50-gaussianF1-5um-threshold");
setAutoThreshold("Huang dark");                              //selection of ImageJ thresholding method
getThreshold(lower, upper);
close();
print("thresholds");
print(lower);
//Define path to save threshold result files. 
//WARNING : this path needs to be indicated in FIJI macro ("Automatic_threshold_application_(ImageJ)_for_submission", line 13)
file=File.open("/Users/Eq.Raineteau_2023/Desktop/Script Mean Image J-Qupath/Output/threshold.txt");
print(file, ""+lower);
close();
close();
close();
}

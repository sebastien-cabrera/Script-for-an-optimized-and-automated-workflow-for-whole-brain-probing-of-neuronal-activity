//This script is part of the manuscript "Establishment of an optimized and automated workflow for whole brain probing of neuronal activity. Cabrera et al."
//This script is for automatic cell detection using ImageJ thresholding methods.


//INSTALLATION : please define location of .exe file, macro and folders as shown below :
// Define path to ImageJ FIJI executable
def imagejPath ='/Fiji.app/ImageJ-win64.exe'

// Define path to FIJI macro
def macroPath ='/Users/Eq.Raineteau_2023/Desktop/Script Mean Image J-Qupath/macro-threshold-auto-cfos.ijm'

// Define folder path where FIJI macro output will be saved. Warning : this path needs to be indicated in FIJI macro ("macro-threshold-auto-cfos.ijm", line 7)
def outputthr = '/Users/Eq.Raineteau_2023/Desktop/Script Mean Image J-Qupath/Output/region.tif'

// Define path to threshold result file. Warning : this path needs to be indicated in FIJI macro ("macro-threshold-auto-cfos.ijm", line 32)
def thresholdFile = new File('/Users/Eq.Raineteau_2023/Desktop/Script Mean Image J-Qupath/Output/threshold.txt')

// Define image channels
setChannelNames( 
    'DAPI',
    'cfos')

// Load libraries
import ij.IJ
import ij.ImagePlus
import ij.plugin.frame.RoiManager
import qupath.lib.objects.PathAnnotationObject
import qupath.imagej.tools.IJTools
import ij.ImagePlus
import ij.process.ImageProcessor
import ij.plugin.filter.GaussianBlur
import ij.plugin.filter.BackgroundSubtracter
import ij.plugin.frame.RoiManager
import qupath.lib.objects.PathObject

// RECTANGLES GENERATION SCRIPT
/*
 * This script generates rectangle annotations at random locations in QuPath,
 * Annotations falling beside the sections will be discarded. 
 * This code was inspired by https://forum.image.sc/t/digital-chalkley-point-graticule-overlay/51211
 * @author Pete Bankhead
 */
// Define the number of rectangle annotations
int nRectangles = 60

// Initialize parameters
double rectangleWidth = 1000
double rectangleHeight = 1000
def resthra = 0
def resthrb = 0
def resthrc = 0
def resthrd = 0
def i = 0

// Loop to repeate threshold analyse
while (i != 4 ) {
    // Generation of rectangle annotations
    int maxFailures = 100 // If the selected region is too small, we won't manage to generate rectangles
    int seed = -1 // Set a seed for reproducibility (ignored if < 0)
    boolean preferEllipse = true // If no ROI is selected, 
    def server1 = getCurrentServer()
    def selected = getSelectedObject()
    def roi1 = selected?.getROI()
    if (roi1 == null || roi1.isPoint()) {
        selected = null
        def plane = getCurrentViewer()?.getImagePlane()
        if (plane == null)
            plane = ImagePlane.getDefaultPlane()
        if (preferEllipse) {
            int size = Math.min(server1.getWidth(), server1.getHeight())
            roi1 = ROIs.createEllipseROI(server1.getWidth()/2-size/2 as int, server1.getHeight()/2-size/2 as int, size, size, plane)
        } else {
            roi1 = ROIs.createRectangleROI(0, 0, server1.getWidth, server1.getHeight(), plane, plane)
        }
    }
    geomTissue = roi1.getGeometry()
    def rng = new Random()
    if (seed >= 0)
        rng.setSeed(seed)
    int count = 0
    def rectangles = []
    int nFailures = 0
    def geomTotal 
    while (count < nRectangles && nFailures < maxFailures) {
        if (Thread.currentThread().isInterrupted()) {
            println 'Interrupted!'
            return
        }
        double x = roi1.getBoundsX() + rng.nextDouble() * (roi1.getBoundsWidth() - rectangleWidth)
        double y = roi1.getBoundsY() + rng.nextDouble() * (roi1.getBoundsHeight() - rectangleHeight)
        if (!roi1.contains(x, y)) {
            nFailures++
            continue
        }    
        rectangleROI = ROIs.createRectangleROI(x, y, rectangleWidth, rectangleHeight, roi1.getImagePlane())
        newGeom = rectangleROI.getGeometry()
        if(!geomTotal){
            geomTotal = newGeom
        }
        overlap = geomTotal.intersects(newGeom) || ( geomTissue.intersection(newGeom).getArea() < newGeom.getArea() )
        // print overlap
        if(!overlap){
            geomTotal = geomTotal.union(newGeom)
            rectangles << rectangleROI
            count++
        }
        nFailures = 0
    }
    print nFailures
    if (nFailures == maxFailures) {
        println "I didn't manage to create all the rectangles you wanted, sorry"
    }    
    def annotations = rectangles.collect {PathObjects.createAnnotationObject(it)}
    if (selected) {
        selected.addPathObjects(annotations)
        fireHierarchyUpdate()
    } else
        addObjects(annotations)
    // RECTANGLES GENERATION SCRIPT END
    
    // EXTRACTION OF INTENSITY VALUES FROM RECTANGLES PREVIOUSLY GENERATED
    // Initialisation parameters
    def totmeas = 0
    def nbanalysis = 0
    def resmean = 0
    annotations = getAnnotationObjects();
    // Threshold calculation for each rectangle
    for (PathObject annotation : annotations) {
        selectObjects(annotation)
        def server2 = getCurrentServer()
        def roi2 = getSelectedROI()
        def requestROI = RegionRequest.createInstance(server2.getPath(), 1, roi2)
        writeImageRegion(server2, requestROI, outputthr)
        def macroCommand = "runMacro(\"${macroPath}\");" // To call FIJI MACRO on selected section
        IJ.runMacro(macroCommand)
        def scanner = new Scanner(thresholdFile)      // Scanner is created to read files containing threshold value 
        def fijimeasur = 0                            // Initialize "fijimeasur" variable to 0
        if (scanner.hasNextDouble()) {                // Check if scanner is a double
            fijimeasur = scanner.nextDouble()            
            if (nbanalysis < 10 ) {                   // For the 9 first threshold calculation : keep all values 
                totmeas = totmeas+fijimeasur
                nbanalysis = nbanalysis + 1
                println("Threshold value is : " + fijimeasur)                
                } else {                              // For next threshold calculation : keep only values >0.1 * mean of thresholds and values <1.9 * mean of thresholds
                    
                    if (fijimeasur >(resmean*0.1) && fijimeasur <(resmean*1.9)) {
                        totmeas = totmeas+fijimeasur
                        nbanalysis = nbanalysis + 1
                        println("Threshold value is : " + fijimeasur)
                    }
                }
            }
        resmean = totmeas / nbanalysis 
        scanner.close()                              // Close scanner to freeing up ressources
        }
    clearDetections()    
    clearAnnotations() //Clear rectangles annotations

    print resmean
    print nbanalysis
                                 
    if (i == 0){resthra = resmean
                if (nbanalysis < 20){resthra = 10000000000   // Number of rectangle is taking into account for producing mean threshold, 
                }}                                           // If under 20, detection will not appear on the selected section
    if (i == 1){resthrb = resmean
                if (nbanalysis < 20){resthrb = 10000000000
                }}
    if (i == 2){resthrc = resmean
                if (nbanalysis < 20){resthrc = 10000000000
                }}
    if (i == 3){resthrd = resmean
                if (nbanalysis < 20){resthrd = 10000000000
                }}
    i = i+1
}
print resthra
def resfinal = (resthra + resthrb + resthrc + resthrd) / 4
print(resthra)
print(resthrb)
print(resthrc)
print("RESULT :")
print(resfinal)

if (resfinal < 100000000) {
    // Setting section contour
    runPlugin('qupath.imagej.detect.tissue.SimpleTissueDetection2', '{"threshold": 0,'+
              '"requestedPixelSizeMicrons": 20.0,  "minAreaMicrons": 10000.0,'+
              '"maxHoleAreaMicrons": 1000000.0,  "darkBackground": true,  "smoothImage": true,'+
              '"medianCleanup": true,  "dilateBoundaries": false,  "smoothCoordinates": true,'+
              '"excludeOnBoundary": false,  "singleAnnotation": true}');              
selectAnnotations()
    //Cell detection cfos
    runPlugin('qupath.imagej.detect.cells.WatershedCellDetection', '{"detectionImage": "cfos",'+
              '"requestedPixelSizeMicrons": 0.5,  "backgroundRadiusMicrons": 5.0,  "medianRadiusMicrons": 1.0,'+
              '"sigmaMicrons": 2.0,  "minAreaMicrons": 25.0,  "maxAreaMicrons": 200.0,  "threshold": '+ resfinal +','+
              '"watershedPostProcess": true,  "cellExpansionMicrons": 0.1,  "includeNuclei": true,'+
              '"smoothBoundaries": true,  "makeMeasurements": true}');
}            
//This script is part of the manuscript "Establishment of an optimized and automated workflow for whole brain probing of neuronal activity. Cabrera et al."
//This script is for automatic cell detection using Qupath median thresholding method.

clearDetections()
clearAnnotations()
// Setting section contour
runPlugin('qupath.imagej.detect.tissue.SimpleTissueDetection2', '{"threshold": 5,'+
          '"requestedPixelSizeMicrons": 20.0,  "minAreaMicrons": 10000.0,'+
          '"maxHoleAreaMicrons": 1000000.0,  "darkBackground": true,  "smoothImage": true,'+
          '"medianCleanup": true,  "dilateBoundaries": false,  "smoothCoordinates": true,'+
          '"excludeOnBoundary": false,  "singleAnnotation": true}');


setChannelNames('dapi', 'cfos') // change here according the number of channels

// recovery of all intensity information relating to the section
selectAnnotations()
runPlugin('qupath.lib.algorithms.IntensityFeaturesPlugin', '{"pixelSizeMicrons": 2.0,  "region": "ROI",'+
          '"tileSizeMicrons": 25.0,  "channel1": false,  "channel2": true,'+
          '"doMean": true,  "doStdDev": true,  "doMinMax": true,  "doMedian": true,'+
          '"doHaralick": false,  "haralickMin": NaN,  "haralickMax": NaN,  "haralickDistance": 1,  "haralickBins": 32}');

// Definition of variable taking median intensity as its value
def imagestats=getAnnotationObjects()[0]
def imagestatsML=imagestats.getMeasurementList()
def double cfos_median_intensity = imagestatsML.getMeasurementValue("ROI: 2.00 µm per pixel: cfos: Median")

// C-fos detection with the previous defined variable for threshold parameter
runPlugin('qupath.imagej.detect.cells.WatershedCellDetection', '{"detectionImage": "cfos",'+
          '"requestedPixelSizeMicrons": 0.5,  "backgroundRadiusMicrons": 5.0,  "medianRadiusMicrons": 1.0,'+
          '"sigmaMicrons": 2.0,  "minAreaMicrons": 25.0,  "maxAreaMicrons": 200.0,  "threshold": '+cfos_median_intensity+','+
          '"watershedPostProcess": true,  "cellExpansionMicrons": 0.1,  "includeNuclei": true,'+
          '"smoothBoundaries": true,  "makeMeasurements": true}');

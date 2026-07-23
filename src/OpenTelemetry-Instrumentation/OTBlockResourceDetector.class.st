"
A pluggable resource detector backed by an arbitrary block, useful for tests and custom integrations.
"
Class {
	#name : 'OTBlockResourceDetector',
	#superclass : 'OTResourceDetector',
	#instVars : [
		'detectorName',
		'detectBlock'
	],
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'instance creation' }
OTBlockResourceDetector class >> named: aString detecting: aBlock [

	^ self new
		  detectorName: aString;
		  detectBlock: aBlock;
		  yourself
]

{ #category : 'private' }
OTBlockResourceDetector >> detectBlock: aBlock [

	detectBlock := aBlock
]

{ #category : 'detecting' }
OTBlockResourceDetector >> detectResource [

	^ detectBlock value
]

{ #category : 'accessing' }
OTBlockResourceDetector >> detectorName [

	^ detectorName ifNil: [ super detectorName ]
]

{ #category : 'private' }
OTBlockResourceDetector >> detectorName: aString [

	detectorName := aString
]

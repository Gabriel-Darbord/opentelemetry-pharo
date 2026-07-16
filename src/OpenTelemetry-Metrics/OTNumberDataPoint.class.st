Class {
	#name : 'OTNumberDataPoint',
	#superclass : 'Object',
	#instVars : [
		'attributes',
		'value',
		'startTimestamp',
		'timestamp'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTNumberDataPoint class >> attributes: aCollection value: aNumber startTimestamp: aStartDateAndTime timestamp: anEndDateAndTime [

	| point |
	point := self new.
	point
		attributes: aCollection;
		value: aNumber;
		startTimestamp: aStartDateAndTime;
		timestamp: anEndDateAndTime.
	^ point
]

{ #category : 'accessing' }
OTNumberDataPoint >> attributes [

	^ attributes ifNil: [ OrderedDictionary new ]
]

{ #category : 'accessing' }
OTNumberDataPoint >> attributes: aCollection [

	attributes := OTAttributeNormalizer normalizeAttributes: aCollection
]

{ #category : 'accessing' }
OTNumberDataPoint >> value [

	^ value
]

{ #category : 'accessing' }
OTNumberDataPoint >> value: aNumber [

	value := aNumber
]

{ #category : 'accessing' }
OTNumberDataPoint >> startTimestamp [

	^ startTimestamp
]

{ #category : 'accessing' }
OTNumberDataPoint >> startTimestamp: aDateAndTime [

	startTimestamp := aDateAndTime
]

{ #category : 'accessing' }
OTNumberDataPoint >> timestamp [

	^ timestamp
]

{ #category : 'accessing' }
OTNumberDataPoint >> timestamp: aDateAndTime [

	timestamp := aDateAndTime
]

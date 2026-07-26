Class {
	#name : 'OTRecordingMetricFilter',
	#superclass : 'OTMetricFilter',
	#instVars : [
		'metricResultBlock',
		'attributesResultBlock'
	],
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'accessing' }
OTRecordingMetricFilter >> attributesResultBlock [

	^ attributesResultBlock
]

{ #category : 'accessing' }
OTRecordingMetricFilter >> attributesResultBlock: aBlock [

	attributesResultBlock := aBlock
]

{ #category : 'initialization' }
OTRecordingMetricFilter >> initialize [

	super initialize.
	metricResultBlock := [ :scope :name :kind :unit | OTMetricFilter accept ].
	attributesResultBlock := [ :scope :name :kind :unit :attributes | OTMetricFilter accept ]
]

{ #category : 'accessing' }
OTRecordingMetricFilter >> metricResultBlock [

	^ metricResultBlock
]

{ #category : 'accessing' }
OTRecordingMetricFilter >> metricResultBlock: aBlock [

	metricResultBlock := aBlock
]

{ #category : 'filtering' }
OTRecordingMetricFilter >> testAttributesInScope: anOTInstrumentationScope name: aNameString kind: aKindSymbol unit: aUnitString attributes: someAttributes [

	^ attributesResultBlock valueWithArguments: {
			  anOTInstrumentationScope.
			  aNameString.
			  aKindSymbol.
			  aUnitString.
			  someAttributes }
]

{ #category : 'filtering' }
OTRecordingMetricFilter >> testMetricInScope: anOTInstrumentationScope name: aNameString kind: aKindSymbol unit: aUnitString [

	^ metricResultBlock valueWithArguments: {
			  anOTInstrumentationScope.
			  aNameString.
			  aKindSymbol.
			  aUnitString }
]

"
I define the boundary for metric stream filtering during collection.

Implementations can accept or drop whole metric streams, or accept only some
attribute sets from a stream.
"
Class {
	#name : 'OTMetricFilter',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'enumerating' }
OTMetricFilter class >> accept [

	^ #accept
]

{ #category : 'enumerating' }
OTMetricFilter class >> acceptPartial [

	^ #acceptPartial
]

{ #category : 'enumerating' }
OTMetricFilter class >> drop [

	^ #drop
]

{ #category : 'filtering' }
OTMetricFilter >> testAttributesInScope: anOTInstrumentationScope name: aNameString kind: aKindSymbol unit: aUnitString attributes: someAttributes [

	self subclassResponsibility
]

{ #category : 'filtering' }
OTMetricFilter >> testMetricInScope: anOTInstrumentationScope name: aNameString kind: aKindSymbol unit: aUnitString [

	self subclassResponsibility
]

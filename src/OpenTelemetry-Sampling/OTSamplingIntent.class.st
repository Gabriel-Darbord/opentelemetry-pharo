"
An immutable composable sampling preference used by CompositeSampler.
"
Class {
	#name : 'OTSamplingIntent',
	#superclass : 'Object',
	#instVars : [
		'threshold',
		'adjustedCountReliable',
		'attributesProvider',
		'traceStateProvider'
	],
	#category : 'OpenTelemetry-Sampling',
	#package : 'OpenTelemetry-Sampling'
}

{ #category : 'instance creation' }
OTSamplingIntent class >> drop [

	^ self threshold: nil adjustedCountReliable: false
]

{ #category : 'instance creation' }
OTSamplingIntent class >> threshold: anInteger adjustedCountReliable: aBoolean [

	^ self
		  threshold: anInteger
		  adjustedCountReliable: aBoolean
		  attributesProvider: nil
		  traceStateProvider: nil
]

{ #category : 'instance creation' }
OTSamplingIntent class >> threshold: anInteger adjustedCountReliable: aBoolean attributesProvider: anAttributesBlock traceStateProvider: aTraceStateBlock [

	^ self new
		  threshold: anInteger;
		  adjustedCountReliable: aBoolean;
		  attributesProvider: anAttributesBlock;
		  traceStateProvider: aTraceStateBlock;
		  yourself
]

{ #category : 'accessing' }
OTSamplingIntent >> adjustedCountReliable [

	^ adjustedCountReliable
]

{ #category : 'accessing' }
OTSamplingIntent >> adjustedCountReliable: aBoolean [

	adjustedCountReliable := aBoolean
]

{ #category : 'resolving' }
OTSamplingIntent >> attributes [

	^ self normalizedAttributesFrom: (attributesProvider ifNil: [ #(  ) ] ifNotNil: [ attributesProvider value ])
]

{ #category : 'accessing' }
OTSamplingIntent >> attributesProvider: aBlockOrNil [

	attributesProvider := aBlockOrNil
]

{ #category : 'private' }
OTSamplingIntent >> normalizedAttributesFrom: aCollection [

	aCollection ifNil: [ ^ #(  ) ].
	^ aCollection asArray
]

{ #category : 'accessing' }
OTSamplingIntent >> threshold [

	^ threshold
]

{ #category : 'accessing' }
OTSamplingIntent >> threshold: anIntegerOrNil [

	threshold := anIntegerOrNil
]

{ #category : 'resolving' }
OTSamplingIntent >> traceStateForParent: aTraceState decision: aDecisionSymbol [

	^ OTTraceState from:
		  (traceStateProvider ifNil: [ aTraceState ] ifNotNil: [ traceStateProvider value: aTraceState value: aDecisionSymbol ])
]

{ #category : 'accessing' }
OTSamplingIntent >> traceStateProvider: aBlockOrNil [

	traceStateProvider := aBlockOrNil
]

"
The immutable result of a sampling decision, including decision, extra attributes, and resulting trace state.
"
Class {
	#name : 'OTSamplingResult',
	#superclass : 'Object',
	#instVars : [
		'decision',
		'attributes',
		'traceState'
	],
	#category : 'OpenTelemetry-Sampling',
	#package : 'OpenTelemetry-Sampling'
}

{ #category : 'instance creation' }
OTSamplingResult class >> decision: aSymbol [

	^ self
		decision: aSymbol
		attributes: #()
		traceState: nil
]

{ #category : 'instance creation' }
OTSamplingResult class >> decision: aSymbol attributes: aCollection traceState: aTraceState [

	^ self new
		decision: aSymbol;
		attributes: (aCollection ifNil: [ #() ] ifNotNil: [ aCollection asArray ]);
		traceState: aTraceState;
		yourself
]

{ #category : 'instance creation' }
OTSamplingResult class >> drop [

	^ self decision: #drop
]

{ #category : 'instance creation' }
OTSamplingResult class >> recordAndSample [

	^ self decision: #recordAndSample
]

{ #category : 'instance creation' }
OTSamplingResult class >> recordOnly [

	^ self decision: #recordOnly
]

{ #category : 'accessing' }
OTSamplingResult >> attributes [

	^ attributes ifNil: [ #() ]
]

{ #category : 'accessing' }
OTSamplingResult >> attributes: aCollection [

	attributes := aCollection
]

{ #category : 'accessing' }
OTSamplingResult >> decision [

	^ decision
]

{ #category : 'accessing' }
OTSamplingResult >> decision: aSymbol [

	decision := aSymbol
]

{ #category : 'testing' }
OTSamplingResult >> isDrop [

	^ self decision = #drop
]

{ #category : 'testing' }
OTSamplingResult >> isRecordAndSample [

	^ self decision = #recordAndSample
]

{ #category : 'testing' }
OTSamplingResult >> isRecordOnly [

	^ self decision = #recordOnly
]

{ #category : 'testing' }
OTSamplingResult >> isRecording [

	^ self isDrop not
]

{ #category : 'accessing' }
OTSamplingResult >> traceFlags [

	^ self isRecordAndSample
		ifTrue: [ '01' ]
		ifFalse: [ '00' ]
]

{ #category : 'accessing' }
OTSamplingResult >> traceState [

	^ traceState
]

{ #category : 'accessing' }
OTSamplingResult >> traceState: aTraceState [

	traceState := aTraceState
]

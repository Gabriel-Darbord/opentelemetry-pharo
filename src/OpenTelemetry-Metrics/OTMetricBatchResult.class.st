"
I pair one metric snapshot with an explicit success, failure, or timeout status.

Metric readers and metric producers use me to surface partial collection results and failure reasons without discarding the collected metric data.
"
Class {
	#name : 'OTMetricBatchResult',
	#superclass : 'Object',
	#instVars : [
		'status',
		'snapshot',
		'failedReasons'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTMetricBatchResult class >> failureSnapshot: anOTMetricSnapshot failedReasons: aCollection [

	^ self status: #failure snapshot: anOTMetricSnapshot failedReasons: aCollection
]

{ #category : 'instance creation' }
OTMetricBatchResult class >> status: aSymbol snapshot: anOTMetricSnapshot failedReasons: aCollection [

	^ self new
		  status: aSymbol;
		  snapshot: anOTMetricSnapshot;
		  failedReasons: aCollection;
		  yourself
]

{ #category : 'instance creation' }
OTMetricBatchResult class >> successSnapshot: anOTMetricSnapshot [

	^ self status: #success snapshot: anOTMetricSnapshot failedReasons: #(  )
]

{ #category : 'instance creation' }
OTMetricBatchResult class >> timeoutSnapshot: anOTMetricSnapshot failedReasons: aCollection [

	^ self status: #timeout snapshot: anOTMetricSnapshot failedReasons: aCollection
]

{ #category : 'converting' }
OTMetricBatchResult >> asLifecycleResult [

	^ OTLifecycleResult new
		  status: self status;
		  yourself
]

{ #category : 'combining' }
OTMetricBatchResult >> combinedWithLifecycleResult: anOTLifecycleResult failedReason: aStringOrNil [

	| combined reasons |
	combined := self asLifecycleResult combinedWith: anOTLifecycleResult.
	reasons := self failedReasons asOrderedCollection.
	((anOTLifecycleResult notNil and: [ anOTLifecycleResult isSuccess not ]) and: [ aStringOrNil notNil ]) ifTrue: [
		reasons add: aStringOrNil ].
	^ self class status: combined status snapshot: self snapshot failedReasons: reasons
]

{ #category : 'accessing' }
OTMetricBatchResult >> failedReasons [

	^ failedReasons ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
OTMetricBatchResult >> failedReasons: aCollection [

	failedReasons := aCollection ifNil: [ #(  ) ] ifNotNil: [ aCollection asArray ]
]

{ #category : 'initialization' }
OTMetricBatchResult >> initialize [

	super initialize.
	status := #failure.
	snapshot := OTMetricSnapshot empty.
	failedReasons := #(  )
]

{ #category : 'testing' }
OTMetricBatchResult >> isFailure [

	^ status = #failure
]

{ #category : 'testing' }
OTMetricBatchResult >> isSuccess [

	^ status = #success
]

{ #category : 'testing' }
OTMetricBatchResult >> isTimeout [

	^ status = #timeout
]

{ #category : 'printing' }
OTMetricBatchResult >> printOn: aStream [

	super printOn: aStream.
	aStream
		nextPut: $(;
		nextPutAll: self status asString;
		nextPutAll: ', metrics=';
		print: self snapshot metrics size;
		nextPut: $)
]

{ #category : 'accessing' }
OTMetricBatchResult >> snapshot [

	^ snapshot ifNil: [ OTMetricSnapshot empty ]
]

{ #category : 'accessing' }
OTMetricBatchResult >> snapshot: anOTMetricSnapshot [

	snapshot := anOTMetricSnapshot ifNil: [ OTMetricSnapshot empty ] ifNotNil: [ anOTMetricSnapshot ]
]

{ #category : 'accessing' }
OTMetricBatchResult >> status [

	^ status
]

{ #category : 'accessing' }
OTMetricBatchResult >> status: aSymbol [

	status := aSymbol ifNil: [ #failure ] ifNotNil: [ aSymbol ]
]

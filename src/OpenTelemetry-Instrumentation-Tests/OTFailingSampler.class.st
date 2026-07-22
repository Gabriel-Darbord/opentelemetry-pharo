Class {
	#name : 'OTFailingSampler',
	#superclass : 'OTSampler',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'instance creation' }
OTFailingSampler class >> failingOperations: aCollection [

	^ self new
		  operationsToFail: aCollection;
		  yourself
]

{ #category : 'private' }
OTFailingSampler class >> operationsToFailBySampler [

	^ OTClassStateStore valueAt: #otOperationsToFailBySampler forClass: self ifAbsent: [
			  | samplers |
			  samplers := WeakIdentityKeyDictionary new.
			  OTClassStateStore valueAt: #otOperationsToFailBySampler forClass: self put: samplers.
			  samplers ]
]

{ #category : 'accessing' }
OTFailingSampler >> description [

	^ 'FailingSampler'
]

{ #category : 'accessing' }
OTFailingSampler >> operationsToFail: aCollection [

	self class operationsToFailBySampler at: self put: (aCollection ifNil: [ Set new ] ifNotNil: [ aCollection asSet ]).
	self
]

{ #category : 'testing' }
OTFailingSampler >> shouldFailOperationNamed: aString [

	^ (self class operationsToFailBySampler at: self ifAbsent: [ Set new ]) includes: aString
]

{ #category : 'sampling' }
OTFailingSampler >> shouldSampleIn: aContext traceId: aTraceId name: aString kind: aSpanKind attributes: someAttributes links: someLinks [

	^ OTSamplingResult recordAndSample
]

{ #category : 'lifecycle' }
OTFailingSampler >> shutdown [

	(self shouldFailOperationNamed: 'shutdown') ifTrue: [ Error signal: 'sampler failure' ].
	^ super shutdown
]

{ #category : 'lifecycle' }
OTFailingSampler >> start [

	(self shouldFailOperationNamed: 'start') ifTrue: [ Error signal: 'sampler failure' ].
	^ super start
]

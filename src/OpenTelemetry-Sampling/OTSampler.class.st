"
I am a component responsible for making decisions about whether or not to sample a trace.
This allows to control the amount of data that is recorded and sent to backends.

My subclasses implement specific sampling strategies.
"
Class {
	#name : 'OTSampler',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Sampling',
	#package : 'OpenTelemetry-Sampling'
}

{ #category : 'private - logging' }
OTSampler class >> compatibilityWarningSink [

	^ OTClassStateStore
		valueAt: #otCompatibilityWarningSink
		forClass: self
		ifAbsent: [ self defaultCompatibilityWarningSink ]
]

{ #category : 'private - logging' }
OTSampler class >> compatibilityWarningSink: aBlock [

	aBlock
		ifNil: [
			OTClassStateStore
				removeValueAt: #otCompatibilityWarningSink
				forClass: self
				ifAbsent: [  ] ]
		ifNotNil: [
			OTClassStateStore
				valueAt: #otCompatibilityWarningSink
				forClass: self
				put: aBlock ].
	^ self compatibilityWarningSink
]

{ #category : 'private - logging' }
OTSampler class >> defaultCompatibilityWarningSink [

	^ OTDiagnosticLogger defaultWarningSink
]

{ #category : 'private - logging' }
OTSampler class >> emittedCompatibilityWarningsBySampler [

	^ OTClassStateStore
		valueAt: #otCompatibilityWarningsBySampler
		forClass: self
		ifAbsent: [
			| warningsBySampler |
			warningsBySampler := WeakIdentityKeyDictionary new.
			OTClassStateStore
				valueAt: #otCompatibilityWarningsBySampler
				forClass: self
				put: warningsBySampler.
			warningsBySampler ]
]

{ #category : 'instance creation' }
OTSampler class >> alwaysRecord: aSampler [
	"Wrap a sampler so DROP becomes RECORD_ONLY while preserving the original sampling rate"

	^ OTAlwaysRecordSampler new rootSampler: aSampler
]

{ #category : 'instance creation' }
OTSampler class >> parentBased [

	^ OTParentBasedSampler default
]

{ #category : 'instance creation' }
OTSampler class >> parentBased: aSampler [

	^ OTParentBasedSampler root: aSampler
]

{ #category : 'instance creation' }
OTSampler class >> probability: aNumber [
	"A consistent probability sampler with a probability between 2^-56 and 1"

	^ OTProbabilisticSampler new probability: aNumber
]

{ #category : 'instance creation' }
OTSampler class >> traceIdRatioBased: aNumber [
	"A deterministic trace-id-ratio sampler with a probability between 0 and 1"

	^ OTTraceIdRatioBasedSampler new probability: aNumber
]

{ #category : 'instance creation' }
OTSampler class >> withInterval: anInteger [
	"A minimum time interval sampler using milliseconds"

	^ OTTimeIntervalSampler new interval: anInteger
]

{ #category : 'instance creation' }
OTSampler class >> withProbability: aNumber [
	"A consistent probability sampler with a probability between 2^-56 and 1"

	^ self probability: aNumber
]

{ #category : 'instance creation' }
OTSampler class >> withRate: anInteger [
	"A fixed-rate sampler with a positive rate"

	^ OTFixedRateSampler new rate: anInteger
]

{ #category : 'private - logging' }
OTSampler class >> noteCompatibilityWarning: aString kind: aSymbol for: aSampler [

	| emittedWarnings |
	emittedWarnings := self
		emittedCompatibilityWarningsBySampler
		at: aSampler
		ifAbsentPut: [ Set new ].
	(emittedWarnings includes: aSymbol) ifTrue: [ ^ false ].
	emittedWarnings add: aSymbol.
	self compatibilityWarningSink value: aString.
	^ true
]

{ #category : 'private - logging' }
OTSampler class >> resetCompatibilityWarningState [

	OTClassStateStore
		removeValueAt: #otCompatibilityWarningsBySampler
		forClass: self
		ifAbsent: [  ].
	OTClassStateStore
		removeValueAt: #otCompatibilityWarningSink
		forClass: self
		ifAbsent: [  ]
]

{ #category : 'accessing' }
OTSampler >> description [

	^ self class name
]

{ #category : 'testing' }
OTSampler >> isShutdown [

	^ false
]

{ #category : 'lifecycle' }
OTSampler >> shutdown [

	^ true
]

{ #category : 'lifecycle' }
OTSampler >> start [

	self
]

{ #category : 'asserting' }
OTSampler >> shouldSample [

	self subclassResponsibility
]

{ #category : 'sampling' }
OTSampler >> shouldSampleIn: aContext traceId: aTraceId name: aString kind: aSpanKind attributes: someAttributes links: someLinks [

	^ self shouldSample
		ifTrue: [ OTSamplingResult recordAndSample ]
		ifFalse: [ OTSamplingResult drop ]
]

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

{ #category : 'instance creation' }
OTSampler class >> alwaysRecord: aSampler [
	"Wrap a sampler so DROP becomes RECORD_ONLY while preserving the original sampling rate"

	^ OTAlwaysRecordSampler new rootSampler: aSampler
]

{ #category : 'private - logging' }
OTSampler class >> compatibilityWarningSink [

	^ self compatibilityWarningStateLock critical: [
		  OTClassStateStore valueAt: #otCompatibilityWarningSink forClass: self ifAbsent: [ self defaultCompatibilityWarningSink ] ]
]

{ #category : 'private - logging' }
OTSampler class >> compatibilityWarningSink: aBlock [

	^ self compatibilityWarningStateLock critical: [
			  aBlock
				  ifNil: [ OTClassStateStore removeValueAt: #otCompatibilityWarningSink forClass: self ifAbsent: [ ] ]
				  ifNotNil: [ OTClassStateStore valueAt: #otCompatibilityWarningSink forClass: self put: aBlock ].
			  OTClassStateStore valueAt: #otCompatibilityWarningSink forClass: self ifAbsent: [ self defaultCompatibilityWarningSink ] ]
]

{ #category : 'private - logging' }
OTSampler class >> compatibilityWarningStateLock [

	^ OTClassStateStore valueAt: #otCompatibilityWarningStateLock forClass: self ifAbsentPut: [ Semaphore forMutualExclusion ]
]

{ #category : 'instance creation' }
OTSampler class >> composite: aComposableSampler [

	^ OTCompositeSampler new delegate: aComposableSampler
]

{ #category : 'private - logging' }
OTSampler class >> defaultCompatibilityWarningSink [

	^ OTDiagnosticLogger defaultWarningSink
]

{ #category : 'private - logging' }
OTSampler class >> emittedCompatibilityWarningsBySampler [

	^ self compatibilityWarningStateLock critical: [
			  OTClassStateStore valueAt: #otCompatibilityWarningsBySampler forClass: self ifAbsent: [
					  | warningsBySampler |
					  warningsBySampler := WeakIdentityKeyDictionary new.
					  OTClassStateStore valueAt: #otCompatibilityWarningsBySampler forClass: self put: warningsBySampler.
					  warningsBySampler ] ]
]

{ #category : 'private - logging' }
OTSampler class >> noteCompatibilityWarning: aString kind: aSymbol for: aSampler [

	| shouldEmit sink |
	shouldEmit := false.
	sink := nil.
	self compatibilityWarningStateLock critical: [
			| emittedWarnings warningsBySampler |
			warningsBySampler := OTClassStateStore valueAt: #otCompatibilityWarningsBySampler forClass: self ifAbsent: [
					                     | warnings |
					                     warnings := WeakIdentityKeyDictionary new.
					                     OTClassStateStore valueAt: #otCompatibilityWarningsBySampler forClass: self put: warnings.
					                     warnings ].
			emittedWarnings := warningsBySampler at: aSampler ifAbsentPut: [ Set new ].
			(emittedWarnings includes: aSymbol) ifFalse: [
					emittedWarnings add: aSymbol.
					shouldEmit := true.
					sink := OTClassStateStore
						        valueAt: #otCompatibilityWarningSink
						        forClass: self
						        ifAbsent: [ self defaultCompatibilityWarningSink ] ] ].
	shouldEmit ifFalse: [ ^ false ].
	sink value: aString.
	^ true
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
OTSampler class >> probabilityOrAlwaysOff: aNumber [
	"A consistent probability sampler with a probability between 0 and 1"

	aNumber = 0 ifTrue: [ ^ OTAlwaysOffSampler new ].
	^ self probability: aNumber
]

{ #category : 'private - logging' }
OTSampler class >> resetCompatibilityWarningState [

	self compatibilityWarningStateLock critical: [
			OTClassStateStore removeValueAt: #otCompatibilityWarningsBySampler forClass: self ifAbsent: [ ].
			OTClassStateStore removeValueAt: #otCompatibilityWarningSink forClass: self ifAbsent: [ ] ]
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

{ #category : 'accessing' }
OTSampler >> description [

	^ self class name
]

{ #category : 'testing' }
OTSampler >> isShutdown [

	^ false
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

{ #category : 'lifecycle' }
OTSampler >> shutdown [

	^ true
]

{ #category : 'lifecycle' }
OTSampler >> start [

	self
]

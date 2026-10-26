"
I am a component responsible for making decisions about whether or not to sample a trace.
This allows to control the amount of data that is recorded and sent to backends.

My subclasses implement specific sampling strategies.
"
Class {
	#name : 'OTSampler',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'instance creation' }
OTSampler class >> alwaysRecord: aSampler [
	"Wrap a sampler so DROP becomes RECORD_ONLY while preserving the original sampling rate"

	^ OTAlwaysRecordSampler new rootSampler: aSampler
]

{ #category : 'private - lifecycle' }
OTSampler class >> beginShutdown: aSampler [

	^ self lifecycleStateLock critical: [
			  | states |
			  states := self shutdownStateBySampler.
			  (states at: aSampler ifAbsent: [ false ]) ifTrue: [ ^ false ].
			  states at: aSampler put: true.
			  true ]
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

{ #category : 'private - lifecycle' }
OTSampler class >> isShutdown: aSampler [

	^ self lifecycleStateLock critical: [ self shutdownStateBySampler at: aSampler ifAbsent: [ false ] ]
]

{ #category : 'private - lifecycle' }
OTSampler class >> lifecycleStateLock [

	^ OTClassStateStore valueAt: #otSamplerLifecycleLock forClass: OTSampler ifAbsentPut: [ Semaphore forMutualExclusion ]
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

{ #category : 'private - lifecycle' }
OTSampler class >> shutdownSamplers: someSamplers [

	^ someSamplers inject: true into: [ :allShutdown :each |
			  | result |
			  result := [ [ each shutdown ] valueWithinMilliseconds: 30000 onTimeout: [ false ] ]
				            on: Error
				            do: [ :error |
						            OTTracerProvider noteSampler: each failedDuring: 'shutdown' error: error.
						            false ].
			  result & allShutdown ]
]

{ #category : 'private - lifecycle' }
OTSampler class >> shutdownStateBySampler [

	^ OTClassStateStore valueAt: #otSamplerShutdownState forClass: OTSampler ifAbsentPut: [ WeakIdentityKeyDictionary new ]
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

{ #category : 'private - lifecycle' }
OTSampler >> beginShutdown [

	^ OTSampler beginShutdown: self
]

{ #category : 'accessing' }
OTSampler >> description [

	^ self class name
]

{ #category : 'testing' }
OTSampler >> isShutdown [

	^ OTSampler isShutdown: self
]

{ #category : 'asserting' }
OTSampler >> shouldSample [

	self isShutdown ifTrue: [ ^ false ].
	self subclassResponsibility
]

{ #category : 'sampling' }
OTSampler >> shouldSampleIn: aContext traceId: aTraceId name: aString kind: aSpanKind attributes: someAttributes links: someLinks [

	self isShutdown ifTrue: [ ^ OTSamplingResult drop ].
	^ self shouldSample
		  ifTrue: [ OTSamplingResult recordAndSample ]
		  ifFalse: [ OTSamplingResult drop ]
]

{ #category : 'lifecycle' }
OTSampler >> shutdown [

	^ self beginShutdown
]

{ #category : 'lifecycle' }
OTSampler >> start [

	self
]

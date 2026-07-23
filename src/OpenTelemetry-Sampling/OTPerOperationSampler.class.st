"
I dispatch sampling decisions by span name, falling back to a default sampler
when no operation-specific sampler is configured.
"
Class {
	#name : 'OTPerOperationSampler',
	#superclass : 'OTSampler',
	#instVars : [
		'defaultSampler',
		'perOperationSamplers'
	],
	#category : 'OpenTelemetry-Sampling',
	#package : 'OpenTelemetry-Sampling'
}

{ #category : 'accessing' }
OTPerOperationSampler >> defaultSampler [

	^ defaultSampler
]

{ #category : 'accessing' }
OTPerOperationSampler >> defaultSampler: anOTSampler [

	anOTSampler ifNil: [ Error signal: 'Per-operation sampler requires a default sampler' ].
	defaultSampler := anOTSampler
]

{ #category : 'accessing' }
OTPerOperationSampler >> description [

	| first |
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'PerOperationSampler{default=';
				  nextPutAll: self defaultSampler description;
				  nextPutAll: ', perOperation={'.
			  first := true.
			  self perOperationSamplers keysAndValuesDo: [ :operationName :sampler |
					  first ifFalse: [ stream nextPutAll: ', ' ].
					  first := false.
					  stream
						  nextPutAll: operationName;
						  nextPut: $=;
						  nextPutAll: sampler description ].
			  stream nextPutAll: '}}' ]
]

{ #category : 'testing' }
OTPerOperationSampler >> hasPerOperationSamplers [

	^ self perOperationSamplers notEmpty
]

{ #category : 'initialization' }
OTPerOperationSampler >> initialize [

	super initialize.
	defaultSampler := OTAlwaysOffSampler new.
	perOperationSamplers := OrderedDictionary new
]

{ #category : 'accessing' }
OTPerOperationSampler >> perOperationSamplers [

	^ perOperationSamplers
]

{ #category : 'accessing' }
OTPerOperationSampler >> perOperationSamplers: aCollection [

	perOperationSamplers := OrderedDictionary new.
	aCollection ifNil: [ ^ perOperationSamplers ].
	aCollection associationsDo: [ :each | perOperationSamplers at: each key asString put: each value ].
	^ perOperationSamplers
]

{ #category : 'private' }
OTPerOperationSampler >> samplerForOperationNamed: aString [

	^ self perOperationSamplers at: (aString ifNil: [ '' ] ifNotNil: [ aString ]) ifAbsent: [ self defaultSampler ]
]

{ #category : 'sampling' }
OTPerOperationSampler >> shouldSampleIn: aContext traceId: aTraceId name: aString kind: aSpanKind attributes: someAttributes links: someLinks [

	^ (self samplerForOperationNamed: aString)
		  shouldSampleIn: aContext
		  traceId: aTraceId
		  name: aString
		  kind: aSpanKind
		  attributes: someAttributes
		  links: someLinks
]

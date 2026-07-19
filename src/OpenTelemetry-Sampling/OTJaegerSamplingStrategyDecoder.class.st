"
I decode Jaeger remote sampling protobuf responses into Pharo sampler objects.
"
Class {
	#name : 'OTJaegerSamplingStrategyDecoder',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Sampling',
	#package : 'OpenTelemetry-Sampling'
}

{ #category : 'private - decoding' }
OTJaegerSamplingStrategyDecoder class >> operationSamplingAssociationFromBytes: aByteArray [

	| operationName probability reader |
	reader := OTProtobufReader on: aByteArray.
	operationName := nil.
	probability := 0.
	[ reader atEnd ] whileFalse: [
		| fieldNumber tag wireType |
		tag := reader readTag.
		fieldNumber := tag first.
		wireType := tag second.
		fieldNumber = 1 ifTrue: [
			wireType = 2
				ifTrue: [ operationName := reader readString ]
				ifFalse: [ reader skipWireType: wireType ] ]
		ifFalse: [
			fieldNumber = 2 ifTrue: [
				wireType = 2
					ifTrue: [
						probability := (self probabilisticSamplerFromBytes: reader readBytes)
							probability ]
					ifFalse: [ reader skipWireType: wireType ] ]
			ifFalse: [ reader skipWireType: wireType ] ] ].
	operationName ifNil: [ ^ nil ].
	^ operationName -> (OTSampler probabilityOrAlwaysOff: probability)
]

{ #category : 'private - decoding' }
OTJaegerSamplingStrategyDecoder class >> perOperationSamplerFromBytes: aByteArray [

	| defaultProbability operationSamplers reader |
	reader := OTProtobufReader on: aByteArray.
	defaultProbability := 0.
	operationSamplers := OrderedDictionary new.
	[ reader atEnd ] whileFalse: [
		| association fieldNumber tag wireType |
		tag := reader readTag.
		fieldNumber := tag first.
		wireType := tag second.
		fieldNumber = 1 ifTrue: [
			wireType = 1
				ifTrue: [ defaultProbability := reader readDouble ]
				ifFalse: [ reader skipWireType: wireType ] ]
		ifFalse: [
			fieldNumber = 3 ifTrue: [
				wireType = 2
					ifTrue: [
						association := self operationSamplingAssociationFromBytes: reader readBytes.
						association ifNotNil: [
							operationSamplers
								at: association key
								put: association value ] ]
					ifFalse: [ reader skipWireType: wireType ] ]
			ifFalse: [ reader skipWireType: wireType ] ] ].
	operationSamplers ifEmpty: [ ^ nil ].
	^ OTPerOperationSampler new
		defaultSampler: (OTSampler probabilityOrAlwaysOff: defaultProbability);
		perOperationSamplers: operationSamplers;
		yourself
]

{ #category : 'private - decoding' }
OTJaegerSamplingStrategyDecoder class >> probabilisticSamplerFromBytes: aByteArray [

	| probability reader |
	reader := OTProtobufReader on: aByteArray.
	probability := 0.
	[ reader atEnd ] whileFalse: [
		| fieldNumber tag wireType |
		tag := reader readTag.
		fieldNumber := tag first.
		wireType := tag second.
		fieldNumber = 1
			ifTrue: [
				wireType = 1
					ifTrue: [ probability := reader readDouble ]
					ifFalse: [ reader skipWireType: wireType ] ]
			ifFalse: [ reader skipWireType: wireType ] ].
	^ OTSampler probabilityOrAlwaysOff: probability
]

{ #category : 'private - decoding' }
OTJaegerSamplingStrategyDecoder class >> rateLimitingSamplerFromBytes: aByteArray [

	| maxTracesPerSecond reader |
	reader := OTProtobufReader on: aByteArray.
	maxTracesPerSecond := 0.
	[ reader atEnd ] whileFalse: [
		| fieldNumber tag wireType |
		tag := reader readTag.
		fieldNumber := tag first.
		wireType := tag second.
		fieldNumber = 1
			ifTrue: [
				wireType = 0
					ifTrue: [ maxTracesPerSecond := reader readVarint ]
					ifFalse: [ reader skipWireType: wireType ] ]
			ifFalse: [ reader skipWireType: wireType ] ].
	^ OTRateLimitingSampler new
		maxTracesPerSecond: maxTracesPerSecond;
		yourself
]

{ #category : 'decoding' }
OTJaegerSamplingStrategyDecoder class >> samplerFromResponseBytes: aByteArray [

	| perOperationSampler probabilisticSampler rateLimitingSampler reader strategyType |
	reader := OTProtobufReader on: aByteArray.
	perOperationSampler := nil.
	probabilisticSampler := nil.
	rateLimitingSampler := nil.
	strategyType := #unrecognized.
	[ reader atEnd ] whileFalse: [
		| fieldNumber tag wireType |
		tag := reader readTag.
		fieldNumber := tag first.
		wireType := tag second.
		fieldNumber = 1 ifTrue: [
			wireType = 0
				ifTrue: [ strategyType := self strategyTypeFromValue: reader readVarint ]
				ifFalse: [ reader skipWireType: wireType ] ]
		ifFalse: [
			fieldNumber = 2 ifTrue: [
				wireType = 2
					ifTrue: [ probabilisticSampler := self probabilisticSamplerFromBytes: reader readBytes ]
					ifFalse: [ reader skipWireType: wireType ] ]
			ifFalse: [
				fieldNumber = 3 ifTrue: [
					wireType = 2
						ifTrue: [ rateLimitingSampler := self rateLimitingSamplerFromBytes: reader readBytes ]
						ifFalse: [ reader skipWireType: wireType ] ]
				ifFalse: [
					fieldNumber = 4 ifTrue: [
						wireType = 2
							ifTrue: [ perOperationSampler := self perOperationSamplerFromBytes: reader readBytes ]
							ifFalse: [ reader skipWireType: wireType ] ]
					ifFalse: [ reader skipWireType: wireType ] ] ] ] ].
	perOperationSampler ifNotNil: [ ^ perOperationSampler ].
	probabilisticSampler ifNotNil: [
		strategyType = #rateLimiting ifFalse: [ ^ probabilisticSampler ] ].
	rateLimitingSampler ifNotNil: [
		strategyType = #probabilistic ifFalse: [ ^ rateLimitingSampler ] ].
	strategyType = #probabilistic ifTrue: [
		^ probabilisticSampler ifNil: [ OTAlwaysOffSampler new ] ].
	strategyType = #rateLimiting ifTrue: [
		^ rateLimitingSampler ifNil: [ OTRateLimitingSampler new ] ].
	Error signal: 'Unsupported Jaeger sampling strategy response'
]

{ #category : 'private - decoding' }
OTJaegerSamplingStrategyDecoder class >> strategyTypeFromValue: anInteger [

	anInteger = 0 ifTrue: [ ^ #probabilistic ].
	anInteger = 1 ifTrue: [ ^ #rateLimiting ].
	^ #unrecognized
]

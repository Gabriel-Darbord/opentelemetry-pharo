"
A customizable SDK-side generator for trace and span identifiers.
"
Class {
	#name : 'OTIdGenerator',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'instance creation' }
OTIdGenerator class >> default [

	^ self new
]

{ #category : 'private' }
OTIdGenerator >> asLowercaseHexFromBytes: aByteArray [

	^ String streamContents: [ :stream |
		  aByteArray do: [ :each | stream nextPutAll: (each printStringBase: 16 length: 2 padded: true) asLowercase ] ]
]

{ #category : 'generating' }
OTIdGenerator >> generateSpanIdBytes [

	^ OTSpanContext byteArrayFromHex: OTSpanContext newSpanId size: 8
]

{ #category : 'generating' }
OTIdGenerator >> generateSpanIdHex [

	^ self asLowercaseHexFromBytes: self generateSpanIdBytes
]

{ #category : 'generating' }
OTIdGenerator >> generateTraceIdBytes [

	^ OTSpanContext byteArrayFromHex: OTSpanContext newTraceId size: 16
]

{ #category : 'generating' }
OTIdGenerator >> generateTraceIdHex [

	^ self asLowercaseHexFromBytes: self generateTraceIdBytes
]

{ #category : 'testing' }
OTIdGenerator >> isRandom [

	^ true
]

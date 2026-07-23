Class {
	#name : 'OTFixedIdGenerator',
	#superclass : 'OTIdGenerator',
	#instVars : [
		'spanIdHex',
		'traceIdHex',
		'random'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'instance creation' }
OTFixedIdGenerator class >> traceIdHex: aTraceIdHex spanIdHex: aSpanIdHex random: aBoolean [

	^ self new
		  traceIdHex: aTraceIdHex;
		  spanIdHex: aSpanIdHex;
		  random: aBoolean;
		  yourself
]

{ #category : 'generating' }
OTFixedIdGenerator >> generateSpanIdBytes [

	^ OTSpanContext byteArrayFromHex: self generateSpanIdHex size: 8
]

{ #category : 'generating' }
OTFixedIdGenerator >> generateSpanIdHex [

	^ spanIdHex
]

{ #category : 'generating' }
OTFixedIdGenerator >> generateTraceIdBytes [

	^ OTSpanContext byteArrayFromHex: self generateTraceIdHex size: 16
]

{ #category : 'generating' }
OTFixedIdGenerator >> generateTraceIdHex [

	^ traceIdHex
]

{ #category : 'testing' }
OTFixedIdGenerator >> isRandom [

	^ random = true
]

{ #category : 'private' }
OTFixedIdGenerator >> random: aBoolean [

	random := aBoolean = true
]

{ #category : 'private' }
OTFixedIdGenerator >> spanIdHex: aString [

	spanIdHex := aString
]

{ #category : 'private' }
OTFixedIdGenerator >> traceIdHex: aString [

	traceIdHex := aString
]

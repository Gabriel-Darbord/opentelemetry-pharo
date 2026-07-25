Class {
	#name : 'OTFakeGRPCMetadata',
	#superclass : 'Object',
	#instVars : [
		'values'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'initialization' }
OTFakeGRPCMetadata >> initialize [

	super initialize.
	values := OrderedDictionary new
]

{ #category : 'accessing' }
OTFakeGRPCMetadata >> addKey: aString value: anotherString [

	values at: aString put: anotherString
]

{ #category : 'accessing' }
OTFakeGRPCMetadata >> valueAt: aString ifAbsent: aBlock [

	^ values at: aString ifAbsent: aBlock
]

{ #category : 'accessing' }
OTFakeGRPCMetadata >> values [

	^ values copy
]

Class {
	#name : 'OTContextKey',
	#superclass : 'Object',
	#instVars : [
		'name'
	],
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'instance creation' }
OTContextKey class >> named: aString [

	^ self new
		  name: aString;
		  yourself
]

{ #category : 'accessing' }
OTContextKey >> name [

	^ name ifNil: [ '' ]
]

{ #category : 'accessing' }
OTContextKey >> name: aString [

	name := aString ifNil: [ '' ] ifNotNil: [ aString asString ].
	^ name
]

{ #category : 'printing' }
OTContextKey >> printOn: aStream [

	aStream
		nextPutAll: 'ContextKey(';
		nextPutAll: self name;
		nextPut: $)
]

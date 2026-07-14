Class {
	#name : 'OTContext',
	#superclass : 'Object',
	#instVars : [
		'currentSpan',
		'baggage',
		'properties'
	],
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'accessing' }
OTContext >> baggage [

	^ baggage
]

{ #category : 'accessing' }
OTContext >> baggage: aBaggage [

	baggage := aBaggage ifNil: [ OTBaggage empty ]
]

{ #category : 'accessing' }
OTContext >> currentSpan [

	^ self span
]

{ #category : 'accessing' }
OTContext >> currentSpan: aSpan [

	self span: aSpan
]

{ #category : 'testing' }
OTContext >> hasBaggage [

	^ self baggage isEmpty not
]

{ #category : 'testing' }
OTContext >> hasProperties [

	^ self properties isEmpty not
]

{ #category : 'testing' }
OTContext >> hasSpan [

	^ self span isNotNil
]

{ #category : 'initialization' }
OTContext >> initialize [

	super initialize.
	currentSpan := nil.
	baggage := OTBaggage empty.
	properties := Dictionary new
]

{ #category : 'testing' }
OTContext >> isEmpty [

	^ self hasSpan not and: [ self hasBaggage not and: [ self hasProperties not ] ]
]

{ #category : 'accessing' }
OTContext >> properties [

	^ properties ifNil: [ Dictionary new ]
]

{ #category : 'private' }
OTContext >> properties: aDictionary [

	properties := aDictionary ifNil: [ Dictionary new ] ifNotNil: [ aDictionary ]
]

{ #category : 'accessing' }
OTContext >> propertyAt: aKey [

	^ self propertyAt: aKey ifAbsent: [ nil ]
]

{ #category : 'accessing' }
OTContext >> propertyAt: aKey ifAbsent: aBlock [

	^ self properties at: aKey ifAbsent: aBlock
]

{ #category : 'accessing' }
OTContext >> span [

	^ currentSpan
]

{ #category : 'accessing' }
OTContext >> span: aSpan [

	currentSpan := aSpan
]

{ #category : 'accessing' }
OTContext >> withBaggage: aBaggage [

	^ self copy
		baggage: aBaggage;
		yourself
]

{ #category : 'accessing' }
OTContext >> withCurrentSpan: aSpan [

	^ self withSpan: aSpan
]

{ #category : 'accessing' }
OTContext >> withPropertyAt: aKey put: aValue [

	| updatedProperties |
	updatedProperties := self properties copy.
	aValue
		ifNil: [ updatedProperties removeKey: aKey ifAbsent: [ ] ]
		ifNotNil: [ updatedProperties at: aKey put: aValue ].
	^ self copy
		properties: updatedProperties;
		yourself
]

{ #category : 'accessing' }
OTContext >> withSpan: aSpan [

	^ self copy
		span: aSpan;
		yourself
]

{ #category : 'accessing' }
OTContext >> withoutBaggage [

	^ self withBaggage: OTBaggage empty
]

{ #category : 'accessing' }
OTContext >> withoutPropertyAt: aKey [

	^ self withPropertyAt: aKey put: nil
]

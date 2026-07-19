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

{ #category : 'instance creation' }
OTContext class >> createKeyNamed: aString [

	^ OTContextKey named: aString
]

{ #category : 'instance creation' }
OTContext class >> keyNamed: aString [

	^ self createKeyNamed: aString
]

{ #category : 'accessing' }
OTContext >> baggage [

	^ baggage
]

{ #category : 'accessing' }
OTContext >> baggage: aBaggage [

	Error signal: 'Use #withBaggage: to derive a new OpenTelemetry context'
]

{ #category : 'accessing' }
OTContext >> currentSpan [

	^ self span
]

{ #category : 'accessing' }
OTContext >> currentSpan: aSpan [

	Error signal: 'Use #withSpan: to derive a new OpenTelemetry context'
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

	^ self valueAt: aKey
]

{ #category : 'accessing' }
OTContext >> propertyAt: aKey ifAbsent: aBlock [

	^ self valueAt: aKey ifAbsent: aBlock
]

{ #category : 'private' }
OTContext >> restoreBaggage: aBaggage [

	baggage := aBaggage ifNil: [ OTBaggage empty ]
]

{ #category : 'private' }
OTContext >> restoreProperties: aDictionary [

	properties := aDictionary ifNil: [ Dictionary new ] ifNotNil: [ aDictionary ]
]

{ #category : 'private' }
OTContext >> restoreSpan: aSpan [

	currentSpan := aSpan
]

{ #category : 'accessing' }
OTContext >> span [

	^ currentSpan
]

{ #category : 'accessing' }
OTContext >> span: aSpan [

	Error signal: 'Use #withSpan: to derive a new OpenTelemetry context'
]

{ #category : 'accessing' }
OTContext >> valueAt: aKey [

	^ self valueAt: aKey ifAbsent: [ nil ]
]

{ #category : 'accessing' }
OTContext >> valueAt: aKey ifAbsent: aBlock [

	^ self properties at: aKey ifAbsent: aBlock
]

{ #category : 'accessing' }
OTContext >> withBaggage: aBaggage [

	^ self copy
		  restoreBaggage: aBaggage;
		  yourself
]

{ #category : 'accessing' }
OTContext >> withCurrentSpan: aSpan [

	^ self withSpan: aSpan
]

{ #category : 'accessing' }
OTContext >> withPropertyAt: aKey put: aValue [

	^ self withValueAt: aKey put: aValue
]

{ #category : 'accessing' }
OTContext >> withSpan: aSpan [

	^ self copy
		  restoreSpan: aSpan;
		  yourself
]

{ #category : 'accessing' }
OTContext >> withValueAt: aKey put: aValue [

	| updatedProperties |
	updatedProperties := self properties copy.
	aValue ifNil: [ updatedProperties removeKey: aKey ifAbsent: [ ] ] ifNotNil: [ updatedProperties at: aKey put: aValue ].
	^ self copy
		  restoreProperties: updatedProperties;
		  yourself
]

{ #category : 'accessing' }
OTContext >> withoutBaggage [

	^ self withBaggage: OTBaggage empty
]

{ #category : 'accessing' }
OTContext >> withoutPropertyAt: aKey [

	^ self withoutValueAt: aKey
]

{ #category : 'accessing' }
OTContext >> withoutValueAt: aKey [

	^ self withValueAt: aKey put: nil
]

"
An immutable resource value associated with telemetry produced by a provider, identified by attributes and an optional schema URL.
"
Class {
	#name : 'OTResource',
	#superclass : 'Object',
	#instVars : [
		'attributes',
		'schemaUrl'
	],
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'instance creation' }
OTResource class >> attributes: aCollection [

	^ self attributes: aCollection schemaUrl: ''
]

{ #category : 'instance creation' }
OTResource class >> attributes: aCollection schemaUrl: aString [

	^ self new
		attributes: (OTAttributeNormalizer normalizeAttributes: aCollection);
		schemaUrl: (aString ifNil: [ '' ] ifNotNil: [ aString ]);
		yourself
]

{ #category : 'instance creation' }
OTResource class >> empty [

	^ self attributes: #() schemaUrl: ''
]

{ #category : 'recording' }
OTResource class >> fromSton: stonReader [

	| representation |
	representation := stonReader parseMap.
	^ self
		attributes: (representation at: #attributes ifAbsent: [ #() ])
		schemaUrl: (representation at: #schemaUrl ifAbsent: [ '' ])
]

{ #category : 'comparing' }
OTResource >> = anObject [

	self == anObject ifTrue: [ ^ true ].
	anObject class == self class ifFalse: [ ^ false ].
	^ self schemaUrl = anObject schemaUrl
		and: [ self attributes = anObject attributes ]
]

{ #category : 'accessing' }
OTResource >> allAttributes [

	^ self attributes copy
]

{ #category : 'accessing' }
OTResource >> attributeAt: aString [

	^ self attributes at: aString ifAbsent: [ nil ]
]

{ #category : 'accessing' }
OTResource >> attributeAt: aString ifAbsent: aBlock [

	^ self attributes at: aString ifAbsent: aBlock
]

{ #category : 'accessing' }
OTResource >> attributes [

	^ attributes ifNil: [ OrderedDictionary new ]
]

{ #category : 'private' }
OTResource >> attributes: aDictionary [

	attributes := aDictionary
]

{ #category : 'comparing' }
OTResource >> hash [

	^ { self schemaUrl. self attributes } hash
]

{ #category : 'testing' }
OTResource >> isEmpty [

	^ self attributes isEmpty and: [ self schemaUrl isEmpty ]
]

{ #category : 'updating' }
OTResource >> merge: anotherResource [

	| oldSchemaUrl newSchemaUrl mergedAttributes mergedSchemaUrl |
	anotherResource ifNil: [ ^ self ].
	mergedAttributes := self allAttributes.
	anotherResource allAttributes associationsDo: [ :each |
		mergedAttributes at: each key put: each value ].
	oldSchemaUrl := self schemaUrl.
	newSchemaUrl := anotherResource schemaUrl.
	mergedSchemaUrl := oldSchemaUrl isEmpty
		ifTrue: [ newSchemaUrl ]
		ifFalse: [ newSchemaUrl isEmpty
			ifTrue: [ oldSchemaUrl ]
			ifFalse: [ oldSchemaUrl = newSchemaUrl
				ifTrue: [ oldSchemaUrl ]
				ifFalse: [ Error signal: 'Cannot merge resources with different schema URLs' ] ] ].
	^ self class attributes: mergedAttributes schemaUrl: mergedSchemaUrl
]

{ #category : 'accessing' }
OTResource >> schemaUrl [

	^ schemaUrl ifNil: [ '' ]
]

{ #category : 'private' }
OTResource >> schemaUrl: aString [

	schemaUrl := aString
]

{ #category : 'accessing' }
OTResource >> serviceName [

	^ self attributeAt: 'service.name'
]

{ #category : 'ston persistence' }
OTResource >> stonOn: stonWriter [

	stonWriter writeObject: self streamMap: [ :map |
		map at: #attributes put: self attributes.
		self schemaUrl ifNotEmpty: [ map at: #schemaUrl put: self schemaUrl ] ]
]

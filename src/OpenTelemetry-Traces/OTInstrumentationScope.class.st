"
A spec-shaped instrumentation scope identified by the tuple (name, version, schemaUrl, attributes).
"
Class {
	#name : 'OTInstrumentationScope',
	#superclass : 'Object',
	#instVars : [
		'name',
		'version',
		'schemaUrl',
		'attributes'
	],
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'instance creation' }
OTInstrumentationScope class >> attributes: aCollection [

	^ self
		  named: ''
		  version: ''
		  schemaUrl: ''
		  attributes: aCollection
]

{ #category : 'ston persistence' }
OTInstrumentationScope class >> fromSton: stonReader [

	| representation |
	representation := stonReader parseMap.
	^ self
		  named: (representation at: #name ifAbsent: [ '' ])
		  version: (representation at: #version ifAbsent: [ '' ])
		  schemaUrl: (representation at: #schemaUrl ifAbsent: [ '' ])
		  attributes: (representation at: #attributes ifAbsent: [ #(  ) ])
]

{ #category : 'instance creation' }
OTInstrumentationScope class >> named: aString [

	^ self
		  named: aString
		  version: ''
		  schemaUrl: ''
		  attributes: #(  )
]

{ #category : 'instance creation' }
OTInstrumentationScope class >> named: aString version: aVersionString [

	^ self
		  named: aString
		  version: aVersionString
		  schemaUrl: ''
		  attributes: #(  )
]

{ #category : 'instance creation' }
OTInstrumentationScope class >> named: aString version: aVersionString schemaUrl: aSchemaUrlString attributes: aCollection [

	| scope |
	scope := self new.
	scope
		name: (aString ifNil: [ '' ] ifNotNil: [ aString ]);
		version: (aVersionString ifNil: [ '' ] ifNotNil: [ aVersionString ]);
		schemaUrl: (aSchemaUrlString ifNil: [ '' ] ifNotNil: [ aSchemaUrlString ]);
		attributes: aCollection.
	^ scope
]

{ #category : 'comparing' }
OTInstrumentationScope >> = anObject [

	self == anObject ifTrue: [ ^ true ].
	anObject class = self class ifFalse: [ ^ false ].
	^ self name = anObject name and: [
		  self version = anObject version and: [ self schemaUrl = anObject schemaUrl and: [ self attributes = anObject attributes ] ] ]
]

{ #category : 'accessing' }
OTInstrumentationScope >> allAttributes [

	^ self attributes copy
]

{ #category : 'accessing' }
OTInstrumentationScope >> attributeAt: aKey [

	^ self attributeAt: aKey ifAbsent: [ nil ]
]

{ #category : 'accessing' }
OTInstrumentationScope >> attributeAt: aKey ifAbsent: aBlock [

	^ self attributes at: aKey ifAbsent: aBlock
]

{ #category : 'accessing' }
OTInstrumentationScope >> attributes [

	^ attributes ifNil: [ OrderedDictionary new ]
]

{ #category : 'accessing' }
OTInstrumentationScope >> attributes: aCollection [

	attributes := [ OTAttributeNormalizer normalizeAttributes: aCollection ]
		              on: Error
		              do: [ OrderedDictionary new ].
	self
]

{ #category : 'comparing' }
OTInstrumentationScope >> hash [

	^ {
		  self name.
		  self version.
		  self schemaUrl.
		  self attributes } hash
]

{ #category : 'testing' }
OTInstrumentationScope >> isEmpty [

	^ self name isEmpty and: [ self version isEmpty and: [ self schemaUrl isEmpty and: [ self attributes isEmpty ] ] ]
]

{ #category : 'accessing' }
OTInstrumentationScope >> name [

	^ name ifNil: [ '' ]
]

{ #category : 'accessing' }
OTInstrumentationScope >> name: aString [

	name := aString ifNil: [ '' ] ifNotNil: [ aString asString ].
	self
]

{ #category : 'printing' }
OTInstrumentationScope >> printOn: aStream [

	aStream nextPutAll: 'InstrumentationScope['.
	aStream nextPutAll: self name.
	self version ifNotEmpty: [
			aStream
				nextPutAll: '@';
				nextPutAll: self version ].
	aStream nextPut: $]
]

{ #category : 'accessing' }
OTInstrumentationScope >> schemaUrl [

	^ schemaUrl ifNil: [ '' ]
]

{ #category : 'accessing' }
OTInstrumentationScope >> schemaUrl: aString [

	schemaUrl := aString ifNil: [ '' ] ifNotNil: [ aString asString ].
	self
]

{ #category : 'ston persistence' }
OTInstrumentationScope >> stonOn: stonWriter [

	stonWriter writeObject: self streamMap: [ :map |
			map at: #name put: self name.
			self version ifNotEmpty: [ map at: #version put: self version ].
			self schemaUrl ifNotEmpty: [ map at: #schemaUrl put: self schemaUrl ].
			self attributes ifNotEmpty: [ map at: #attributes put: self attributes ] ]
]

{ #category : 'accessing' }
OTInstrumentationScope >> version [

	^ version ifNil: [ '' ]
]

{ #category : 'accessing' }
OTInstrumentationScope >> version: aString [

	version := aString ifNil: [ '' ] ifNotNil: [ aString asString ].
	self
]

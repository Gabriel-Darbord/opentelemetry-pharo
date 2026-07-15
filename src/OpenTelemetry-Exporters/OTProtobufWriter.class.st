"
A minimal protobuf wire-format writer for OTLP trace payloads.
"
Class {
	#name : 'OTProtobufWriter',
	#superclass : 'Object',
	#instVars : [
		'stream'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'instance creation' }
OTProtobufWriter class >> on: aWriteStream [

	^ self new
		stream: aWriteStream;
		yourself
]

{ #category : 'instance creation' }
OTProtobufWriter class >> withBytes [

	^ self on: (WriteStream on: ByteArray new)
]

{ #category : 'accessing' }
OTProtobufWriter >> contents [

	^ stream contents
]

{ #category : 'private - writing' }
OTProtobufWriter >> nextPutByte: anInteger [

	stream nextPut: anInteger
]

{ #category : 'accessing' }
OTProtobufWriter >> stream: aWriteStream [

	stream := aWriteStream
]

{ #category : 'private - writing' }
OTProtobufWriter >> writeBytes: aByteArray [

	self writeVarint: aByteArray size.
	stream nextPutAll: aByteArray
]

{ #category : 'private - writing' }
OTProtobufWriter >> writeDouble: aNumber [

	self writeFixed64: aNumber asFloat asIEEE64BitWord
]

{ #category : 'private - writing' }
OTProtobufWriter >> writeEmbedded: aBlock [

	| embedded |
	embedded := self class withBytes.
	aBlock value: embedded.
	self writeBytes: embedded contents
]

{ #category : 'private - writing' }
OTProtobufWriter >> writeFixed32: anInteger [

	| value |
	value := anInteger.
	4 timesRepeat: [
		self nextPutByte: (value bitAnd: 16rFF).
		value := value bitShift: -8 ]
]

{ #category : 'private - writing' }
OTProtobufWriter >> writeFixed64: anInteger [

	| value |
	value := anInteger.
	8 timesRepeat: [
		self nextPutByte: (value bitAnd: 16rFF).
		value := value bitShift: -8 ]
]

{ #category : 'private - writing' }
OTProtobufWriter >> writeString: aString [

	self writeBytes: aString utf8Encoded
]

{ #category : 'private - writing' }
OTProtobufWriter >> writeTag: aFieldNumber wireType: aWireTypeInteger [

	self writeVarint: ((aFieldNumber bitShift: 3) bitOr: aWireTypeInteger)
]

{ #category : 'private - writing' }
OTProtobufWriter >> writeVarint: anInteger [

	| value |
	value := anInteger.
	value < 0 ifTrue: [ value := (1 bitShift: 64) + value ].
	[ value >= 16r80 ] whileTrue: [
		self nextPutByte: ((value bitAnd: 16r7F) bitOr: 16r80).
		value := value bitShift: -7 ].
	self nextPutByte: value
]

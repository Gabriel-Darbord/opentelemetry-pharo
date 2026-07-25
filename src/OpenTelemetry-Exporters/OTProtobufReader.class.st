"
A minimal protobuf wire-format reader for OTLP trace payloads and responses.
"
Class {
	#name : 'OTProtobufReader',
	#superclass : 'Object',
	#instVars : [
		'bytes',
		'position'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'instance creation' }
OTProtobufReader class >> on: aByteArray [

	^ self new
		  bytes: aByteArray;
		  yourself
]

{ #category : 'testing' }
OTProtobufReader >> atEnd [

	^ position > bytes size
]

{ #category : 'accessing' }
OTProtobufReader >> bytes: aByteArray [

	bytes := aByteArray ifNil: [ #[  ] ] ifNotNil: [ aByteArray ].
	position := 1
]

{ #category : 'private - reading' }
OTProtobufReader >> nextByte [

	| value |
	value := bytes at: position.
	position := position + 1.
	^ value
]

{ #category : 'private - reading' }
OTProtobufReader >> readBytes [

	| end length result start |
	length := self readVarint.
	start := position.
	end := start + length - 1.
	result := length = 0
		          ifTrue: [ #[  ] ]
		          ifFalse: [ bytes copyFrom: start to: end ].
	position := end + 1.
	^ result
]

{ #category : 'private - reading' }
OTProtobufReader >> readDouble [

	^ Float fromIEEE64Bit: self readFixed64
]

{ #category : 'private - reading' }
OTProtobufReader >> readFixed32 [

	| shift value |
	value := 0.
	shift := 0.
	4 timesRepeat: [
			value := value bitOr: (self nextByte bitShift: shift).
			shift := shift + 8 ].
	^ value
]

{ #category : 'private - reading' }
OTProtobufReader >> readFixed64 [

	| shift value |
	value := 0.
	shift := 0.
	8 timesRepeat: [
			value := value bitOr: (self nextByte bitShift: shift).
			shift := shift + 8 ].
	^ value
]

{ #category : 'private - reading' }
OTProtobufReader >> readString [

	^ self readBytes asString
]

{ #category : 'private - reading' }
OTProtobufReader >> readTag [

	| tag |
	tag := self readVarint.
	^ {
		  (tag bitShift: -3).
		  (tag bitAnd: 7) }
]

{ #category : 'private - reading' }
OTProtobufReader >> readVarint [

	| byte result shift |
	result := 0.
	shift := 0.
	[
		byte := self nextByte.
		result := result bitOr: ((byte bitAnd: 16r7F) bitShift: shift).
		(byte bitAnd: 16r80) = 0 ] whileFalse: [ shift := shift + 7 ].
	^ result
]

{ #category : 'private - reading' }
OTProtobufReader >> skipWireType: aWireTypeInteger [

	aWireTypeInteger = 0 ifTrue: [
			self readVarint.
			^ self ].
	aWireTypeInteger = 1 ifTrue: [
			position := position + 8.
			^ self ].
	aWireTypeInteger = 2 ifTrue: [
			position := position + self readVarint.
			^ self ].
	aWireTypeInteger = 5 ifTrue: [
			position := position + 4.
			^ self ].
	Error signal: 'Unsupported protobuf wire type: ' , aWireTypeInteger asString
]

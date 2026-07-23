"
A standard-output exporter intended for debugging and learning purposes.
Its output format is intentionally unspecified.
"
Class {
	#name : 'OTConsoleLogRecordExporter',
	#superclass : 'OTLogRecordExporter',
	#instVars : [
		'outputStreamBlock'
	],
	#category : 'OpenTelemetry-Logs',
	#package : 'OpenTelemetry-Logs'
}

{ #category : 'exporting' }
OTConsoleLogRecordExporter >> export: someLogRecords [

	| stream |
	stream := self outputStream.
	someLogRecords do: [ :each |
			stream
				nextPutAll: (self formattedLogRecord: each);
				lf ].
	^ true
]

{ #category : 'private' }
OTConsoleLogRecordExporter >> formattedLogRecord: anOTLogRecord [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: '[';
				  nextPutAll: anOTLogRecord observedTimestamp printString;
				  nextPutAll: '] '.
			  anOTLogRecord severityText ifNotNil: [ :value | stream nextPutAll: value ] ifNil: [
					  anOTLogRecord severityNumber = OTSeverity undefined ifFalse: [
						  stream nextPutAll: (OTSeverity shortNameFor: anOTLogRecord severityNumber) ] ].
			  anOTLogRecord eventName ifNotNil: [ :value |
					  stream
						  nextPutAll: ' {';
						  nextPutAll: value;
						  nextPut: $} ].
			  anOTLogRecord body ifNotNil: [
					  stream
						  nextPutAll: ': ';
						  nextPutAll: anOTLogRecord body printString ].
			  anOTLogRecord attributes ifNotEmpty: [
					  stream
						  nextPutAll: ' attributes=';
						  nextPutAll: anOTLogRecord attributes printString ] ]
]

{ #category : 'accessing' }
OTConsoleLogRecordExporter >> outputStream [

	^ outputStreamBlock ifNil: [ Stdio stdout ] ifNotNil: [ outputStreamBlock value ]
]

{ #category : 'accessing' }
OTConsoleLogRecordExporter >> outputStream: anObject [

	outputStreamBlock := anObject isBlock
		                     ifTrue: [ anObject ]
		                     ifFalse: [ [ anObject ] ].
	^ anObject
]

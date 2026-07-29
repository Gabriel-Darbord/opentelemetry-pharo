"
I centralize cross-signal OTLP exporter support logic that does not belong to a
single trace, log, or metric implementation.
"
Class {
	#name : 'OTOtlpExportSupport',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'messages' }
OTOtlpExportSupport class >> invalidSuccessResponseMessageForSignal: aString transport: transportName error: anError [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'OpenTelemetry OTLP ';
				  nextPutAll: aString;
				  nextPutAll: ' export returned an invalid ';
				  nextPutAll: transportName;
				  nextPutAll: ' success response: ';
				  nextPutAll: anError messageText ]
]

{ #category : 'messages' }
OTOtlpExportSupport class >> partialSuccessMessageForSignal: aString details: anObject [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'OpenTelemetry OTLP ';
				  nextPutAll: aString;
				  nextPutAll: ' export reported partial success: ';
				  print: anObject ]
]

{ #category : 'messages' }
OTOtlpExportSupport class >> payloadEncodingFailureMessageForSignal: aString transport: transportName error: anError [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'OpenTelemetry OTLP ';
				  nextPutAll: aString;
				  nextPutAll: ' export failed to encode ';
				  nextPutAll: transportName;
				  nextPutAll: ' payload: ';
				  nextPutAll: anError messageText ]
]

{ #category : 'messages' }
OTOtlpExportSupport class >> retryExhaustedForGrpcStatusMessageForSignal: aString status: aStatus [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'OpenTelemetry OTLP ';
				  nextPutAll: aString;
				  nextPutAll: ' export exhausted retries after gRPC status ';
				  nextPutAll: aStatus codeName;
				  nextPutAll: ' (';
				  print: aStatus code;
				  nextPut: $) ]
]

{ #category : 'messages' }
OTOtlpExportSupport class >> retryExhaustedForHttpStatusMessageForSignal: aString code: anInteger [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'OpenTelemetry OTLP ';
				  nextPutAll: aString;
				  nextPutAll: ' export exhausted retries after HTTP status ';
				  print: anInteger ]
]

{ #category : 'messages' }
OTOtlpExportSupport class >> retryExhaustedForTransportErrorMessageForSignal: aString error: anError [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'OpenTelemetry OTLP ';
				  nextPutAll: aString;
				  nextPutAll: ' export exhausted retries after a retryable transport failure: ';
				  nextPutAll: anError messageText ]
]

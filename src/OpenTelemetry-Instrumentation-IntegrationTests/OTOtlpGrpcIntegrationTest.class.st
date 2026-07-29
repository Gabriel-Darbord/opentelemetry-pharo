Class {
	#name : 'OTOtlpGrpcIntegrationTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-IntegrationTests',
	#package : 'OpenTelemetry-Instrumentation-IntegrationTests'
}

{ #category : 'private' }
OTOtlpGrpcIntegrationTest >> collectorEndpoint [

	^ self environmentValueAt: 'OTEL_PHARO_OTLP_GRPC_INTEGRATION_ENDPOINT' ifAbsent: [ 'http://127.0.0.1:4317' ]
]

{ #category : 'private' }
OTOtlpGrpcIntegrationTest >> collectorOutputFileEnvironmentKeyForSignalNamed: aString [

	aString = 'TRACES' ifTrue: [ ^ 'OTEL_PHARO_OTLP_GRPC_INTEGRATION_TRACE_OUTPUT_FILE' ].
	aString = 'LOGS' ifTrue: [ ^ 'OTEL_PHARO_OTLP_GRPC_INTEGRATION_LOG_OUTPUT_FILE' ].
	aString = 'METRICS' ifTrue: [ ^ 'OTEL_PHARO_OTLP_GRPC_INTEGRATION_METRIC_OUTPUT_FILE' ].
	self error: 'Unsupported OTLP/gRPC integration signal: ' , aString printString
]

{ #category : 'private' }
OTOtlpGrpcIntegrationTest >> collectorOutputFileForSignalNamed: aString [

	| path |
	path := self environmentValueAt: (self collectorOutputFileEnvironmentKeyForSignalNamed: aString) ifAbsent: [
			        aString = 'TRACES'
				        ifTrue: [ self environmentValueAt: 'OTEL_PHARO_OTLP_GRPC_INTEGRATION_OUTPUT_FILE' ifAbsent: [ nil ] ]
				        ifFalse: [ nil ] ].
	^ path ifNotNil: [ path asFileReference ]
]

{ #category : 'private' }
OTOtlpGrpcIntegrationTest >> environmentValueAt: aKey ifAbsent: aBlock [

	| environment value |
	environment := Smalltalk os environment.
	value := environment at: aKey ifAbsent: [ ^ aBlock value ].
	value := value asString trimBoth.
	^ value isEmpty
		  ifTrue: [ aBlock value ]
		  ifFalse: [ value ]
]

{ #category : 'private' }
OTOtlpGrpcIntegrationTest >> integrationEnabled [

	| value |
	value := self environmentValueAt: 'OTEL_PHARO_OTLP_GRPC_INTEGRATION_ENABLED' ifAbsent: [ ^ false ].
	value := value asLowercase.
	^ #( '1' 'true' 'yes' 'on' ) includes: value
]

{ #category : 'private' }
OTOtlpGrpcIntegrationTest >> waitForCollectorOutputFile: aFileReference toContainAll: someStrings timeoutSeconds: anInteger [

	| deadlineMillis |
	deadlineMillis := Time millisecondClockValue + (anInteger * 1000).
	[ Time millisecondClockValue <= deadlineMillis ] whileTrue: [
			| contents |
			contents := aFileReference exists
				            ifTrue: [
						            [ aFileReference contents ]
							            on: Error
							            do: [ '' ] ]
				            ifFalse: [ '' ].
			(someStrings allSatisfy: [ :each | contents includesSubstring: each ]) ifTrue: [ ^ true ].
			(Delay forMilliseconds: 100) wait ].
	^ false
]

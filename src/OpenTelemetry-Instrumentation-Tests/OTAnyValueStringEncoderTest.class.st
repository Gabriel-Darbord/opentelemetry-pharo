Class {
	#name : 'OTAnyValueStringEncoderTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'tests' }
OTAnyValueStringEncoderTest >> testConsoleAttributesAreAJsonObject [

	| record line marker |
	record := OTLogRecord new
		          attributes: {
				          ('count' -> 12).
				          ('flag' -> true) };
		          yourself.
	line := OTConsoleLogRecordExporter new formattedLogRecord: record.
	marker := ' attributes='.
	self
		assert: (STONJSON fromString: (line copyFrom: (line findString: marker) + marker size to: line size))
		equals: (Dictionary new
				 at: 'count' put: 12;
				 at: 'flag' put: true;
				 yourself)
]

{ #category : 'tests' }
OTAnyValueStringEncoderTest >> testNestedCollectionsRemainJsonValuesAcrossExporters [

	| value expected |
	value := Dictionary new
		         at: 'values' put: {
				         3.
				         true.
				         nil.
				         'hello' utf8Encoded.
				         Float infinity.
				         Float negativeInfinity.
				         Float nan };
		         yourself.
	expected := Dictionary new
		            at: 'values' put: #( 3 true nil 'aGVsbG8=' 'Infinity' '-Infinity' 'NaN' );
		            yourself.
	self assert: (STONJSON fromString: (OTAnyValueStringEncoder stringFor: value)) equals: expected.
	self assert: (STONJSON fromString: (OTZipkinSpanExporter new tagStringFor: value)) equals: expected.
	self assert: (STONJSON fromString: (OTPrometheusTextEncoder new prometheusStringValueFor: value)) equals: expected.
	self assert: (OTAnyValueStringEncoder stringFor: Dictionary new) equals: '{}'.
	self assert: (OTAnyValueStringEncoder stringFor: #(  )) equals: '[]'
]

{ #category : 'tests' }
OTAnyValueStringEncoderTest >> testScalarRepresentationDoesNotAddJsonQuotes [

	self assert: (OTAnyValueStringEncoder stringFor: 'hello') equals: 'hello'.
	self assert: (OTAnyValueStringEncoder stringFor: 'hello' utf8Encoded) equals: 'aGVsbG8='.
	self assert: (OTAnyValueStringEncoder stringFor: nil) equals: ''.
	self assert: (OTAnyValueStringEncoder stringFor: true) equals: 'true'.
	self assert: (OTAnyValueStringEncoder stringFor: 123) equals: '123'.
	self assert: (OTAnyValueStringEncoder stringFor: Float nan) equals: 'NaN'.
	self assert: (OTAnyValueStringEncoder stringFor: Float infinity) equals: 'Infinity'.
	self assert: (OTAnyValueStringEncoder stringFor: Float negativeInfinity) equals: '-Infinity'
]

{ #category : 'tests' }
OTAnyValueStringEncoderTest >> testZipkinAnnotationEscapesTheNameAndPreservesAttributeTypes [

	| attributes event annotation decoded |
	attributes := {
		              ('number' -> 12).
		              ('nested' -> (Dictionary new
			                at: 'bytes' put: 'hello' utf8Encoded;
			                yourself)) }.
	event := OTSpanEvent named: 'quoted"event' attributes: attributes timestamp: DateAndTime unixEpoch.
	annotation := OTZipkinSpanExporter new annotationValueFor: event.
	decoded := STONJSON fromString: '{' , annotation , '}'.
	self assert: ((decoded at: 'quoted"event') at: 'number') equals: 12.
	self assert: (((decoded at: 'quoted"event') at: 'nested') at: 'bytes') equals: 'aGVsbG8='
]

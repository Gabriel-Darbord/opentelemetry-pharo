"
I am an exporter specifically for the [Zipkin](https://zipkin.io/) distributed tracing system.
"
Class {
	#name : #OTZipkinSpanExporter,
	#superclass : #OTSpanExporter,
	#instVars : [
		'httpClient'
	],
	#category : 'OpenTelemetry-Exporters'
}

{ #category : #exporting }
OTZipkinSpanExporter >> export: spans [

	^ (self httpClient
		   contents: (self transform: spans);
		   execute;
		   response) code = 202
]

{ #category : #accessing }
OTZipkinSpanExporter >> httpClient [

	^ httpClient ifNil: [
		  | writer |
		  writer := ZnUtils defaultJSONWriter.
		  httpClient := ZnClient new
			                http;
			                method: #POST;
			                accept: ZnMimeType applicationJson;
			                addPathSegment: 'api';
			                addPathSegment: 'v2';
			                addPathSegment: 'spans';
			                contentWriter: [ :data |
				                ZnEntity json: (writer toString: data) ] ]
]

{ #category : #accessing }
OTZipkinSpanExporter >> transform: spans [
	"Transform OpenTelemetry spans into the Zipkin format following the rules at https://opentelemetry.io/docs/specs/otel/trace/sdk_exporters/zipkin/"

	^ spans collect: [ :span |
		  | data |
		  data := Dictionary new.
		  data
			  at: 'traceId' put: span traceId printBits;
			  at: 'id' put: span spanId printMostSignificantBits;
			  at: 'name' put: span name;
			  at: 'timestamp' put: span startTime asUnixMicroseconds;
			  at: 'duration'
			  put: (span endTime - span startTime) asMicroseconds.
		  span parent ifNotNil: [ :parent |
			  data at: 'parentId' put: parent spanId printMostSignificantBits ].
		  span kind ifNotNil: [ :kind |
			  kind = OTSpan internal ifFalse: [ data at: 'kind' put: kind ] ].
		  "events -> annotations"
		  span events ifNotNil: [ :events |
			  data at: 'annotations' put: events ].
		  "attributes -> tags"
		  span attributes ifNotNil: [ :attributes |
			  attributes ifNotEmpty: [ data at: 'tags' put: attributes copy ] ].
		  "status added to tags"
		  span status ifNotNil: [ :status |
			  data at: 'tags' at: 'otel.statusCode' put: status ].
		  "local endpoint: service name and ip (TODO)"
		  data
			  at: 'localEndpoint'
			  at: 'serviceName'
			  put: span instrumentationName.
		  data ]
]

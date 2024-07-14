"
I am an exporter specifically for the [Zipkin](https://zipkin.io/) distributed tracing system.
"
Class {
	#name : 'OTZipkinSpanExporter',
	#superclass : 'OTSpanExporter',
	#instVars : [
		'httpClient'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'exporting' }
OTZipkinSpanExporter >> export: spans [

	^ (self httpClient
		   contents: (self transform: spans);
		   execute;
		   response) code = 202
]

{ #category : 'accessing' }
OTZipkinSpanExporter >> httpClient [
	"Configured to localhost:9411 by default."

	^ httpClient ifNil: [
		  (httpClient := ZnClient new)
			  http;
			  host: 'localhost';
			  port: 9411;
			  addPathSegment: 'api';
			  addPathSegment: 'v2';
			  addPathSegment: 'spans';
			  method: #POST;
			  accept: ZnMimeType applicationJson;
			  contentWriter: [ :data |
				  ZnEntity json: (ZnUtils defaultJSONWriter toString: data) ] ]
]

{ #category : 'private - utilities' }
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

Extension { #name : 'ZnClient' }

{ #category : '*OpenTelemetry-Exporters' }
ZnClient >> removeHeaderNamed: aKey [

	request headers removeKey: aKey ifAbsent: [ ]
]

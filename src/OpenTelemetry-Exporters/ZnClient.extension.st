Extension { #name : 'ZnClient' }

{ #category : '*OpenTelemetry-Exporters' }
ZnClient >> responseContents [

	| responseEntity |
	responseEntity := self entity.
	responseEntity ifNil: [ ^ nil ].
	^ responseEntity contents
]

{ #category : '*OpenTelemetry-Exporters' }
ZnClient >> responseHeaderAt: aKey ifAbsent: aBlock [

	| httpResponse |
	httpResponse := self response.
	httpResponse ifNil: [ ^ aBlock value ].
	^ httpResponse headers at: aKey ifAbsent: aBlock
]

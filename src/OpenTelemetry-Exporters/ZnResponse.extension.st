Extension { #name : 'ZnResponse' }

{ #category : '*OpenTelemetry-Exporters' }
ZnResponse >> responseContents [

	| responseEntity |
	responseEntity := self entity.
	responseEntity ifNil: [ ^ nil ].
	^ responseEntity contents
]

{ #category : '*OpenTelemetry-Exporters' }
ZnResponse >> responseHeaderAt: aKey ifAbsent: aBlock [

	^ self headers at: aKey ifAbsent: aBlock
]

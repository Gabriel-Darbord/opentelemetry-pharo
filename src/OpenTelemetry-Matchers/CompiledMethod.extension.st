Extension { #name : 'CompiledMethod' }

{ #category : '*OpenTelemetry-Matchers' }
CompiledMethod >> otName [

	^ self selector
]

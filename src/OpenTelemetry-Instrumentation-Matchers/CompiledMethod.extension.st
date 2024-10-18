Extension { #name : 'CompiledMethod' }

{ #category : '*OpenTelemetry-Instrumentation-Matchers' }
CompiledMethod >> otName [

	^ self selector
]

Extension { #name : 'CompiledMethod' }

{ #category : '*OpenTelemetry-Instrumentation' }
CompiledMethod >> otName [

	^ self selector
]

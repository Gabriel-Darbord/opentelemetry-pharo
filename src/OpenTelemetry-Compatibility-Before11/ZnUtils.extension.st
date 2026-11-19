Extension { #name : 'ZnUtils' }

{ #category : '*OpenTelemetry-Compatibility-Before11' }
ZnUtils class >> defaultJSONWriter [
	"The JSON writer Zinc uses for REST entities, as Pharo 11 answers it: NeoJSONWriter when present, STONJSON otherwise."

	^ self class environment
		  at: #NeoJSONWriter
		  ifAbsent: [ self class environment at: #STONJSON ifAbsent: [ self error: 'Could not find a suitable JSON writer' ] ]
]

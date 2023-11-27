Extension { #name : #UUID }

{ #category : #'*OpenTelemetry-Exporters' }
UUID >> printBits [
	"Return a String representing my bits without hyphens"

	^ String new: 32 streamContents: [ :stringStream |
		  1 to: 16 do: [ :i |
		  (self at: i) printLowercaseHexByteOn: stringStream ] ]
]

{ #category : #'*OpenTelemetry-Exporters' }
UUID >> printMostSignificantBits [
	"Return a String representing my most significant bits without hyphens"

	^ String new: 16 streamContents: [ :stringStream |
		  1 to: 8 do: [ :i |
		  (self at: i) printLowercaseHexByteOn: stringStream ] ]
]

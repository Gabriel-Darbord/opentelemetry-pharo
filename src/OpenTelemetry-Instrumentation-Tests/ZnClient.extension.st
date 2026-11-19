Extension { #name : 'ZnClient' }

{ #category : '*OpenTelemetry-Instrumentation-Tests' }
ZnClient >> otSocketStreamTimeout [
	"The socket stream timeout this client was given. Zinc keeps it as the socketStreamTimeout option where it has one, which timeout: writes there, while Pharo 15's timeout still reads the option it replaced."

	^ (ZnOptions globalDefault includesKey: #socketStreamTimeout)
		  ifTrue: [ self localOptions at: #socketStreamTimeout ]
		  ifFalse: [ self timeout ]
]

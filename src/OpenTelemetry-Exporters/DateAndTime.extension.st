Extension { #name : #DateAndTime }

{ #category : #'*OpenTelemetry-Exporters' }
DateAndTime >> asUnixMicroseconds [
	"answer number of microseconds since unix epoch (midnight Jan 1, 1970, UTC)"

	^ ((self offset: Duration zero) - self class unixEpoch)
		  asMicroseconds
]

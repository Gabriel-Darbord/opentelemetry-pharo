Extension { #name : 'Semaphore' }

{ #category : '*OpenTelemetry-Compatibility-Before12' }
Semaphore >> waitTimeoutMilliseconds: anInteger [
	"Wait on this semaphore for up to the given number of milliseconds, then timeout. Answer true if the deadline expired, false otherwise. Pharo 12 renamed waitTimeoutMSecs: to this."

	^ self waitTimeoutMSecs: anInteger
]

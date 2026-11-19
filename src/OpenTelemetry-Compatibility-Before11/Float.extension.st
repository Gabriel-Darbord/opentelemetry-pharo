Extension { #name : 'Float' }

{ #category : '*OpenTelemetry-Compatibility-Before11' }
Float >> asIEEE64BitWord [
	"Answer the 64-bit integer holding the receiver in IEEE 754 double format, as Pharo 11 does."

	^ ((self basicAt: 1) bitShift: 32) + (self basicAt: 2)
]

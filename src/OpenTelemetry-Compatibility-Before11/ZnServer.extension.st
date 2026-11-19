Extension { #name : 'ZnServer' }

{ #category : '*OpenTelemetry-Compatibility-Before11' }
ZnServer class >> withOSAssignedPortDo: block [
	"Create and start a new server on a port the OS assigns, pass it to block, and stop it afterwards, as Pharo 11 does."

	| server |
	server := self on: 0.
	[
		server start.
		self assert: server isRunning & server isListening.
		block cull: server ] ensure: [ server stop ]
]

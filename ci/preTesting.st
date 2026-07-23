TestCase
	compile:
		'runCase
	self resources do: [ :each | each availableFor: self ].
	[
		| previousDiagnosticLogger |
		[
			previousDiagnosticLogger := nil.
			((self class package name beginsWith: ''OpenTelemetry-'')
				and: [ self class ~= OTDiagnosticLoggerTest ])
				ifTrue: [
					previousDiagnosticLogger := OTDiagnosticLogger current.
					OTDiagnosticLogger current: (OTDiagnosticLogger onMessageDo: [ :severity :message | ]) ].
			self setUp.
			previousDiagnosticLogger ifNotNil: [
				OTDiagnosticLogger current: (OTDiagnosticLogger onMessageDo: [ :severity :message | ]) ].
			self performTest
		] ensure: [
			self tearDown.
			previousDiagnosticLogger ifNotNil: [ OTDiagnosticLogger current: previousDiagnosticLogger ] ]
	] ensure: [ self cleanUpInstanceVariables ]'
	classified: 'running'

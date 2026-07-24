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
					previousDiagnosticLogger := OTDiagnosticLogger classVarNamed: #Current.
					OTDiagnosticLogger current: (OTDiagnosticLogger onMessageDo: [ :severity :message | ]) ].
			self setUp.
			previousDiagnosticLogger ifNotNil: [
				OTDiagnosticLogger current: (OTDiagnosticLogger onMessageDo: [ :severity :message | ]) ].
			self performTest
		] ensure: [
			self tearDown.
			OTDiagnosticLogger classVarNamed: #Current put: previousDiagnosticLogger ]
	] ensure: [ self cleanUpInstanceVariables ]'
	classified: 'running'

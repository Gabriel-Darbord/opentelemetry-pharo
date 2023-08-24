Class {
	#name : #BaselineOfOpenTelemetry,
	#superclass : #BaselineOf,
	#category : #BaselineOfOpenTelemetry
}

{ #category : #baselines }
BaselineOfOpenTelemetry >> baseline: spec [

	<baseline>
	spec for: #common do: [
		self packages: spec.
		self groups: spec ]
]

{ #category : #baselines }
BaselineOfOpenTelemetry >> groups: spec [

	spec
		group: 'default' with: #( 'core' 'tests' );
		group: 'core'
		with: #( 'OpenTelemetry-Instrumentation'
			   'OpenTelemetry-Exporters' );
		group: 'tests' with: 'OpenTelemetry-Instrumentation-Tests';
		group: 'SUnit' with: #( 'default' 'OpenTelemetry-Agents-SUnit' )
]

{ #category : #baselines }
BaselineOfOpenTelemetry >> packages: spec [

	spec
		package: 'OpenTelemetry-Instrumentation';
		package: 'OpenTelemetry-Instrumentation-Tests'
		with: [ spec requires: 'OpenTelemetry-Instrumentation' ];
		package: 'OpenTelemetry-Exporters';
		package: 'OpenTelemetry-Agents-SUnit'
]

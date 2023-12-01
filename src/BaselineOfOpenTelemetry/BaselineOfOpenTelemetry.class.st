Class {
	#name : #BaselineOfOpenTelemetry,
	#superclass : #BaselineOf,
	#category : #BaselineOfOpenTelemetry
}

{ #category : #baselines }
BaselineOfOpenTelemetry >> baseline: spec [

	<baseline>
	spec for: #common do: [
		spec postLoadDoIt: #instrument.
		self dependencies: spec.
		self packages: spec.
		self groups: spec ]
]

{ #category : #baselines }
BaselineOfOpenTelemetry >> dependencies: spec [

	spec
		baseline: 'STONCustomizer'
		with: [
		spec repository: 'github://jecisc/STONCustomizer:v1.x.x/src' ]
]

{ #category : #baselines }
BaselineOfOpenTelemetry >> groups: spec [

	spec
		group: 'default' with: #( 'core' 'tests' );
		group: 'core'
		with: #( 'OpenTelemetry-Instrumentation'
			   'OpenTelemetry-Exporters' 'OpenTelemetry-Sampling' );
		group: 'all' with: #( 'default' 'SUnit' 'Shout' 'OpalCompiler' );
		group: 'tests' with: 'OpenTelemetry-Instrumentation-Tests';
		group: 'SUnit' with: 'OpenTelemetry-Agents-SUnit';
		group: 'Shout' with: 'OpenTelemetry-Agents-Shout';
		group: 'OpalCompiler' with: 'OpenTelemetry-Agents-OpalCompiler'
]

{ #category : #actions }
BaselineOfOpenTelemetry >> instrument [

	OTAgentInstaller install
]

{ #category : #baselines }
BaselineOfOpenTelemetry >> packages: spec [

	spec
		package: 'OpenTelemetry-Configuration';
		package: 'OpenTelemetry-Instrumentation' with: [
			spec requires:
					#( 'OpenTelemetry-Exporters' 'OpenTelemetry-Sampling'
					   'OpenTelemetry-Instrumentation-Matchers' ) ];
		package: 'OpenTelemetry-Instrumentation-Tests'
		with: [ spec requires: 'OpenTelemetry-Instrumentation' ];
		package: 'OpenTelemetry-Instrumentation-Matchers';
		package: 'OpenTelemetry-Exporters';
		package: 'OpenTelemetry-Sampling';
		package: 'OpenTelemetry-Agents-SUnit'
		with: [ spec requires: 'OpenTelemetry-Instrumentation' ];
		package: 'OpenTelemetry-Agents-Shout' with: [
			spec requires:
					#( 'STONCustomizer' 'OpenTelemetry-Instrumentation' ) ];
		package: 'OpenTelemetry-Agents-OpalCompiler'
		with: [ spec requires: 'OpenTelemetry-Instrumentation' ]
]

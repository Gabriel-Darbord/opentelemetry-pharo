Class {
	#name : 'BaselineOfOpenTelemetry',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfOpenTelemetry',
	#package : 'BaselineOfOpenTelemetry'
}

{ #category : 'baselines' }
BaselineOfOpenTelemetry >> baseline: spec [

	<baseline>
	spec for: #common do: [
		spec postLoadDoIt: #instrument.
		self dependencies: spec.
		self packages: spec.
		self groups: spec ]
]

{ #category : 'baselines' }
BaselineOfOpenTelemetry >> dependencies: spec [

	spec
		baseline: 'STONCustomizer'
		with: [
		spec repository: 'github://jecisc/STONCustomizer:v1.x.x/src' ]
]

{ #category : 'baselines' }
BaselineOfOpenTelemetry >> groups: spec [

	spec
		group: 'default' with: #( 'core' 'tests' );
		group: 'core' with: #( 'OpenTelemetry-Instrumentation' );
		group: 'all' with: #( 'default' 'SUnit' 'Shout' 'OpalCompiler' );
		group: 'tests' with: 'OpenTelemetry-Instrumentation-Tests';
		group: 'SUnit' with: 'OpenTelemetry-Agents-SUnit';
		group: 'Shout' with: 'OpenTelemetry-Agents-Shout';
		group: 'OpalCompiler' with: 'OpenTelemetry-Agents-OpalCompiler'
]

{ #category : 'actions' }
BaselineOfOpenTelemetry >> instrument [

	OTAgentInstaller install
]

{ #category : 'baselines' }
BaselineOfOpenTelemetry >> packages: spec [

	spec
		package: 'OpenTelemetry-Configuration';
		package: 'OpenTelemetry-Instrumentation' with: [
			spec requires:
					#( 'OpenTelemetry-Configuration' 'OpenTelemetry-Exporters'
					   'OpenTelemetry-Sampling' 'OpenTelemetry-Matchers' ) ];
		package: 'OpenTelemetry-Instrumentation-Tests'
		with: [ spec requires: 'OpenTelemetry-Instrumentation' ];
		package: 'OpenTelemetry-Matchers';
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

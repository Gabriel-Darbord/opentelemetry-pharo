Class {
	#name : 'BaselineOfOpenTelemetry',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfOpenTelemetry',
	#package : 'BaselineOfOpenTelemetry'
}

{ #category : 'baselines' }
BaselineOfOpenTelemetry >> baseline: spec [

	<baseline>
	spec for: #common do: [ self baselineCommon: spec ].

	spec
		for: #( 'pharo12.x' 'pharo13.x' 'pharo14.x' )
		do: [ self baselinePharo12Plus: spec ]
]

{ #category : 'baselines' }
BaselineOfOpenTelemetry >> baselineCommon: spec [

	spec baseline: 'STONCustomizer' with: [ spec repository: 'github://jecisc/STONCustomizer:v1.x.x/src' ].

	spec
		package: 'OpenTelemetry-Instrumentation-MetaLink' with: [ spec requires: 'OpenTelemetry-Instrumentation' ];
		package: 'OpenTelemetry-Instrumentation'
		with: [ spec requires: #( 'OpenTelemetry-Exporters' 'OpenTelemetry-Matchers' 'OpenTelemetry-Sampling' ) ];
		package: 'OpenTelemetry-Instrumentation-MetaLink-Tests'
		with: [ spec requires: #( 'OpenTelemetry-Instrumentation-Tests' 'OpenTelemetry-Instrumentation-MetaLink' ) ];
		package: 'OpenTelemetry-Instrumentation-Tests' with: [ spec requires: 'OpenTelemetry-Instrumentation' ];
		package: 'OpenTelemetry-Logs' with: [ spec requires: #( 'OpenTelemetry-Exporters' 'OpenTelemetry-Instrumentation' ) ];
		package: 'OpenTelemetry-Logs-Tests' with: [ spec requires: 'OpenTelemetry-Logs' ];
		package: 'OpenTelemetry-Metrics' with: [ spec requires: 'OpenTelemetry-Instrumentation' ];
		package: 'OpenTelemetry-Metrics-Tests' with: [ spec requires: 'OpenTelemetry-Metrics' ];
		package: 'OpenTelemetry-Exporters';
		package: 'OpenTelemetry-Matchers';
		package: 'OpenTelemetry-Sampling' with: [ spec requires: 'OpenTelemetry-Exporters' ];
		package: 'OpenTelemetry-Agents-SUnit' with: [ spec requires: 'OpenTelemetry-Instrumentation' ];
		package: 'OpenTelemetry-Agents-Shout' with: [ spec requires: #( 'STONCustomizer' 'OpenTelemetry-Instrumentation' ) ];
		package: 'OpenTelemetry-Agents-OpalCompiler' with: [ spec requires: 'OpenTelemetry-Instrumentation' ].

	spec
		group: 'default' with: #( 'core' 'tests' );
		group: 'all' with: #( 'default' 'SUnit' 'Shout' 'OpalCompiler' );
		group: 'SUnit' with: #( 'OpenTelemetry-Agents-SUnit' );
		group: 'Shout' with: #( 'OpenTelemetry-Agents-Shout' );
		group: 'OpalCompiler' with: #( 'OpenTelemetry-Agents-OpalCompiler' )
]

{ #category : 'baselines' }
BaselineOfOpenTelemetry >> baselinePharo12Plus: spec [
	"MethodProxies are available for Pharo 12+"

	spec baseline: 'MethodProxies' with: [
		spec repository:
			'github://pharo-contributions/MethodProxies:v.2.0/src' ].

	spec
		package: 'OpenTelemetry-Compatibility-Pharo12Plus';
		package: 'OpenTelemetry-Instrumentation-MethodProxy'
		with: [
			spec requires: #( 'MethodProxies' 'OpenTelemetry-Instrumentation' ) ];
		package: 'OpenTelemetry-Instrumentation-MethodProxy-Tests' with: [
			spec requires: #( 'OpenTelemetry-Instrumentation-Tests'
					   'OpenTelemetry-Instrumentation-MethodProxy' ) ].

	spec
		group: 'core' with: #( 'OpenTelemetry-Instrumentation-MetaLink'
			   'OpenTelemetry-Metrics'
			   'OpenTelemetry-Logs'
			   'OpenTelemetry-Instrumentation-MethodProxy'
			   'OpenTelemetry-Compatibility-Pharo12Plus' );
		group: 'tests'
		with: #( 'OpenTelemetry-Metrics-Tests'
			   'OpenTelemetry-Logs-Tests'
			   'OpenTelemetry-Instrumentation-MetaLink-Tests'
			   'OpenTelemetry-Instrumentation-MethodProxy-Tests' )
]

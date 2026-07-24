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

	spec for: #( 'pharo12.x' 'pharo13.x' 'pharo14.x' ) do: [ self baselinePharo12Plus: spec ]
]

{ #category : 'baselines' }
BaselineOfOpenTelemetry >> baselineCommon: spec [

	spec
		package: 'OpenTelemetry-Instrumentation-MetaLink' with: [ spec requires: 'OpenTelemetry-Instrumentation' ];
		package: 'OpenTelemetry-Instrumentation'
		with: [ spec requires: #( 'OpenTelemetry-Exporters' 'OpenTelemetry-Matchers' 'OpenTelemetry-Sampling' ) ];
		package: 'OpenTelemetry-Instrumentation-MetaLink-Tests'
		with: [ spec requires: #( 'OpenTelemetry-Instrumentation-Tests' 'OpenTelemetry-Instrumentation-MetaLink' ) ];
		package: 'OpenTelemetry-Instrumentation-Tests' with: [ spec requires: 'OpenTelemetry-Instrumentation' ];
		package: 'OpenTelemetry-Logs' with: [ spec requires: #( 'OpenTelemetry-Exporters' 'OpenTelemetry-Instrumentation' ) ];
		package: 'OpenTelemetry-Logs-Tests' with: [ spec requires: #( 'OpenTelemetry-Logs' 'OpenTelemetry-Instrumentation-Tests' ) ];
		package: 'OpenTelemetry-Metrics' with: [ spec requires: 'OpenTelemetry-Instrumentation' ];
		package: 'OpenTelemetry-Metrics-Tests'
		with: [ spec requires: #( 'OpenTelemetry-Metrics' 'OpenTelemetry-Instrumentation-Tests' ) ];
		package: 'OpenTelemetry-Exporters';
		package: 'OpenTelemetry-Matchers';
		package: 'OpenTelemetry-Sampling' with: [ spec requires: 'OpenTelemetry-Exporters' ].

	spec
		group: 'traces' with: #( 'OpenTelemetry-Instrumentation' );
		group: 'instrumentation' with: #( 'traces' 'OpenTelemetry-Instrumentation-MetaLink' );
		group: 'logs' with: #( 'OpenTelemetry-Logs' );
		group: 'metrics' with: #( 'OpenTelemetry-Metrics' );
		group: 'traces-tests' with: #( 'OpenTelemetry-Instrumentation-Tests' );
		group: 'instrumentation-tests' with: #( 'OpenTelemetry-Instrumentation-MetaLink-Tests' );
		group: 'logs-tests' with: #( 'OpenTelemetry-Logs-Tests' );
		group: 'metrics-tests' with: #( 'OpenTelemetry-Metrics-Tests' );
		group: 'core' with: #( 'instrumentation' 'logs' 'metrics' );
		group: 'tests' with: #( 'traces-tests' 'instrumentation-tests' 'logs-tests' 'metrics-tests' );
		group: 'default' with: #( 'core' 'tests' );
		group: 'all' with: #( 'default' )
]

{ #category : 'baselines' }
BaselineOfOpenTelemetry >> baselinePharo12Plus: spec [
	"MethodProxies are available for Pharo 12+"

	spec baseline: 'MethodProxies' with: [ spec repository: 'github://pharo-contributions/MethodProxies:v.2.0/src' ].

	spec
		package: 'OpenTelemetry-Compatibility-Pharo12Plus';
		package: 'OpenTelemetry-Instrumentation-MethodProxy'
		with: [ spec requires: #( 'MethodProxies' 'OpenTelemetry-Instrumentation' ) ];
		package: 'OpenTelemetry-Instrumentation-MethodProxy-Tests'
		with: [ spec requires: #( 'OpenTelemetry-Instrumentation-Tests' 'OpenTelemetry-Instrumentation-MethodProxy' ) ].

	spec
		group: 'instrumentation'
		with: #( 'traces' 'OpenTelemetry-Instrumentation-MetaLink' 'OpenTelemetry-Instrumentation-MethodProxy'
			   'OpenTelemetry-Compatibility-Pharo12Plus' );
		group: 'instrumentation-tests'
		with: #( 'OpenTelemetry-Instrumentation-MetaLink-Tests' 'OpenTelemetry-Instrumentation-MethodProxy-Tests' )
]

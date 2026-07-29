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

	spec baseline: 'GRPC' with: [ spec repository: 'github://Gabriel-Darbord/grpc-pharo:main/src' ].

	spec
		package: 'OpenTelemetry-Matchers';
		package: 'OpenTelemetry-SDK';
		package: 'OpenTelemetry-Instrumentation' with: [ spec requires: #( 'OpenTelemetry-Matchers' ) ];
		package: 'OpenTelemetry-Exporters';
		package: 'OpenTelemetry-Traces'
		with: [ spec requires: #( 'OpenTelemetry-SDK' 'OpenTelemetry-Instrumentation' 'OpenTelemetry-Exporters'
				   'GRPC' ) ];
		package: 'OpenTelemetry-Logs'
		with: [ spec requires: #( 'OpenTelemetry-SDK' 'OpenTelemetry-Traces' 'OpenTelemetry-Exporters' ) ];
		package: 'OpenTelemetry-Metrics'
		with: [ spec requires: #( 'OpenTelemetry-SDK' 'OpenTelemetry-Traces' 'OpenTelemetry-Exporters' ) ];
		package: 'OpenTelemetry-Autoconfigure' with: [
				spec requires:
						#( 'OpenTelemetry-SDK' 'OpenTelemetry-Instrumentation' 'OpenTelemetry-Exporters' 'OpenTelemetry-Traces'
						   'OpenTelemetry-Logs' 'OpenTelemetry-Metrics' ) ];
		package: 'OpenTelemetry-Instrumentation-MetaLink' with: [ spec requires: 'OpenTelemetry-Instrumentation' ];
		package: 'OpenTelemetry-Instrumentation-Tests' with: [
				spec requires:
						#( 'OpenTelemetry-SDK' 'OpenTelemetry-Instrumentation' 'OpenTelemetry-Exporters' 'OpenTelemetry-Traces'
						   'OpenTelemetry-Autoconfigure' ) ];
		package: 'OpenTelemetry-Instrumentation-IntegrationTests' with: [
				spec requires:
						#( 'OpenTelemetry-Autoconfigure' 'OpenTelemetry-Exporters' 'OpenTelemetry-Traces' 'OpenTelemetry-Logs'
						   'OpenTelemetry-Metrics' 'OpenTelemetry-Instrumentation-Tests' ) ];
		package: 'OpenTelemetry-Logs-IntegrationTests'
		with: [ spec requires: #( 'OpenTelemetry-Logs' 'OpenTelemetry-Instrumentation-IntegrationTests' ) ];
		package: 'OpenTelemetry-Metrics-IntegrationTests'
		with: [ spec requires: #( 'OpenTelemetry-Metrics' 'OpenTelemetry-Instrumentation-IntegrationTests' ) ];
		package: 'OpenTelemetry-Instrumentation-MetaLink-Tests'
		with: [ spec requires: #( 'OpenTelemetry-Instrumentation-Tests' 'OpenTelemetry-Instrumentation-MetaLink' ) ];
		package: 'OpenTelemetry-Logs-Tests'
		with: [ spec requires: #( 'OpenTelemetry-Logs' 'OpenTelemetry-Instrumentation-Tests' 'OpenTelemetry-Autoconfigure' ) ];
		package: 'OpenTelemetry-Metrics-Tests'
		with: [ spec requires: #( 'OpenTelemetry-Metrics' 'OpenTelemetry-Instrumentation-Tests' 'OpenTelemetry-Autoconfigure' ) ].

	spec
		group: 'traces' with: #( 'OpenTelemetry-Traces' );
		group: 'instrumentation' with: #( 'OpenTelemetry-Instrumentation-MetaLink' );
		group: 'logs' with: #( 'OpenTelemetry-Logs' );
		group: 'metrics' with: #( 'OpenTelemetry-Metrics' );
		group: 'autoconfigure' with: #( 'OpenTelemetry-Autoconfigure' );
		group: 'traces-tests' with: #( 'OpenTelemetry-Instrumentation-Tests' );
		group: 'traces-integration-tests' with: #( 'OpenTelemetry-Instrumentation-IntegrationTests' );
		group: 'logs-integration-tests' with: #( 'OpenTelemetry-Logs-IntegrationTests' );
		group: 'metrics-integration-tests' with: #( 'OpenTelemetry-Metrics-IntegrationTests' );
		group: 'instrumentation-tests' with: #( 'OpenTelemetry-Instrumentation-MetaLink-Tests' );
		group: 'logs-tests' with: #( 'OpenTelemetry-Logs-Tests' );
		group: 'metrics-tests' with: #( 'OpenTelemetry-Metrics-Tests' );
		group: 'core' with: #( 'traces' 'instrumentation' 'logs' 'metrics' 'autoconfigure' );
		group: 'tests' with: #( 'core' 'traces-tests' 'instrumentation-tests' 'logs-tests' 'metrics-tests' );
		group: 'integration-tests'
		with:
			#( 'OpenTelemetry-Instrumentation-IntegrationTests' 'OpenTelemetry-Logs-IntegrationTests' 'OpenTelemetry-Metrics-IntegrationTests' );
		group: 'default' with: #( 'core' );
		group: 'all' with: #( 'tests' 'integration-tests' )
]

{ #category : 'baselines' }
BaselineOfOpenTelemetry >> baselinePharo12Plus: spec [
	"MethodProxies are available for Pharo 12+"

	spec baseline: 'MethodProxies' with: [ spec repository: 'github://pharo-contributions/MethodProxies:v.2.0/src' ].

	spec
		package: 'OpenTelemetry-Compatibility-Pharo12Plus';
		package: 'OpenTelemetry-Instrumentation'
		with: [ spec requires: #( 'OpenTelemetry-Matchers' 'OpenTelemetry-Compatibility-Pharo12Plus' ) ];
		package: 'OpenTelemetry-Instrumentation-MethodProxy'
		with: [ spec requires: #( 'MethodProxies' 'OpenTelemetry-Instrumentation' ) ];
		package: 'OpenTelemetry-Instrumentation-MethodProxy-Tests'
		with: [ spec requires: #( 'OpenTelemetry-Instrumentation-Tests' 'OpenTelemetry-Instrumentation-MethodProxy' ) ].

	spec
		group: 'instrumentation' with: #( 'OpenTelemetry-Instrumentation-MetaLink' 'OpenTelemetry-Instrumentation-MethodProxy'
			   'OpenTelemetry-Compatibility-Pharo12Plus' );
		group: 'instrumentation-tests'
		with: #( 'OpenTelemetry-Instrumentation-MetaLink-Tests' 'OpenTelemetry-Instrumentation-MethodProxy-Tests' )
]

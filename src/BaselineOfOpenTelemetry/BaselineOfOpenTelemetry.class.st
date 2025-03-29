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
		spec
			baseline: 'STONCustomizer'
			with: [
			spec repository: 'github://jecisc/STONCustomizer:v1.x.x/src' ].

		spec
			package: 'OpenTelemetry-Instrumentation-MetaLink'
			with: 'OpenTelemetry-Instrumentation';
			package: 'OpenTelemetry-Instrumentation' with: [
				spec requires:
						#( 'OpenTelemetry-Configuration' 'OpenTelemetry-Exporters'
						   'OpenTelemetry-Matchers' 'OpenTelemetry-Sampling' ) ];
			package: 'OpenTelemetry-Instrumentation-MetaLink-Tests'
			with: 'OpenTelemetry-Instrumentation-Tests';
			package: 'OpenTelemetry-Instrumentation-Tests'
			with: 'OpenTelemetry-Instrumentation';
			package: 'OpenTelemetry-Configuration';
			package: 'OpenTelemetry-Exporters';
			package: 'OpenTelemetry-Matchers';
			package: 'OpenTelemetry-Sampling';
			package: 'OpenTelemetry-Agents-SUnit'
			with: 'OpenTelemetry-Instrumentation';
			package: 'OpenTelemetry-Agents-Shout' with: [
				spec requires:
						#( 'STONCustomizer' 'OpenTelemetry-Instrumentation' ) ];
			package: 'OpenTelemetry-Agents-OpalCompiler'
			with: 'OpenTelemetry-Instrumentation'.


		spec
			group: 'default' with: #( 'core' 'tests' );
			group: 'core' with: #( 'OpenTelemetry-Instrumentation-MetaLink' );
			group: 'all' with: #( 'default' 'SUnit' 'Shout' 'OpalCompiler' );
			group: 'tests'
			with: 'OpenTelemetry-Instrumentation-MetaLink-Tests';
			group: 'SUnit' with: 'OpenTelemetry-Agents-SUnit';
			group: 'Shout' with: 'OpenTelemetry-Agents-Shout';
			group: 'OpalCompiler' with: 'OpenTelemetry-Agents-OpalCompiler' ].

	"Only use MethodProxies for Pharo 12+"
	spec for: #( 'pharo12.x' 'pharo13.x' ) do: [
		spec
			baseline: 'MethodProxies'
			with: [
			spec repository: 'github://pharo-contributions/MethodProxies/src' ].

		spec
			package: 'OpenTelemetry-Instrumentation-MethodProxy'
			with: [
				spec requires:
						#( 'MethodProxies' 'OpenTelemetry-Instrumentation' ) ];
			package: 'OpenTelemetry-Instrumentation-MethodProxy-Tests'
			with: [
				spec requires: #( 'OpenTelemetry-Instrumentation-Tests'
						   'OpenTelemetry-Instrumentation-MethodProxy' ) ].

		spec
			group: 'core' with: #( 'OpenTelemetry-Instrumentation-MetaLink'
				   'OpenTelemetry-Instrumentation-MethodProxy' );
			group: 'tests'
			with: #( 'OpenTelemetry-Instrumentation-MetaLink-Tests'
				   'OpenTelemetry-Instrumentation-MethodProxy-Tests' ) ]
]

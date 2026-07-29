| result spec |

TestCase defaultTimeLimitSecs: 30.

spec := SmalltalkCISpec new
	name: 'OTLP gRPC Integration Tests';
	yourself.

result := SmalltalkCI testRunnerClass
	runClasses: {
		OTOtlpGrpcSpanExporterIntegrationTest.
		OTOtlpGrpcLogRecordExporterIntegrationTest.
		OTOtlpGrpcMetricExporterIntegrationTest }
	spec: spec.

SCITestReporterStdout report: result spec: spec on: SmalltalkCI stdout.

result isSuccessful ifFalse: [ Error signal: 'OTLP gRPC integration tests failed' ]

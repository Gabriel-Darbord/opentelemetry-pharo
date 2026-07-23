| packageName stubNames |
stubNames := #(
	OTAlwaysOffSampler
	OTAlwaysOnSampler
	OTAttributeNormalizer
	OTBatchLogRecordProcessor
	OTBlockResourceDetector
	OTComposableSampler
	OTConsoleLogRecordExporter
	OTHostResourceDetector
	OTInstrumentationScope
	OTJaegerRemoteSampler
	OTLoggerConfig
	OTMeterConfig
	OTMeterProvider
	OTMetricAttributeFilter
	OTMetricView
	OTOtlpGrpcLogRecordExporter
	OTOtlpHttpProtobufLogRecordExporter
	OTParentBasedSampler
	OTPeriodicExportingMetricReader
	OTProcessResourceDetector
	OTPrometheusMetricReader
	OTResource
	OTSampler
	OTServiceInstanceResourceDetector
	OTSimpleLogRecordProcessor
	OTSpan
	OTSpanContext
	OTSpanEvent
	OTSpanLink
	OTStaticResourceDetector
	OTTraceState
	OTTracerProvider
	OTSeverity
).
stubNames do: [ :each |
	Smalltalk globals at: each put: nil ]

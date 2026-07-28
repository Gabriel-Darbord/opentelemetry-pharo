Class {
	#name : 'OTPrometheusMetricReaderTest',
	#superclass : 'TestCase',
	#instVars : [
		'provider',
		'reader'
	],
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'private' }
OTPrometheusMetricReaderTest >> occurrencesOfSubstring: aSubstring in: aString [

	| count index |
	count := 0.
	index := 1.
	[
		index := aString findString: aSubstring startingAt: index.
		index > 0 ] whileTrue: [
			count := count + 1.
			index := index + aSubstring size ].
	^ count
]

{ #category : 'running' }
OTPrometheusMetricReaderTest >> tearDown [

	[ provider ifNotNil: [ provider shutdown ] ] ensure: [ super tearDown ]
]

{ #category : 'tests' }
OTPrometheusMetricReaderTest >> testCollectReturnsEmptySnapshotAfterShutdown [

	| snapshot |
	provider := OTMeterProvider new.
	reader := OTPrometheusMetricReader new.
	reader port: 0.
	provider addMetricReader: reader.
	self assert: reader shutdown.
	snapshot := reader collect.
	self assert: snapshot metrics isEmpty.
	self assert: snapshot measurements isEmpty
]

{ #category : 'tests' }
OTPrometheusMetricReaderTest >> testCollectUsesCumulativeTemporality [

	| counter metric |
	provider := OTMeterProvider new.
	reader := OTPrometheusMetricReader new.
	reader port: 0.
	provider addMetricReader: reader.
	counter := (provider meterNamed: 'demo.metrics') counterNamed: 'requests.total'.
	counter add: 2 attributes: { ('method' -> 'GET') }.
	metric := reader collectSnapshot metrics first.
	self assert: metric temporality equals: #cumulative
]

{ #category : 'tests' }
OTPrometheusMetricReaderTest >> testConcurrentShutdownReturnsTrueOnce [

	| done gate lock results workerCount |
	provider := OTMeterProvider new.
	reader := OTPrometheusMetricReader new.
	reader port: 0.
	provider addMetricReader: reader.
	results := OrderedCollection new.
	lock := Semaphore forMutualExclusion.
	gate := Semaphore new.
	done := Semaphore new.
	workerCount := 8.
	workerCount timesRepeat: [
			[
				gate wait.
				lock critical: [ results add: reader shutdown ].
				done signal ] forkAt: Processor userBackgroundPriority ].
	workerCount timesRepeat: [ gate signal ].
	workerCount timesRepeat: [ self assert: (done waitTimeoutMilliseconds: 1000) not ].
	self assert: (results count: [ :each | each = true ]) equals: 1.
	self assert: (results count: [ :each | each = false ]) equals: workerCount - 1.
	self assert: reader isShutdown.
	self assert: reader server isNil
]

{ #category : 'tests' }
OTPrometheusMetricReaderTest >> testResponseFormatDescriptorForAcceptHeaderNegotiatesAllowUtf8Escaping [

	| descriptor |
	reader := OTPrometheusMetricReader new.
	descriptor := reader responseFormatDescriptorForAcceptHeader: 'application/openmetrics-text;version=1.0.0;escaping=allow-utf-8'.
	self assert: (descriptor at: #format) equals: #openMetricsText100.
	self assert: (descriptor at: #escaping) equals: #allowUtf8
]

{ #category : 'tests' }
OTPrometheusMetricReaderTest >> testResponseFormatForAcceptHeaderUsesHighestWeightedSupportedFormat [

	reader := OTPrometheusMetricReader new.
	self
		assert: (reader responseFormatForAcceptHeader:
				 'application/openmetrics-text;version=1.0.0;q=0.2,text/plain;version=1.0.0;q=0.6,text/plain;version=0.0.4;q=0.1')
		equals: #prometheusText100
]

{ #category : 'tests' }
OTPrometheusMetricReaderTest >> testScrapeAllowUtf8DoesNotUndoUnderscoreEscapingStrategy [

	| client counter scrape |
	provider := OTMeterProvider new.
	reader := OTPrometheusMetricReader new.
	reader
		port: 0;
		scopeInfoEnabled: false;
		targetInfoEnabled: false.
	provider addMetricReader: reader.
	counter := (provider meterNamed: 'demo.metrics') counterNamed: 'metric.name'.
	counter add: 1 attributes: { ('label:with:colons' -> 'value') }.
	client := ZnClient new.
	client
		url: 'http://localhost:' , reader port asString , reader path;
		accept: 'application/openmetrics-text; version=1.0.0; escaping=allow-utf-8';
		get.
	scrape := client response entity contents asString.
	self assert: (scrape includesSubstring: 'metric_name_total{label_with_colons="value"} 1').
	self deny: (scrape includesSubstring: '{"metric.name"')
]

{ #category : 'tests' }
OTPrometheusMetricReaderTest >> testScrapeCanDisableScopeInfoAndTargetInfo [

	| counter scrape |
	provider := OTMeterProvider new.
	provider resource: (OTResource attributes: { ('service.name' -> 'demo') }).
	reader := OTPrometheusMetricReader new.
	reader
		port: 0;
		scopeInfoEnabled: false;
		targetInfoEnabled: false.
	provider addMetricReader: reader.
	counter := (provider
		            meterNamed: 'demo.metrics'
		            version: '1.0.0'
		            schemaUrl: ''
		            attributes: { ('scope.answer' -> 42) }) counterNamed: 'requests.total'.
	counter add: 3 attributes: { ('method' -> 'GET') }.
	scrape := ZnClient new get: 'http://localhost:' , reader port asString , reader path.
	scrape := scrape asString.
	self assert: (scrape includesSubstring: '# TYPE requests_total counter').
	self assert: (scrape includesSubstring: 'method="GET"').
	self deny: (scrape includesSubstring: 'otel_scope_name="demo.metrics"').
	self deny: (scrape includesSubstring: 'target_info{')
]

{ #category : 'tests' }
OTPrometheusMetricReaderTest >> testScrapeCopiesConfiguredResourceConstantLabels [

	| counter scrape |
	provider := OTMeterProvider new.
	provider resource: (OTResource attributes: {
				 ('service.name' -> 'demo').
				 ('service.namespace' -> 'shop').
				 ('service.instance.id' -> 'pharo-1') }).
	reader := OTPrometheusMetricReader new.
	reader
		port: 0;
		resourceConstantLabels: (OTMetricAttributeFilter included: #( 'service.name' ) excluded: nil).
	provider addMetricReader: reader.
	counter := (provider meterNamed: 'demo.metrics') counterNamed: 'requests.total'.
	counter add: 3 attributes: { ('method' -> 'GET') }.
	scrape := ZnClient new get: 'http://localhost:' , reader port asString , reader path.
	scrape := scrape asString.
	self assert: (self occurrencesOfSubstring: 'service_name="demo"' in: scrape) equals: 2.
	self assert: (self occurrencesOfSubstring: 'service_namespace="shop"' in: scrape) equals: 1.
	self assert: (self occurrencesOfSubstring: 'service_instance_id="pharo-1"' in: scrape) equals: 1
]

{ #category : 'tests' }
OTPrometheusMetricReaderTest >> testScrapeDoesNotWriteTargetInfoForEmptyResource [

	| counter scrape |
	provider := OTMeterProvider new.
	provider resource: OTResource empty.
	reader := OTPrometheusMetricReader new.
	reader port: 0.
	provider addMetricReader: reader.
	counter := (provider meterNamed: 'demo.metrics') counterNamed: 'requests.total'.
	counter add: 3 attributes: { ('method' -> 'GET') }.
	scrape := ZnClient new get: 'http://localhost:' , reader port asString , reader path.
	scrape := scrape asString.
	self assert: (scrape includesSubstring: 'requests_total{').
	self deny: (scrape includesSubstring: 'target_info{')
]

{ #category : 'tests' }
OTPrometheusMetricReaderTest >> testScrapeNegotiatedUnderscoresOverrideNoTranslation [

	| client counter scrape |
	provider := OTMeterProvider new.
	reader := OTPrometheusMetricReader new.
	reader
		port: 0;
		translationStrategy: #noTranslation;
		scopeInfoEnabled: false;
		targetInfoEnabled: false.
	provider addMetricReader: reader.
	counter := (provider meterNamed: 'demo.metrics') counterNamed: 'metric.name'.
	counter add: 1 attributes: { ('label:with:colons' -> 'value') }.
	client := ZnClient new.
	client
		url: 'http://localhost:' , reader port asString , reader path;
		accept: 'application/openmetrics-text; version=1.0.0; escaping=underscores';
		get.
	scrape := client response entity contents asString.
	self
		assert: client response entity contentType asString
		equals: 'application/openmetrics-text;version=1.0.0;charset=utf-8;escaping=underscores'.
	self assert: (scrape includesSubstring: 'metric_name{label_with_colons="value"} 1').
	self deny: (scrape includesSubstring: '{"metric.name"')
]

{ #category : 'tests' }
OTPrometheusMetricReaderTest >> testScrapeNegotiatesAllowUtf8EscapingForOpenMetricsText [

	| client counter scrape |
	provider := OTMeterProvider new.
	reader := OTPrometheusMetricReader new.
	reader
		port: 0;
		translationStrategy: #noTranslation;
		scopeInfoEnabled: false;
		targetInfoEnabled: false.
	provider addMetricReader: reader.
	counter := (provider meterNamed: 'demo.metrics') counterNamed: 'metric.name'.
	counter add: 1 attributes: { ('label:with:colons' -> 'value') }.
	client := ZnClient new.
	client
		url: 'http://localhost:' , reader port asString , reader path;
		accept: 'application/openmetrics-text; version=1.0.0; escaping=allow-utf-8';
		get.
	scrape := client response entity contents asString.
	self
		assert: client response entity contentType asString
		equals: 'application/openmetrics-text;version=1.0.0;charset=utf-8;escaping=allow-utf-8'.
	self assert: (scrape includesSubstring: '{"metric.name","label:with:colons"="value"} 1')
]

{ #category : 'tests' }
OTPrometheusMetricReaderTest >> testScrapeNegotiatesOpenMetricsText [

	| client counter scrape |
	provider := OTMeterProvider new.
	provider resource: (OTResource attributes: { ('service.name' -> 'demo') }).
	reader := OTPrometheusMetricReader new.
	reader port: 0.
	provider addMetricReader: reader.
	counter := (provider meterNamed: 'demo.metrics') counterNamed: 'requests.total'.
	counter add: 1 attributes: { ('method' -> 'GET') }.
	client := ZnClient new.
	client
		url: 'http://localhost:' , reader port asString , reader path;
		accept: 'application/openmetrics-text; version=1.0.0';
		get.
	scrape := client response entity contents asString.
	self
		assert: client response entity contentType asString
		equals: 'application/openmetrics-text;version=1.0.0;charset=utf-8;escaping=underscores'.
	self assert: (scrape includesSubstring: '# EOF')
]

{ #category : 'tests' }
OTPrometheusMetricReaderTest >> testScrapeNegotiatesPrometheusTextVersionOne [

	| client counter scrape |
	provider := OTMeterProvider new.
	reader := OTPrometheusMetricReader new.
	reader port: 0.
	provider addMetricReader: reader.
	counter := (provider meterNamed: 'demo.metrics') counterNamed: 'requests.total'.
	counter add: 1 attributes: { ('method' -> 'GET') }.
	client := ZnClient new.
	client
		url: 'http://localhost:' , reader port asString , reader path;
		accept: 'text/plain; version=1.0.0';
		get.
	scrape := client response entity contents asString.
	self assert: client response entity contentType asString equals: 'text/plain;version=1.0.0;charset=utf-8;escaping=underscores'.
	self deny: (scrape includesSubstring: '# EOF')
]

{ #category : 'tests' }
OTPrometheusMetricReaderTest >> testScrapeServesPrometheusTextOverHttp [

	| counter scrape |
	provider := OTMeterProvider new.
	provider resource: (OTResource attributes: { ('service.name' -> 'demo') }).
	reader := OTPrometheusMetricReader new.
	reader port: 0.
	provider addMetricReader: reader.
	counter := (provider
		            meterNamed: 'demo.metrics'
		            version: '1.0.0'
		            schemaUrl: ''
		            attributes: { ('scope.answer' -> 42) }) counterNamed: 'requests.total'.
	counter add: 3 attributes: { ('method' -> 'GET') }.
	scrape := ZnClient new get: 'http://localhost:' , reader port asString , reader path.
	scrape := scrape asString.
	self assert: (scrape includesSubstring: '# TYPE requests_total counter').
	self assert: (scrape includesSubstring: 'method="GET"').
	self assert: (scrape includesSubstring: 'otel_scope_name="demo.metrics"').
	self assert: (scrape includesSubstring: 'target_info{')
]

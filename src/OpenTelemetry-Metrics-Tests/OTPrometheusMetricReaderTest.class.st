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

{ #category : 'running' }
OTPrometheusMetricReaderTest >> tearDown [

	[ provider ifNotNil: [ provider shutdown ] ] ensure: [ super tearDown ]
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
OTPrometheusMetricReaderTest >> testResponseFormatForAcceptHeaderUsesHighestWeightedSupportedFormat [

	reader := OTPrometheusMetricReader new.
	self
		assert: (reader responseFormatForAcceptHeader:
				 'application/openmetrics-text;version=1.0.0;q=0.2,text/plain;version=1.0.0;q=0.6,text/plain;version=0.0.4;q=0.1')
		equals: #prometheusText100
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

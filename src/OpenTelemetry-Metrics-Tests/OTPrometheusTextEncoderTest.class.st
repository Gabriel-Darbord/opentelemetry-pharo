Class {
	#name : 'OTPrometheusTextEncoderTest',
	#superclass : 'TestCase',
	#instVars : [
		'encoder'
	],
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'private' }
OTPrometheusTextEncoderTest >> occurrencesOfSubstring: aSubstring in: aString [

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

{ #category : 'private' }
OTPrometheusTextEncoderTest >> sampleExemplarValue: aNumber timestamp: aDateAndTime [

	| exemplar |
	exemplar := OTMetricExemplar new.
	exemplar
		value: aNumber;
		timestamp: aDateAndTime;
		filteredAttributes: #(  ).
	^ exemplar
]

{ #category : 'private' }
OTPrometheusTextEncoderTest >> sampleResource [

	^ OTResource attributes: {
			  ('service.name' -> 'demo').
			  ('service.namespace' -> 'shop').
			  ('service.instance.id' -> 'pharo-1') }
]

{ #category : 'private' }
OTPrometheusTextEncoderTest >> sampleScope [

	^ OTInstrumentationScope
		  named: 'instrumentation'
		  version: '1.0.0'
		  schemaUrl: 'https://scope.example/schema'
		  attributes: { ('scope.key' -> 'scope-value') }
]

{ #category : 'running' }
OTPrometheusTextEncoderTest >> setUp [

	super setUp.
	encoder := OTPrometheusTextEncoder new
]

{ #category : 'tests' }
OTPrometheusTextEncoderTest >> testEncodeSnapshotAddsUnitSuffixAndUnitMetadataForOpenMetrics [

	| metric point snapshot text |
	point := OTNumberDataPoint
		         attributes: { ('method' -> 'GET') }
		         value: 4
		         startTimestamp: DateAndTime unixEpoch
		         timestamp: DateAndTime unixEpoch.
	metric := OTSumMetricData new.
	metric
		instrumentationScope: self sampleScope;
		name: 'response.size';
		description: 'Response size';
		unit: 'By';
		points: { point };
		monotonic: true;
		temporality: #cumulative.
	snapshot := OTMetricSnapshot
		            resource: self sampleResource
		            measurements: #(  )
		            metrics: { metric }
		            collectedAt: DateAndTime unixEpoch.
	text := encoder encodeSnapshot: snapshot format: #openMetricsText100.
	self assert: (text includesSubstring: '# TYPE response_size_bytes_total counter').
	self assert: (text includesSubstring: '# UNIT response_size_bytes_total bytes').
	self assert: (text includesSubstring: 'response_size_bytes_total{').
	text := encoder encodeSnapshot: snapshot.
	self deny: (text includesSubstring: '# UNIT response_size_bytes_total bytes')
]

{ #category : 'tests' }
OTPrometheusTextEncoderTest >> testEncodeSnapshotConcatenatesHistogramBoundaryLabelCollisions [

	| metric point snapshot text |
	point := OTHistogramDataPoint
		         attributes: { ('le' -> 'client-boundary') }
		         count: 3
		         sum: 6
		         min: 1
		         max: 3
		         explicitBounds: #( 2 )
		         bucketCounts: #( 2 1 )
		         startTimestamp: DateAndTime unixEpoch
		         timestamp: DateAndTime unixEpoch.
	metric := OTHistogramMetricData new.
	metric
		instrumentationScope: self sampleScope;
		name: 'request.duration';
		description: 'Request duration';
		unit: 'ms';
		points: { point };
		temporality: #cumulative.
	snapshot := OTMetricSnapshot
		            resource: OTResource empty
		            measurements: #(  )
		            metrics: { metric }
		            collectedAt: DateAndTime unixEpoch.
	text := encoder encodeSnapshot: snapshot.
	self assert: (text includesSubstring: 'client-boundary').
	self assert: (text includesSubstring: 'le="').
	self assert: (text includesSubstring: ';')
]

{ #category : 'tests' }
OTPrometheusTextEncoderTest >> testEncodeSnapshotConcatenatesMetricAttributeWithScopeLabelAfterNormalization [

	| metric point snapshot text |
	point := OTNumberDataPoint
		         attributes: { ('otel.scope.name' -> 'attribute-scope') }
		         value: 1
		         startTimestamp: DateAndTime unixEpoch
		         timestamp: DateAndTime unixEpoch.
	metric := OTGaugeMetricData new.
	metric
		instrumentationScope: self sampleScope;
		name: 'requests';
		description: 'Requests';
		unit: '1';
		points: { point }.
	snapshot := OTMetricSnapshot
		            resource: OTResource empty
		            measurements: #(  )
		            metrics: { metric }
		            collectedAt: DateAndTime unixEpoch.
	text := encoder encodeSnapshot: snapshot.
	self assert: (text includesSubstring: 'otel_scope_name="attribute-scope;instrumentation"').
	self assert: (text includesSubstring: 'otel_scope_schema_url="https://scope.example/schema"').
	self assert: (text includesSubstring: 'otel_scope_version="1.0.0"')
]

{ #category : 'tests' }
OTPrometheusTextEncoderTest >> testEncodeSnapshotCanDisableScopeInfoLabels [

	| metric point snapshot text |
	point := OTNumberDataPoint
		         attributes: { ('method' -> 'GET') }
		         value: 1
		         startTimestamp: DateAndTime unixEpoch
		         timestamp: DateAndTime unixEpoch.
	metric := OTGaugeMetricData new.
	metric
		instrumentationScope: self sampleScope;
		name: 'requests';
		description: 'Requests';
		unit: '1';
		points: { point }.
	snapshot := OTMetricSnapshot
		            resource: self sampleResource
		            measurements: #(  )
		            metrics: { metric }
		            collectedAt: DateAndTime unixEpoch.
	encoder scopeInfoEnabled: false.
	text := encoder encodeSnapshot: snapshot.
	self assert: (text includesSubstring: 'method="GET"').
	self deny: (text includesSubstring: 'otel_scope_name').
	self deny: (text includesSubstring: 'otel_scope_version').
	self deny: (text includesSubstring: 'otel_scope_schema_url').
	self deny: (text includesSubstring: 'otel_scope_scope_key')
]

{ #category : 'tests' }
OTPrometheusTextEncoderTest >> testEncodeSnapshotCanDisableTargetInfoMetric [

	| metric point snapshot text |
	point := OTNumberDataPoint
		         attributes: { ('method' -> 'GET') }
		         value: 1
		         startTimestamp: DateAndTime unixEpoch
		         timestamp: DateAndTime unixEpoch.
	metric := OTGaugeMetricData new.
	metric
		instrumentationScope: self sampleScope;
		name: 'requests';
		description: 'Requests';
		unit: '1';
		points: { point }.
	snapshot := OTMetricSnapshot
		            resource: self sampleResource
		            measurements: #(  )
		            metrics: { metric }
		            collectedAt: DateAndTime unixEpoch.
	encoder targetInfoEnabled: false.
	text := encoder encodeSnapshot: snapshot.
	self assert: (text includesSubstring: 'requests{').
	self deny: (text includesSubstring: 'target_info{')
]

{ #category : 'tests' }
OTPrometheusTextEncoderTest >> testEncodeSnapshotDropsExponentialHistogramsFromTextOutput [

	| metric point snapshot text |
	point := OTExponentialHistogramDataPoint new.
	point
		attributes: { ('method' -> 'GET') };
		count: 3;
		sum: 12;
		scale: 0;
		timestamp: DateAndTime unixEpoch.
	metric := OTExponentialHistogramMetricData new.
	metric
		instrumentationScope: self sampleScope;
		name: 'request.duration';
		description: 'Request duration';
		unit: 'ms';
		points: { point };
		temporality: #cumulative.
	snapshot := OTMetricSnapshot
		            resource: self sampleResource
		            measurements: #(  )
		            metrics: { metric }
		            collectedAt: DateAndTime unixEpoch.
	text := encoder encodeSnapshot: snapshot.
	self deny: (text includesSubstring: 'request_duration').
	self assert: (text includesSubstring: 'target_info')
]

{ #category : 'tests' }
OTPrometheusTextEncoderTest >> testEncodeSnapshotDropsMetricFamilyWhenPrometheusTypesConflict [

	| counterMetric gaugeMetric counterPoint gaugePoint snapshot text warnings |
	counterPoint := OTNumberDataPoint
		                attributes: { ('source' -> 'counter') }
		                value: 4
		                startTimestamp: DateAndTime unixEpoch
		                timestamp: DateAndTime unixEpoch.
	gaugePoint := OTNumberDataPoint
		              attributes: { ('source' -> 'gauge') }
		              value: 2
		              startTimestamp: DateAndTime unixEpoch
		              timestamp: DateAndTime unixEpoch.
	counterMetric := OTSumMetricData new.
	counterMetric
		instrumentationScope: self sampleScope;
		name: 'requests';
		description: 'Counter form';
		unit: '1';
		points: { counterPoint };
		monotonic: true;
		temporality: #cumulative.
	gaugeMetric := OTGaugeMetricData new.
	gaugeMetric
		instrumentationScope: self sampleScope;
		name: 'requests.total';
		description: 'Gauge form';
		unit: '1';
		points: { gaugePoint }.
	snapshot := OTMetricSnapshot
		            resource: OTResource empty
		            measurements: #(  )
		            metrics: {
				            counterMetric.
				            gaugeMetric }
		            collectedAt: DateAndTime unixEpoch.
	warnings := OrderedCollection new.
	encoder warningSink: [ :message | warnings add: message ].
	text := encoder encodeSnapshot: snapshot format: #prometheusText100.
	self deny: (text includesSubstring: '# TYPE requests_total').
	self deny: (text includesSubstring: 'requests_total{').
	self assert: warnings size equals: 1.
	self assert: (warnings first includesSubstring: 'conflicting types')
]

{ #category : 'tests' }
OTPrometheusTextEncoderTest >> testEncodeSnapshotDropsMetricWhenPrometheusSampleIdentityConflictsAfterLabelNormalization [

	| firstMetric firstPoint secondMetric secondPoint snapshot text warnings |
	firstPoint := OTNumberDataPoint
		              attributes: { ('http.method' -> 'GET') }
		              value: 1
		              startTimestamp: DateAndTime unixEpoch
		              timestamp: DateAndTime unixEpoch.
	secondPoint := OTNumberDataPoint
		               attributes: { ('http_method' -> 'GET') }
		               value: 2
		               startTimestamp: DateAndTime unixEpoch
		               timestamp: DateAndTime unixEpoch.
	firstMetric := OTSumMetricData new.
	firstMetric
		instrumentationScope: self sampleScope;
		name: 'requests';
		description: 'Request count';
		unit: '1';
		points: { firstPoint };
		monotonic: true;
		temporality: #cumulative.
	secondMetric := OTSumMetricData new.
	secondMetric
		instrumentationScope: self sampleScope;
		name: 'requests';
		description: 'Request count';
		unit: '1';
		points: { secondPoint };
		monotonic: true;
		temporality: #cumulative.
	snapshot := OTMetricSnapshot
		            resource: OTResource empty
		            measurements: #(  )
		            metrics: {
				            firstMetric.
				            secondMetric }
		            collectedAt: DateAndTime unixEpoch.
	warnings := OrderedCollection new.
	encoder warningSink: [ :message | warnings add: message ].
	text := encoder encodeSnapshot: snapshot format: #prometheusText100.
	self assert: (self occurrencesOfSubstring: 'requests_total{' in: text) equals: 1.
	self assert: (text includesSubstring: 'http_method="GET"').
	self assert: warnings size equals: 1.
	self assert: (warnings first includesSubstring: 'duplicate sample identity')
]

{ #category : 'tests' }
OTPrometheusTextEncoderTest >> testEncodeSnapshotEmitsCounterExemplarForOpenMetrics [

	| exemplar metric openMetricsText point prometheusText snapshot timestamp |
	timestamp := DateAndTime unixEpoch + (Duration seconds: 1520879607) + (Duration milliSeconds: 789).
	exemplar := self sampleExemplarValue: 1 timestamp: timestamp.
	exemplar
		traceId: '0123456789abcdef0123456789abcdef';
		spanId: '89abcdef01234567';
		filteredAttributes: { ('user' -> 'alice') }.
	point := OTNumberDataPoint
		         attributes: { ('status' -> '200') }
		         value: 1
		         startTimestamp: DateAndTime unixEpoch
		         timestamp: DateAndTime unixEpoch.
	point exemplars: { exemplar }.
	metric := OTSumMetricData new.
	metric
		instrumentationScope: self sampleScope;
		name: 'requests';
		description: 'Requests';
		unit: '1';
		points: { point };
		monotonic: true;
		temporality: #cumulative.
	snapshot := OTMetricSnapshot
		            resource: OTResource empty
		            measurements: #(  )
		            metrics: { metric }
		            collectedAt: DateAndTime unixEpoch.
	openMetricsText := encoder encodeSnapshot: snapshot format: #openMetricsText100.
	prometheusText := encoder encodeSnapshot: snapshot format: #prometheusText100.
	self assert: (openMetricsText includesSubstring: ' # {').
	self assert: (openMetricsText includesSubstring: 'trace_id="0123456789abcdef0123456789abcdef"').
	self assert: (openMetricsText includesSubstring: 'span_id="89abcdef01234567"').
	self assert: (openMetricsText includesSubstring: 'user="alice"').
	self assert: (openMetricsText includesSubstring: ' 1 1520879607.789').
	self deny: (prometheusText includesSubstring: ' # {')
]

{ #category : 'tests' }
OTPrometheusTextEncoderTest >> testEncodeSnapshotEmitsHistogramExemplarsPerBucketForOpenMetrics [

	| earlierExemplar laterExemplar metric point snapshot text upperBucketExemplar overflowBucketExemplar |
	earlierExemplar := self
		                   sampleExemplarValue: 5
		                   timestamp: DateAndTime unixEpoch + (Duration seconds: 1520879607) + (Duration milliSeconds: 456).
	laterExemplar := self
		                 sampleExemplarValue: 7
		                 timestamp: DateAndTime unixEpoch + (Duration seconds: 1520879607) + (Duration milliSeconds: 789).
	upperBucketExemplar := self
		                       sampleExemplarValue: 15
		                       timestamp: DateAndTime unixEpoch + (Duration seconds: 1520879608) + (Duration milliSeconds: 123).
	overflowBucketExemplar := self
		                          sampleExemplarValue: 25
		                          timestamp: DateAndTime unixEpoch + (Duration seconds: 1520879608) + (Duration milliSeconds: 456).
	point := OTHistogramDataPoint
		         attributes: { ('http.method' -> 'GET') }
		         count: 10
		         sum: 42
		         min: 1
		         max: 25
		         explicitBounds: #( 10 20 )
		         bucketCounts: #( 2 3 5 )
		         startTimestamp: DateAndTime unixEpoch
		         timestamp: DateAndTime unixEpoch.
	point exemplars: {
			earlierExemplar.
			laterExemplar.
			upperBucketExemplar.
			overflowBucketExemplar }.
	metric := OTHistogramMetricData new.
	metric
		instrumentationScope: self sampleScope;
		name: 'request.duration';
		description: 'Request duration';
		unit: 'ms';
		points: { point };
		temporality: #cumulative.
	snapshot := OTMetricSnapshot
		            resource: OTResource empty
		            measurements: #(  )
		            metrics: { metric }
		            collectedAt: DateAndTime unixEpoch.
	text := encoder encodeSnapshot: snapshot format: #openMetricsText100.
	self assert: (self occurrencesOfSubstring: ' # {' in: text) equals: 3.
	self assert: (text includesSubstring: 'le="10"').
	self assert: (text includesSubstring: '# {} 7 1520879607.789').
	self assert: (text includesSubstring: 'le="20"').
	self assert: (text includesSubstring: '# {} 15 1520879608.123').
	self assert: (text includesSubstring: 'le="+Inf"').
	self assert: (text includesSubstring: '# {} 25 1520879608.456')
]

{ #category : 'tests' }
OTPrometheusTextEncoderTest >> testEncodeSnapshotLimitsExemplarLabelsAndPreservesTraceIdentifierPrecedence [

	| exemplar longValue metric point snapshot text |
	longValue := String new: 150 withAll: $x.
	exemplar := self
		            sampleExemplarValue: 1
		            timestamp: DateAndTime unixEpoch + (Duration seconds: 1520879607) + (Duration milliSeconds: 789).
	exemplar
		traceId: '0123456789abcdef0123456789abcdef';
		spanId: '89abcdef01234567';
		filteredAttributes: {
				('trace.id' -> 'wrong-trace-id').
				('user' -> 'alice').
				('overflow' -> longValue) }.
	point := OTNumberDataPoint
		         attributes: { ('status' -> '200') }
		         value: 1
		         startTimestamp: DateAndTime unixEpoch
		         timestamp: DateAndTime unixEpoch.
	point exemplars: { exemplar }.
	metric := OTSumMetricData new.
	metric
		instrumentationScope: self sampleScope;
		name: 'requests';
		description: 'Requests';
		unit: '1';
		points: { point };
		monotonic: true;
		temporality: #cumulative.
	snapshot := OTMetricSnapshot
		            resource: OTResource empty
		            measurements: #(  )
		            metrics: { metric }
		            collectedAt: DateAndTime unixEpoch.
	text := encoder encodeSnapshot: snapshot format: #openMetricsText100.
	self assert: (text includesSubstring: 'trace_id="0123456789abcdef0123456789abcdef"').
	self assert: (text includesSubstring: 'span_id="89abcdef01234567"').
	self assert: (text includesSubstring: 'user="alice"').
	self deny: (text includesSubstring: 'wrong-trace-id').
	self deny: (text includesSubstring: 'overflow=')
]

{ #category : 'tests' }
OTPrometheusTextEncoderTest >> testEncodeSnapshotUsesInfoTypeHintAcrossFormats [

	| metric point prometheusText openMetricsText snapshot |
	point := OTNumberDataPoint
		         attributes: { ('version' -> '1.2.3') }
		         value: 42
		         startTimestamp: DateAndTime unixEpoch
		         timestamp: DateAndTime unixEpoch.
	metric := OTGaugeMetricData new.
	metric
		instrumentationScope: self sampleScope;
		name: 'build';
		description: 'Build metadata';
		unit: 'ms';
		points: { point };
		metadata: { ('prometheus.type' -> 'info') }.
	snapshot := OTMetricSnapshot
		            resource: OTResource empty
		            measurements: #(  )
		            metrics: { metric }
		            collectedAt: DateAndTime unixEpoch.
	prometheusText := encoder encodeSnapshot: snapshot format: #prometheusText100.
	openMetricsText := encoder encodeSnapshot: snapshot format: #openMetricsText100.
	self assert: (prometheusText includesSubstring: '# TYPE build_info gauge').
	self assert: (prometheusText includesSubstring: 'build_info{').
	self assert: (prometheusText includesSubstring: 'version="1.2.3"} 1').
	self deny: (prometheusText includesSubstring: '# UNIT build_info').
	self assert: (openMetricsText includesSubstring: '# TYPE build_info info')
]

{ #category : 'tests' }
OTPrometheusTextEncoderTest >> testEncodeSnapshotUsesStateSetTypeHintAcrossFormats [

	| metric point openMetricsText prometheusText snapshot |
	point := OTNumberDataPoint
		         attributes: { ('connection_state' -> 'idle') }
		         value: 1
		         startTimestamp: DateAndTime unixEpoch
		         timestamp: DateAndTime unixEpoch.
	metric := OTGaugeMetricData new.
	metric
		instrumentationScope: self sampleScope;
		name: 'connection.state';
		description: 'Connection state';
		unit: '1';
		points: { point };
		metadata: { ('prometheus.type' -> 'stateset') }.
	snapshot := OTMetricSnapshot
		            resource: OTResource empty
		            measurements: #(  )
		            metrics: { metric }
		            collectedAt: DateAndTime unixEpoch.
	prometheusText := encoder encodeSnapshot: snapshot format: #prometheusText100.
	openMetricsText := encoder encodeSnapshot: snapshot format: #openMetricsText100.
	self assert: (prometheusText includesSubstring: '# TYPE connection_state gauge').
	self assert: (openMetricsText includesSubstring: '# TYPE connection_state stateset').
	self deny: (openMetricsText includesSubstring: '# UNIT connection_state').
	self assert: (openMetricsText includesSubstring: 'connection_state{connection_state="idle"')
]

{ #category : 'tests' }
OTPrometheusTextEncoderTest >> testEncodeSnapshotUsesUnknownTypeHintAcrossFormats [

	| metric openMetricsText point prometheusText snapshot |
	point := OTNumberDataPoint
		         attributes: { ('method' -> 'GET') }
		         value: 7
		         startTimestamp: DateAndTime unixEpoch
		         timestamp: DateAndTime unixEpoch.
	metric := OTGaugeMetricData new.
	metric
		instrumentationScope: self sampleScope;
		name: 'requests';
		description: 'Requests';
		unit: '1';
		points: { point };
		metadata: { ('prometheus.type' -> 'unkown') }.
	snapshot := OTMetricSnapshot
		            resource: OTResource empty
		            measurements: #(  )
		            metrics: { metric }
		            collectedAt: DateAndTime unixEpoch.
	prometheusText := encoder encodeSnapshot: snapshot format: #prometheusText100.
	openMetricsText := encoder encodeSnapshot: snapshot format: #openMetricsText100.
	self assert: (prometheusText includesSubstring: '# TYPE requests untyped').
	self assert: (openMetricsText includesSubstring: '# TYPE requests unknown').
	self assert: (openMetricsText includesSubstring: 'requests{')
]

{ #category : 'tests' }
OTPrometheusTextEncoderTest >> testEncodeSnapshotWritesCountersScopeLabelsAndTargetInfo [

	| metric point snapshot text |
	point := OTNumberDataPoint
		         attributes: { ('http.method' -> 'GET') }
		         value: 4
		         startTimestamp: DateAndTime unixEpoch
		         timestamp: DateAndTime unixEpoch.
	metric := OTSumMetricData new.
	metric
		instrumentationScope: self sampleScope;
		name: 'http.requests';
		description: 'Request count';
		unit: '1';
		points: { point };
		monotonic: true;
		temporality: #cumulative.
	snapshot := OTMetricSnapshot
		            resource: self sampleResource
		            measurements: #(  )
		            metrics: { metric }
		            collectedAt: DateAndTime unixEpoch.
	text := encoder encodeSnapshot: snapshot.
	self assert: (text includesSubstring: '# TYPE http_requests_total counter').
	self assert: (text includesSubstring: 'http_requests_total{').
	self assert: (text includesSubstring: 'http_method="GET"').
	self assert: (text includesSubstring: 'otel_scope_name="instrumentation"').
	self assert: (text includesSubstring: 'otel_scope_version="1.0.0"').
	self assert: (text includesSubstring: 'otel_scope_schema_url="https://scope.example/schema"').
	self assert: (text includesSubstring: 'otel_scope_scope_key="scope-value"').
	self assert: (text includesSubstring: 'target_info{').
	self assert: (text includesSubstring: 'job="shop/demo"').
	self assert: (text includesSubstring: 'instance="pharo-1"')
]

{ #category : 'tests' }
OTPrometheusTextEncoderTest >> testEncodeSnapshotWritesHistogramBucketsCumulatively [

	| metric point snapshot text |
	point := OTHistogramDataPoint
		         attributes: { ('http.method' -> 'GET') }
		         count: 10
		         sum: 42
		         min: 1
		         max: 25
		         explicitBounds: #( 10 20 )
		         bucketCounts: #( 2 3 5 )
		         startTimestamp: DateAndTime unixEpoch
		         timestamp: DateAndTime unixEpoch.
	metric := OTHistogramMetricData new.
	metric
		instrumentationScope: self sampleScope;
		name: 'request.duration';
		description: 'Request duration';
		unit: 'ms';
		points: { point };
		temporality: #cumulative.
	snapshot := OTMetricSnapshot
		            resource: OTResource empty
		            measurements: #(  )
		            metrics: { metric }
		            collectedAt: DateAndTime unixEpoch.
	text := encoder encodeSnapshot: snapshot.
	self assert: (text includesSubstring: '# TYPE request_duration_milliseconds histogram').
	self assert: (text includesSubstring: 'request_duration_milliseconds_bucket{').
	self assert: (text includesSubstring: 'le="10"').
	self assert: (text includesSubstring: '} 2').
	self assert: (text includesSubstring: 'le="20"').
	self assert: (text includesSubstring: '} 5').
	self assert: (text includesSubstring: 'le="+Inf"').
	self assert: (text includesSubstring: '} 10').
	self assert: (text includesSubstring: 'request_duration_milliseconds_sum{').
	self assert: (text includesSubstring: 'request_duration_milliseconds_count{')
]

{ #category : 'tests' }
OTPrometheusTextEncoderTest >> testEncodeSnapshotWritesSingleHelpLineWhenDescriptionsConflict [

	| firstMetric secondMetric firstPoint secondPoint snapshot text warnings |
	firstPoint := OTNumberDataPoint
		              attributes: { ('source' -> 'one') }
		              value: 1
		              startTimestamp: DateAndTime unixEpoch
		              timestamp: DateAndTime unixEpoch.
	secondPoint := OTNumberDataPoint
		               attributes: { ('source' -> 'two') }
		               value: 2
		               startTimestamp: DateAndTime unixEpoch
		               timestamp: DateAndTime unixEpoch.
	firstMetric := OTSumMetricData new.
	firstMetric
		instrumentationScope: self sampleScope;
		name: 'requests';
		description: 'First description';
		unit: '1';
		points: { firstPoint };
		monotonic: true;
		temporality: #cumulative.
	secondMetric := OTSumMetricData new.
	secondMetric
		instrumentationScope: self sampleScope;
		name: 'requests';
		description: 'Second description';
		unit: '1';
		points: { secondPoint };
		monotonic: true;
		temporality: #cumulative.
	snapshot := OTMetricSnapshot
		            resource: OTResource empty
		            measurements: #(  )
		            metrics: {
				            firstMetric.
				            secondMetric }
		            collectedAt: DateAndTime unixEpoch.
	warnings := OrderedCollection new.
	encoder warningSink: [ :message | warnings add: message ].
	text := encoder encodeSnapshot: snapshot format: #prometheusText100.
	self assert: (self occurrencesOfSubstring: '# HELP requests_total ' in: text) equals: 1.
	self assert: (text includesSubstring: 'source="one"').
	self assert: (text includesSubstring: 'source="two"').
	self assert: warnings size equals: 1.
	self assert: (warnings first includesSubstring: 'HELP')
]

{ #category : 'tests' }
OTPrometheusTextEncoderTest >> testEncodeSnapshotWritesSummaryQuantilesCountAndSum [

	| metric point snapshot text |
	point := OTSummaryDataPoint
		         attributes: { ('http.method' -> 'GET') }
		         count: 2
		         sum: 3.0
		         quantileValues: {
				         (OTSummaryQuantileValue quantile: 0.5 value: 1.5).
				         (OTSummaryQuantileValue quantile: 0.9 value: 2.5) }
		         startTimestamp: DateAndTime unixEpoch
		         timestamp: DateAndTime unixEpoch.
	metric := OTSummaryMetricData new.
	metric
		instrumentationScope: self sampleScope;
		name: 'request.duration';
		description: 'Request duration summary';
		unit: 'ms';
		points: { point }.
	snapshot := OTMetricSnapshot
		            resource: OTResource empty
		            measurements: #(  )
		            metrics: { metric }
		            collectedAt: DateAndTime unixEpoch.
	text := encoder encodeSnapshot: snapshot format: #openMetricsText100.
	self assert: (text includesSubstring: '# TYPE request_duration_milliseconds summary').
	self assert: (text includesSubstring: '# UNIT request_duration_milliseconds milliseconds').
	self assert: (text includesSubstring: 'request_duration_milliseconds{').
	self assert: (text includesSubstring: 'quantile="0.5"} 1.5').
	self assert: (text includesSubstring: 'quantile="0.9"} 2.5').
	self assert: (text includesSubstring: 'request_duration_milliseconds_sum{').
	self assert: (text includesSubstring: 'request_duration_milliseconds_count{')
]

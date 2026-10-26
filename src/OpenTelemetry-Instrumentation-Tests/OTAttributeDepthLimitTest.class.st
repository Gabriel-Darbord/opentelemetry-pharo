Class {
	#name : 'OTAttributeDepthLimitTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'tests' }
OTAttributeDepthLimitTest >> testDepthLimitBoundsCyclesWithoutChangingTheInput [

	| value normalized |
	value := Array new: 1.
	value at: 1 put: value.
	normalized := OTAttributeNormalizer normalizeAttributeValue: value lengthLimit: nil depthLimit: 3.
	self assert: normalized first first first isNil.
	self assert: value first identicalTo: value
]

{ #category : 'tests' }
OTAttributeDepthLimitTest >> testDepthLimitsParticipateInEqualityCopyAndValidation [

	{
		OTSpanLimits.
		OTLogRecordLimits } do: [ :limitClass |
			| limits copy |
			limits := limitClass new.
			self assert: limits attributeValueDepthLimit equals: 64.
			copy := limits copy.
			self assert: limits equals: copy.
			self assert: limits hash equals: copy hash.
			copy attributeValueDepthLimit: 0.
			self deny: limits = copy.
			self assert: limits attributeValueDepthLimit equals: 64.
			#( -1 1.5 '2' ) do: [ :invalid | self should: [ limits attributeValueDepthLimit: invalid ] raise: Error ] ]
]

{ #category : 'tests' }
OTAttributeDepthLimitTest >> testLogAttributesUseDefaultAndConfiguredLimitsButBodyIsExempt [

	| deep limits logRecord value cursor |
	value := #( #( 1 ) ).
	limits := OTLogRecordLimits new
		          attributeValueDepthLimit: 1;
		          yourself.
	logRecord := OTLogRecord new
		             limits: limits;
		             yourself.
	logRecord
		body: value;
		attributeNamed: 'single' put: value;
		attributes: { ('bulk' -> value) }.
	self assert: logRecord body equals: value.
	self assert: (logRecord attributeNamed: 'bulk') equals: #( nil ).
	logRecord attributeNamed: 'single' put: value.
	self assert: (logRecord attributeNamed: 'single') equals: #( nil ).
	deep := 1.
	65 timesRepeat: [ deep := { deep } ].
	logRecord := OTLogRecord new.
	logRecord attributeNamed: 'deep' put: deep.
	cursor := logRecord attributeNamed: 'deep'.
	64 timesRepeat: [ cursor := cursor first ].
	self assert: cursor isNil.
	self assert: ((OTResource attributes: { ('deep' -> deep) }) allAttributes at: 'deep') equals: deep
]

{ #category : 'tests' }
OTAttributeDepthLimitTest >> testMixedContainersAndScalarsAtTheBoundary [

	| value normalized |
	value := { (Dictionary new
		          at: 'child' put: #( 1 );
		          yourself) }.
	normalized := OTAttributeNormalizer normalizeAttributeValue: value lengthLimit: nil depthLimit: 2.
	self assert: (normalized first at: 'child') isNil.
	self assert: (OTAttributeNormalizer normalizeAttributeValue: value lengthLimit: nil depthLimit: 1) equals: #( nil ).
	self assert: (OTAttributeNormalizer normalizeAttributeValue: value lengthLimit: nil depthLimit: 0) isNil.
	{
		1.
		'value'.
		true.
		#[ 1 2 ] } do: [ :scalar |
		self assert: (OTAttributeNormalizer normalizeAttributeValue: scalar lengthLimit: nil depthLimit: 0) equals: scalar ].
	self
		assert: (OTAttributeNormalizer normalizeAttributeValue: #( 'long' #( 1 ) ) lengthLimit: 2 depthLimit: 1)
		equals: #( 'lo' nil )
]

{ #category : 'tests' }
OTAttributeDepthLimitTest >> testSpanAttributesEventsAndLinksUseTheConfiguredDepth [

	| provider span value attributes |
	provider := OTTracerProvider new.
	provider spanProcessor: (OTSimpleSpanProcessor new
			 exporter: OTNoopSpanExporter new;
			 yourself).
	provider spanLimits: (OTSpanLimits new
			 attributeValueDepthLimit: 1;
			 yourself).
	value := #( #( 1 ) ).
	attributes := { ('nested' -> value) }.
	[
		span := ((provider tracerNamed: 'limits') spanBuilderNamed: 'operation')
			        attributes: attributes;
			        startSpan.
		self assert: (span attributes at: 'nested') equals: #( nil ).
		span attributeAt: 'direct' put: value.
		self assert: (span attributes at: 'direct') equals: #( nil ).
		span addEventNamed: 'event' attributes: attributes.
		span addLink: (OTSpanLink spanContext: span spanContext attributes: attributes).
		self assert: (span events first attributes at: 'nested') equals: #( nil ).
		self assert: (span links first attributes at: 'nested') equals: #( nil ).
		span end ] ensure: [ provider shutdown ]
]

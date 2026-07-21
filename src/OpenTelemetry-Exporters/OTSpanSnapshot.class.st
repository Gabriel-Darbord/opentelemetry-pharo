"
Internal immutable export snapshot for ended spans. Processors/exporters use this to decouple export data from the live OTSpan API surface.
"
Class {
	#name : 'OTSpanSnapshot',
	#superclass : 'Object',
	#instVars : [
		'spanContext',
		'parentSpanContext',
		'name',
		'kind',
		'startTime',
		'endTime',
		'status',
		'statusDescription',
		'attributes',
		'events',
		'links',
		'resource',
		'instrumentationScope',
		'droppedAttributesCount',
		'droppedEventsCount',
		'droppedLinksCount'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'instance creation' }
OTSpanSnapshot class >> fromExportableSpan: anObject [

	^ anObject class == self
		  ifTrue: [ anObject ]
		  ifFalse: [ self fromSpan: anObject ]
]

{ #category : 'instance creation' }
OTSpanSnapshot class >> fromSpan: aSpan [

	^ self new initializeFromSpan: aSpan
]

{ #category : 'accessing' }
OTSpanSnapshot >> asExportRecord [

	| data |
	data := OrderedDictionary new.
	data
		at: #spanId put: self spanId;
		at: #traceId put: self traceId;
		at: #name put: name;
		at: #kind put: kind;
		at: #startTime put: startTime;
		at: #endTime put: endTime;
		at: #status put: self status;
		at: #traceFlags put: self traceFlags;
		at: #instrumentationName put: self instrumentationScope name.
	self instrumentationScope isEmpty ifFalse: [ data at: #instrumentationScope put: self instrumentationScope ].
	self parentSpanContext ifNotNil: [ :aParentContext |
			data
				at: #parentSpanContext put: aParentContext;
				at: #parentId put: aParentContext spanId ].
	self traceState ifNotNil: [ :aTraceState | data at: #traceState put: aTraceState asHeaderValue ].
	self statusDescription ifNotNil: [ :description | data at: #statusDescription put: description ].
	attributes isEmptyOrNil ifFalse: [ data at: #attributes put: attributes ].
	events isEmptyOrNil ifFalse: [ data at: #events put: events ].
	self links ifNotEmpty: [ data at: #links put: self links ].
	self resource isEmpty ifFalse: [ data at: #resource put: self resource ].
	self droppedAttributesCount > 0 ifTrue: [ data at: #droppedAttributesCount put: self droppedAttributesCount ].
	self droppedEventsCount > 0 ifTrue: [ data at: #droppedEventsCount put: self droppedEventsCount ].
	self droppedLinksCount > 0 ifTrue: [ data at: #droppedLinksCount put: self droppedLinksCount ].
	^ data
]

{ #category : 'accessing' }
OTSpanSnapshot >> attributes [

	^ attributes
]

{ #category : 'accessing' }
OTSpanSnapshot >> droppedAttributesCount [

	^ droppedAttributesCount
]

{ #category : 'accessing' }
OTSpanSnapshot >> droppedEventsCount [

	^ droppedEventsCount
]

{ #category : 'accessing' }
OTSpanSnapshot >> droppedLinksCount [

	^ droppedLinksCount
]

{ #category : 'accessing' }
OTSpanSnapshot >> endTime [

	^ endTime
]

{ #category : 'accessing' }
OTSpanSnapshot >> events [

	^ events
]

{ #category : 'accessing' }
OTSpanSnapshot >> hasEnded [

	^ endTime notNil
]

{ #category : 'initialization' }
OTSpanSnapshot >> initializeFromSpan: aSpan [

	| record |
	record := aSpan asExportRecord.
	spanContext := aSpan spanContext.
	parentSpanContext := record at: #parentSpanContext ifAbsent: [ nil ].
	name := record at: #name.
	kind := record at: #kind.
	startTime := record at: #startTime.
	endTime := record at: #endTime.
	status := record at: #status.
	statusDescription := record at: #statusDescription ifAbsent: [ nil ].
	attributes := (record at: #attributes ifAbsent: [ OrderedDictionary new ]) copy.
	events := (record at: #events ifAbsent: [ #(  ) ]) copy.
	links := (record at: #links ifAbsent: [ #(  ) ]) copy.
	resource := record at: #resource ifAbsent: [ OTResource empty ].
	instrumentationScope := record
		                        at: #instrumentationScope
		                        ifAbsent: [ OTInstrumentationScope named: (record at: #instrumentationName ifAbsent: [ '' ]) ].
	droppedAttributesCount := record at: #droppedAttributesCount ifAbsent: [ 0 ].
	droppedEventsCount := record at: #droppedEventsCount ifAbsent: [ 0 ].
	droppedLinksCount := record at: #droppedLinksCount ifAbsent: [ 0 ]
]

{ #category : 'accessing' }
OTSpanSnapshot >> instrumentationName [

	^ self instrumentationScope name
]

{ #category : 'accessing' }
OTSpanSnapshot >> instrumentationScope [

	^ instrumentationScope
]

{ #category : 'accessing' }
OTSpanSnapshot >> instrumentationVersion [

	^ self instrumentationScope version
]

{ #category : 'accessing' }
OTSpanSnapshot >> kind [

	^ kind
]

{ #category : 'accessing' }
OTSpanSnapshot >> links [

	^ links
]

{ #category : 'accessing' }
OTSpanSnapshot >> name [

	^ name
]

{ #category : 'accessing' }
OTSpanSnapshot >> parentSpanContext [

	^ parentSpanContext
]

{ #category : 'printing' }
OTSpanSnapshot >> printOn: aStream [

	aStream
		nextPutAll: 'Span[';
		nextPutAll: self instrumentationScope name;
		nextPutAll: ': ';
		nextPutAll: (name ifNil: [ '' ]);
		nextPut: $]
]

{ #category : 'accessing' }
OTSpanSnapshot >> resource [

	^ resource
]

{ #category : 'accessing' }
OTSpanSnapshot >> spanContext [

	^ spanContext
]

{ #category : 'accessing' }
OTSpanSnapshot >> spanId [

	^ spanContext spanId
]

{ #category : 'accessing' }
OTSpanSnapshot >> startTime [

	^ startTime
]

{ #category : 'accessing' }
OTSpanSnapshot >> status [

	^ status
]

{ #category : 'accessing' }
OTSpanSnapshot >> statusDescription [

	^ statusDescription
]

{ #category : 'ston persistence' }
OTSpanSnapshot >> stonOn: stonWriter [

	stonWriter writeObject: self streamMap: [ :map |
			map
				at: #spanId put: self spanId;
				at: #traceId put: self traceId;
				at: #name put: name;
				at: #kind put: kind;
				at: #startTime put: startTime;
				at: #endTime put: endTime;
				at: #status put: self status;
				at: #traceFlags put: self traceFlags;
				at: #instrumentationName put: self instrumentationScope name.
			self instrumentationScope isEmpty ifFalse: [ map at: #instrumentationScope put: self instrumentationScope ].
			self parentSpanContext ifNotNil: [ :aParentContext |
					map
						at: #parentSpanContext put: aParentContext;
						at: #parentId put: aParentContext spanId ].
			self traceState ifNotNil: [ :aTraceState | map at: #traceState put: aTraceState asHeaderValue ].
			self statusDescription ifNotNil: [ :description | map at: #statusDescription put: description ].
			attributes isEmptyOrNil ifFalse: [ map at: #attributes put: attributes ].
			events isEmptyOrNil ifFalse: [ map at: #events put: events ].
			self links ifNotEmpty: [ map at: #links put: self links ].
			self resource isEmpty ifFalse: [ map at: #resource put: self resource ].
			self droppedAttributesCount > 0 ifTrue: [ map at: #droppedAttributesCount put: self droppedAttributesCount ].
			self droppedEventsCount > 0 ifTrue: [ map at: #droppedEventsCount put: self droppedEventsCount ].
			self droppedLinksCount > 0 ifTrue: [ map at: #droppedLinksCount put: self droppedLinksCount ] ]
]

{ #category : 'accessing' }
OTSpanSnapshot >> traceFlags [

	^ spanContext traceFlags
]

{ #category : 'accessing' }
OTSpanSnapshot >> traceId [

	^ spanContext traceId
]

{ #category : 'accessing' }
OTSpanSnapshot >> traceState [

	^ spanContext traceState
]

Class {
	#name : 'OTExponentialBucketRange',
	#superclass : 'Object',
	#instVars : [
		'offset',
		'bucketCounts'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTExponentialBucketRange class >> offset: anInteger bucketCounts: aCollection [

	| range |
	range := self new.
	range
		offset: anInteger;
		bucketCounts: aCollection.
	^ range
]

{ #category : 'accessing' }
OTExponentialBucketRange >> bucketCounts [

	^ bucketCounts ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
OTExponentialBucketRange >> bucketCounts: aCollection [

	bucketCounts := aCollection ifNil: [ #(  ) ] ifNotNil: [ aCollection asArray ]
]

{ #category : 'accessing' }
OTExponentialBucketRange >> offset [

	^ offset ifNil: [ 0 ]
]

{ #category : 'accessing' }
OTExponentialBucketRange >> offset: anInteger [

	offset := anInteger ifNil: [ 0 ] ifNotNil: [ anInteger ]
]

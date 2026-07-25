"
I select which attributes survive into an aggregated metric stream.
I can keep only named keys, drop named keys, or pass everything through.
"
Class {
	#name : 'OTMetricAttributeFilter',
	#superclass : 'Object',
	#instVars : [
		'includedKeys',
		'excludedKeys'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTMetricAttributeFilter class >> all [

	^ self new
]

{ #category : 'instance creation' }
OTMetricAttributeFilter class >> included: someIncludedKeys excluded: someExcludedKeys [

	^ self new
		  includedKeys: someIncludedKeys;
		  excludedKeys: someExcludedKeys;
		  yourself
]

{ #category : 'accessing' }
OTMetricAttributeFilter >> excludedKeys [

	^ excludedKeys
]

{ #category : 'accessing' }
OTMetricAttributeFilter >> excludedKeys: aCollection [

	excludedKeys := aCollection ifNil: [ nil ] ifNotNil: [ aCollection collect: [ :each | each asString ] ]
]

{ #category : 'accessing' }
OTMetricAttributeFilter >> includedKeys [

	^ includedKeys
]

{ #category : 'accessing' }
OTMetricAttributeFilter >> includedKeys: aCollection [

	includedKeys := aCollection ifNil: [ nil ] ifNotNil: [ aCollection collect: [ :each | each asString ] ]
]

{ #category : 'testing' }
OTMetricAttributeFilter >> isAll [

	^ includedKeys isNil and: [ excludedKeys isNil ]
]

{ #category : 'filtering' }
OTMetricAttributeFilter >> selectedAttributesFrom: anOrderedDictionary [

	| selected |
	selected := includedKeys ifNil: [ anOrderedDictionary copy ] ifNotNil: [
			            includedKeys inject: OrderedDictionary new into: [ :filtered :each |
					            anOrderedDictionary at: each ifPresent: [ :value | filtered at: each put: value ].
					            filtered ] ].
	excludedKeys ifNil: [ ^ selected ].
	excludedKeys do: [ :each | selected removeKey: each ifAbsent: [ ] ].
	^ selected
]

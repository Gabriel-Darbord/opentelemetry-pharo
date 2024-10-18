"
A matcher that uses a one-arg block to evaluate whether to accept a given element.
"
Class {
	#name : 'OTPluggableMatcher',
	#superclass : 'OTMatcher',
	#instVars : [
		'block'
	],
	#category : 'OpenTelemetry-Matchers',
	#package : 'OpenTelemetry-Matchers'
}

{ #category : 'accessing' }
OTPluggableMatcher >> block [

	^ block
]

{ #category : 'accessing' }
OTPluggableMatcher >> block: aBlock [

	block := aBlock
]

{ #category : 'testing' }
OTPluggableMatcher >> matches: target [

	^ block value: target
]

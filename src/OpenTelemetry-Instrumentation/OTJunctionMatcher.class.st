"
A junction allows to chain different `OTMatcher`s in a readable manner.
"
Class {
	#name : 'OTJunctionMatcher',
	#superclass : 'OTMatcher',
	#instVars : [
		'matchers'
	],
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'instance creation' }
OTJunctionMatcher class >> withAll: matchers [

	^ self new matchers: matchers asOrderedCollection
]

{ #category : 'accessing' }
OTJunctionMatcher >> matchers [

	^ matchers
]

{ #category : 'accessing' }
OTJunctionMatcher >> matchers: aCollection [

	matchers := aCollection
]

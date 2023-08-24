Class {
	#name : #OTContext,
	#superclass : #Object,
	#instVars : [
		'currentSpan'
	],
	#category : #'OpenTelemetry-Instrumentation'
}

{ #category : #'accessing - context' }
OTContext >> currentSpan [

	^ currentSpan
]

{ #category : #accessing }
OTContext >> currentSpan: aSpan [

	currentSpan := aSpan
]

{ #category : #initialization }
OTContext >> initialize [
	"TODO gather data on executor"
]

"
A minimal MeterConfig for provider-side meter enablement decisions.
"
Class {
	#name : 'OTMeterConfig',
	#superclass : 'Object',
	#instVars : [
		'enabled'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTMeterConfig class >> default [

	^ self new
]

{ #category : 'instance creation' }
OTMeterConfig class >> enabled: aBoolean [

	^ self new
		enabled: aBoolean;
		yourself
]

{ #category : 'copying' }
OTMeterConfig >> copy [

	^ self class enabled: self enabled
]

{ #category : 'accessing' }
OTMeterConfig >> enabled [

	^ enabled ifNil: [ true ]
]

{ #category : 'accessing' }
OTMeterConfig >> enabled: aBoolean [

	enabled := aBoolean ifNil: [ true ] ifNotNil: [ aBoolean ]
]

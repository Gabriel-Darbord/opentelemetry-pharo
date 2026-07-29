"
An immutable self-observability component identity.

I pair one low-cardinality component type with one SDK-instance-local component name and the common attributes derived from them.
"
Class {
	#name : 'OTSdkSelfObservabilityComponent',
	#superclass : 'Object',
	#instVars : [
		'type',
		'name',
		'attributes'
	],
	#category : 'OpenTelemetry-SDK',
	#package : 'OpenTelemetry-SDK'
}

{ #category : 'instance creation' }
OTSdkSelfObservabilityComponent class >> type: aTypeString name: aNameString [

	^ self new
		  type: aTypeString;
		  name: aNameString;
		  attributes: {
				  ('otel.component.type' -> aTypeString).
				  ('otel.component.name' -> aNameString) } asDictionary;
		  yourself
]

{ #category : 'accessing' }
OTSdkSelfObservabilityComponent >> attributes [

	^ attributes
]

{ #category : 'accessing' }
OTSdkSelfObservabilityComponent >> attributes: aDictionary [

	attributes := aDictionary
]

{ #category : 'accessing' }
OTSdkSelfObservabilityComponent >> name [

	^ name
]

{ #category : 'accessing' }
OTSdkSelfObservabilityComponent >> name: aString [

	name := aString
]

{ #category : 'accessing' }
OTSdkSelfObservabilityComponent >> type [

	^ type
]

{ #category : 'accessing' }
OTSdkSelfObservabilityComponent >> type: aString [

	type := aString
]

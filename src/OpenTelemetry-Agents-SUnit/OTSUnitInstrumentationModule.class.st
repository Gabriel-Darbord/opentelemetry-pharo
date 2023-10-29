Class {
	#name : #OTSUnitInstrumentationModule,
	#superclass : #OTInstrumentationModule,
	#category : #'OpenTelemetry-Agents-SUnit'
}

{ #category : #accessing }
OTSUnitInstrumentationModule class >> instrumentationName [

	^ 'sunit'
]

{ #category : #accessing }
OTSUnitInstrumentationModule class >> typeInstrumentations [

	^ { OTSUnitInstrumentation }
]

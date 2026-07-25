Class {
	#name : 'OTW3CBaggagePropagatorTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'tests' }
OTW3CBaggagePropagatorTest >> testExtractCountsDuplicateMembersTowardEntryLimit [

	| baggage carrier context duplicateMembers header |
	duplicateMembers := OrderedCollection new.
	64 timesRepeat: [ duplicateMembers add: 'user.id=42' ].
	duplicateMembers add: 'tenant.id=acme'.
	header := String streamContents: [ :stream |
			          duplicateMembers doWithIndex: [ :each :index |
					          index > 1 ifTrue: [ stream nextPut: $, ].
					          stream nextPutAll: each ] ].
	carrier := Dictionary new
		           at: 'baggage' put: header;
		           yourself.
	context := OTW3CBaggagePropagator current extract: OTContext new from: carrier.
	baggage := context baggage.
	self assert: baggage size equals: 1.
	self assert: (baggage valueAt: 'user.id') equals: '42'.
	self deny: (baggage includesEntryNamed: 'tenant.id')
]

{ #category : 'tests' }
OTW3CBaggagePropagatorTest >> testExtractDecodesPercentEncodedMetadata [

	| baggage carrier context |
	carrier := Dictionary new
		           at: 'baggage' put: 'user.id=42;source%3Dcrm%3Btier%3Dgold';
		           yourself.
	context := OTW3CBaggagePropagator current extract: OTContext new from: carrier.
	baggage := context baggage.
	self assert: (baggage valueAt: 'user.id') equals: '42'.
	self assert: (baggage entryAt: 'user.id') metadata asString equals: 'source=crm;tier=gold'
]

{ #category : 'tests' }
OTW3CBaggagePropagatorTest >> testExtractDropsMembersWithInvalidMetadataPercentEncodingAndKeepsValidOnes [

	| baggage carrier context |
	carrier := Dictionary new
		           at: 'baggage' put: 'good=value,bad=value;meta=%GG,encoded=value%202';
		           yourself.
	context := OTW3CBaggagePropagator current extract: OTContext new from: carrier.
	baggage := context baggage.
	self assert: baggage size equals: 2.
	self assert: (baggage valueAt: 'good') equals: 'value'.
	self assert: (baggage valueAt: 'encoded') equals: 'value 2'.
	self deny: (baggage includesEntryNamed: 'bad')
]

{ #category : 'tests' }
OTW3CBaggagePropagatorTest >> testExtractStopsAtConfiguredEntryLimit [

	| carrier context firstAccepted lastAccepted header |
	firstAccepted := 'first'.
	lastAccepted := 'entry' , OTW3CBaggagePropagator maxBaggageEntries asString.
	header := String streamContents: [ :stream |
			          1 to: OTW3CBaggagePropagator maxBaggageEntries + 1 do: [ :index |
					          index > 1 ifTrue: [ stream nextPut: $, ].
					          stream
						          nextPutAll: 'entry';
						          nextPutAll: index asString;
						          nextPut: $=;
						          nextPutAll: (index = 1
								           ifTrue: [ firstAccepted ]
								           ifFalse: [
										           index = OTW3CBaggagePropagator maxBaggageEntries
											           ifTrue: [ lastAccepted ]
											           ifFalse: [ 'value' ] ]) ] ].
	carrier := Dictionary new
		           at: 'baggage' put: header;
		           yourself.
	context := OTW3CBaggagePropagator new extract: OTContext new from: carrier.
	self assert: context baggage size equals: OTW3CBaggagePropagator maxBaggageEntries.
	self assert: (context baggage valueAt: 'entry1') equals: firstAccepted.
	self assert: (context baggage valueAt: 'entry' , OTW3CBaggagePropagator maxBaggageEntries asString) equals: lastAccepted.
	self deny: (context baggage includesEntryNamed: 'entry' , (OTW3CBaggagePropagator maxBaggageEntries + 1) asString)
]

{ #category : 'tests' }
OTW3CBaggagePropagatorTest >> testExtractUsesLastValueForDuplicateKeysAcrossHeaders [

	| baggage carrier context |
	carrier := Dictionary new
		           at: 'baggage' put: #( 'user.id=41' 'user.id=42' );
		           yourself.
	context := OTW3CBaggagePropagator current extract: OTContext new from: carrier.
	baggage := context baggage.
	self assert: baggage size equals: 1.
	self assert: (baggage valueAt: 'user.id') equals: '42'
]

{ #category : 'tests' }
OTW3CBaggagePropagatorTest >> testInjectDropsOversizedMembersWithoutProducingPartialOnes [

	| baggage carrier encoded firstValue propagated secondValue |
	firstValue := String new: OTW3CBaggagePropagator maxBaggageBytes - 10 withAll: $a.
	secondValue := 'second'.
	baggage := OTBaggage empty
		           withEntryNamed: 'first' value: firstValue;
		           withEntryNamed: 'second' value: secondValue.
	carrier := Dictionary new.
	OTW3CBaggagePropagator new inject: (OTContext new withBaggage: baggage) into: carrier.
	encoded := carrier at: 'baggage'.
	self assert: encoded size <= OTW3CBaggagePropagator maxBaggageBytes.
	propagated := OTW3CBaggagePropagator new baggageFromHeader: encoded.
	self assert: propagated size equals: 1.
	self deny: (propagated includesEntryNamed: 'first').
	self assert: (propagated valueAt: 'second') equals: secondValue
]

{ #category : 'tests' }
OTW3CBaggagePropagatorTest >> testInjectPercentEncodesMetadata [

	| baggage carrier context |
	baggage := OTBaggage empty withEntryNamed: 'user.id' value: '42' metadata: 'source=crm;tier=gold'.
	context := OTContext new withBaggage: baggage.
	carrier := Dictionary new.
	OTW3CBaggagePropagator current inject: context into: carrier.
	self assert: (carrier at: 'baggage') equals: 'user.id=42;source%3Dcrm%3Btier%3Dgold'
]

Class {
	#name : 'OTMethodProxyInstaller',
	#superclass : 'OTAgentInstaller',
	#instVars : [
		'proxy'
	],
	#category : 'OpenTelemetry-Instrumentation-MethodProxy',
	#package : 'OpenTelemetry-Instrumentation-MethodProxy'
}

{ #category : 'actions' }
OTMethodProxyInstaller class >> cleanupInstrumentation: anInstrumentation [

	| classMatcher |
	classMatcher := anInstrumentation classMatcher.
	anInstrumentation packageMatcher matchingPackagesDo: [ :package |
			classMatcher matching: package classes do: [ :class |
					self restoreMethodProxyArtifactsIn: class.
					self restoreMethodProxyArtifactsIn: class class ] ]
]

{ #category : 'actions' }
OTMethodProxyInstaller class >> installInstrumentation: anInstrumentation [

	self cleanupInstrumentation: anInstrumentation.
	super installInstrumentation: anInstrumentation
]

{ #category : 'testing' }
OTMethodProxyInstaller class >> isMethodProxyArtifact: aMethod [

	^ (aMethod selector isKindOf: MpHiddenSelector) or: [ self isMethodProxyTrap: aMethod ]
]

{ #category : 'testing' }
OTMethodProxyInstaller class >> isMethodProxyTrap: aMethod [

	^ (aMethod hasPragmaNamed: #trap) or: [ aMethod sourceCode beginsWith: 'trapMethod' ]
]

{ #category : 'private' }
OTMethodProxyInstaller class >> originalMethodFrom: methods [

	^ methods detect: [ :method | (self isMethodProxyTrap: method) not ] ifNone: [ methods first ]
]

{ #category : 'actions' }
OTMethodProxyInstaller class >> restoreMethodProxyArtifactsIn: aBehavior [

	| hiddenSelectors groupedMethods |
	hiddenSelectors := aBehavior localSelectors select: [ :selector | selector isKindOf: MpHiddenSelector ].
	hiddenSelectors ifEmpty: [ ^ self ].

	groupedMethods := Dictionary new.
	hiddenSelectors do: [ :hiddenSelector |
			(groupedMethods at: hiddenSelector proxifiedSelector ifAbsentPut: [ OrderedCollection new ]) add:
				(aBehavior compiledMethodAt: hiddenSelector) ].

	groupedMethods keysAndValuesDo: [ :selector :methods |
			| method |
			method := self originalMethodFrom: methods.
			method selector: selector.
			aBehavior addSelectorSilently: selector withMethod: method ].

	hiddenSelectors do: [ :hiddenSelector | aBehavior removeSelectorSilently: hiddenSelector ].
	aBehavior flushCache
]

{ #category : 'actions' }
OTMethodProxyInstaller class >> uninstallInstrumentation: anInstrumentation [

	anInstrumentation reset.
	MpMethodProxy allSubInstancesDo: [ :proxy | proxy handler == anInstrumentation ifTrue: [ proxy uninstall ] ].
	self cleanupInstrumentation: anInstrumentation.
	MpMethodProxy enableInstrumentation "keep proxies enabled"
]

{ #category : 'private' }
OTMethodProxyInstaller >> instrument: aMethod [
	"This is a private method, do not use this!
	Install the method proxy on the instrumented method."

	proxy install enableInstrumentation
]

{ #category : 'private' }
OTMethodProxyInstaller >> shouldInstrument: aMethod with: anInstrumentation [
	"A bit weird but this is when the proxy is created"

	(self class isMethodProxyArtifact: aMethod) ifTrue: [ ^ false ].
	proxy := MpMethodProxy onMethod: aMethod handler: anInstrumentation.
	^ true "proxy used to have a `shouldWrap:` method"
]

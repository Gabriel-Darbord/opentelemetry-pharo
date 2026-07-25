"
I am the base class for MetaLink-backed instrumentations.
I derive the MetaLink control flow from the hooks implemented by a concrete instrumentation and provide the runtime entry points for those hooks.
"
Class {
	#name : 'OTMetaLinkInstrumentation',
	#superclass : 'OTInstrumentation',
	#category : 'OpenTelemetry-Instrumentation-MetaLink',
	#package : 'OpenTelemetry-Instrumentation-MetaLink'
}

{ #category : 'testing' }
OTMetaLinkInstrumentation class >> hasMethodEnterHook [

	| implementor |
	implementor := self classSide whichClassIncludesSelector: #onMethodEnter:.
	^ implementor notNil and: [ implementor ~= OTMetaLinkInstrumentation class ]
]

{ #category : 'testing' }
OTMetaLinkInstrumentation class >> hasMethodExceptionHook [

	| implementor |
	implementor := self classSide whichClassIncludesSelector: #onMethodException:error:.
	^ implementor notNil and: [ implementor ~= OTMetaLinkInstrumentation class ]
]

{ #category : 'testing' }
OTMetaLinkInstrumentation class >> hasMethodExitHook [

	| implementor |
	implementor := self classSide whichClassIncludesSelector: #onMethodExit:withValue:.
	^ implementor notNil and: [ implementor ~= OTMetaLinkInstrumentation class ]
]

{ #category : 'configuring' }
OTMetaLinkInstrumentation class >> installer [

	^ OTMetaLinkInstaller
]

{ #category : 'testing' }
OTMetaLinkInstrumentation class >> isAbstract [

	^ self == OTMetaLinkInstrumentation
]

{ #category : 'configuring' }
OTMetaLinkInstrumentation class >> metalinkControl [

	^ (self usesMethodExitHook or: [ self usesMethodExceptionHook ])
		  ifTrue: [ #instead ]
		  ifFalse: [ #before ]
]

{ #category : 'configuring' }
OTMetaLinkInstrumentation class >> metalinkSelector [

	self usesMethodExitHook ifFalse: [
			self usesMethodExceptionHook ifFalse: [ ^ #runBefore: ].
			self usesMethodEnterHook
				ifTrue: [ ^ #runWithEnterAndExceptionHandling: ]
				ifFalse: [ ^ #runWithExceptionHandling: ] ].
	self usesMethodExceptionHook ifFalse: [
			self usesMethodEnterHook
				ifTrue: [ ^ #runWithEnterAndExit: ]
				ifFalse: [ ^ #runWithExit: ] ].
	self usesMethodEnterHook
		ifTrue: [ ^ #runWithEnterExitAndExceptionHandling: ]
		ifFalse: [ ^ #runWithExitAndExceptionHandling: ]
]

{ #category : 'evaluating' }
OTMetaLinkInstrumentation class >> onMethodEnter: event [
	"This method is executed BEFORE the instrumented method.
	The event contains the RFMethodOperation plus the data requested in #configure:."

	
]

{ #category : 'evaluating' }
OTMetaLinkInstrumentation class >> onMethodException: event error: anException [
	"This method is executed when the instrumented method exits through an unhandled exception.
	The first argument contains the RFMethodOperation plus the data requested in #configure:.
	The second contains the exception raised by the instrumented method."

	
]

{ #category : 'evaluating' }
OTMetaLinkInstrumentation class >> onMethodExit: event withValue: returnValue [
	"This method is executed AFTER the instrumented method.
	The first argument contains the RFMethodOperation plus the data requested in #configure:.
	The second contains the return value of the method."

	
]

{ #category : 'private' }
OTMetaLinkInstrumentation class >> run: arguments [
	"Compatibility entry point. Installed MetaLinks should use the more specific selectors."

	^ self perform: self metalinkSelector with: arguments
]

{ #category : 'private' }
OTMetaLinkInstrumentation class >> runBefore: arguments [

	sampler ifNotNil: [ sampler shouldSample ifFalse: [ ^ self ] ].
	self onMethodEnter: arguments
]

{ #category : 'private' }
OTMetaLinkInstrumentation class >> runWithEnterAndExceptionHandling: arguments [

	sampler ifNotNil: [ sampler shouldSample ifFalse: [ ^ arguments first value ] ].
	self onMethodEnter: arguments.
	^ [ arguments first value ]
		  on: Exception
		  do: [ :error |
				  self onMethodException: arguments error: error.
				  error pass ]
]

{ #category : 'private' }
OTMetaLinkInstrumentation class >> runWithEnterAndExit: arguments [

	| returnValue |
	sampler ifNotNil: [ sampler shouldSample ifFalse: [ ^ arguments first value ] ].
	self onMethodEnter: arguments.
	^ [ returnValue := arguments first value ] ensure: [ self onMethodExit: arguments withValue: returnValue ]
]

{ #category : 'private' }
OTMetaLinkInstrumentation class >> runWithEnterExitAndExceptionHandling: arguments [

	| returnValue |
	sampler ifNotNil: [ sampler shouldSample ifFalse: [ ^ arguments first value ] ].
	self onMethodEnter: arguments.
	^ [
		  [ returnValue := arguments first value ]
			  on: Exception
			  do: [ :error |
					  self onMethodException: arguments error: error.
					  error pass ] ] ensure: [ self onMethodExit: arguments withValue: returnValue ]
]

{ #category : 'private' }
OTMetaLinkInstrumentation class >> runWithExceptionHandling: arguments [

	sampler ifNotNil: [ sampler shouldSample ifFalse: [ ^ arguments first value ] ].
	^ [ arguments first value ]
		  on: Exception
		  do: [ :error |
				  self onMethodException: arguments error: error.
				  error pass ]
]

{ #category : 'private' }
OTMetaLinkInstrumentation class >> runWithExit: arguments [

	| returnValue |
	sampler ifNotNil: [ sampler shouldSample ifFalse: [ ^ arguments first value ] ].
	^ [ returnValue := arguments first value ] ensure: [ self onMethodExit: arguments withValue: returnValue ]
]

{ #category : 'private' }
OTMetaLinkInstrumentation class >> runWithExitAndExceptionHandling: arguments [

	| returnValue |
	sampler ifNotNil: [ sampler shouldSample ifFalse: [ ^ arguments first value ] ].
	^ [
		  [ returnValue := arguments first value ]
			  on: Exception
			  do: [ :error |
					  self onMethodException: arguments error: error.
					  error pass ] ] ensure: [ self onMethodExit: arguments withValue: returnValue ]
]

{ #category : 'configuring' }
OTMetaLinkInstrumentation class >> usesMethodEnterHook [

	^ self hasMethodEnterHook
]

{ #category : 'configuring' }
OTMetaLinkInstrumentation class >> usesMethodExceptionHook [

	^ self hasMethodExceptionHook
]

{ #category : 'configuring' }
OTMetaLinkInstrumentation class >> usesMethodExitHook [

	^ self hasMethodExitHook
]

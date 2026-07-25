Class {
	#name : 'OTMethodProxyPassThrough',
	#superclass : 'MpMethodProxy',
	#category : 'OpenTelemetry-Instrumentation-MethodProxy',
	#package : 'OpenTelemetry-Instrumentation-MethodProxy'
}

{ #category : 'class initialization' }
OTMethodProxyPassThrough class >> initialize [

	self buildPrototypesUpToArguments: 15
]

{ #category : 'evaluating' }
OTMethodProxyPassThrough class >> prototypeTrap [
	"The unwind handler should be the first temp.
	The complete flag should be the second temp."

	<trap>
	<debuggerCompleteToSender>
	<primitive: 198>
	| deactivator complete result process |
	ENABLED ifFalse: [ ^ self originalMessage ].
	process := Processor activeProcess.
	process isMeta ifTrue: [ ^ self originalMessage ].
	deactivator := #slowdeactivator.
	result := self originalMessage.
	complete := true.
	^ result
]

{ #category : 'as yet unclassified' }
OTMethodProxyPassThrough class >> trapMethod [
	"The unwind handler should be the first temp.
	The complete flag should be the second temp."

	<trap>
	<debuggerCompleteToSender>
	<primitive: 198>
	| deactivator complete result process |
	ENABLED ifFalse: [ ^ self trapMethod ].
	process := Processor activeProcess.
	process isMeta ifTrue: [ ^ self trapMethod ].
	deactivator := #slowdeactivator.
	result := self trapMethod.
	complete := true.
	^ result
]

{ #category : 'as yet unclassified' }
OTMethodProxyPassThrough class >> trapMethodwith: arg1 [
	"The unwind handler should be the first temp.
	The complete flag should be the second temp."

	<trap>
	<debuggerCompleteToSender>
	<primitive: 198>
	| deactivator complete result process |
	ENABLED ifFalse: [ ^ self trapMethodwith: arg1 ].
	process := Processor activeProcess.
	process isMeta ifTrue: [ ^ self trapMethodwith: arg1 ].
	deactivator := #slowdeactivator.
	result := self trapMethodwith: arg1.
	complete := true.
	^ result
]

{ #category : 'as yet unclassified' }
OTMethodProxyPassThrough class >> trapMethodwith: arg1 with: arg2 [
	"The unwind handler should be the first temp.
	The complete flag should be the second temp."

	<trap>
	<debuggerCompleteToSender>
	<primitive: 198>
	| deactivator complete result process |
	ENABLED ifFalse: [ ^ self trapMethodwith: arg1 with: arg2 ].
	process := Processor activeProcess.
	process isMeta ifTrue: [ ^ self trapMethodwith: arg1 with: arg2 ].
	deactivator := #slowdeactivator.
	result := self trapMethodwith: arg1 with: arg2.
	complete := true.
	^ result
]

{ #category : 'as yet unclassified' }
OTMethodProxyPassThrough class >> trapMethodwith: arg1 with: arg2 with: arg3 [
	"The unwind handler should be the first temp.
	The complete flag should be the second temp."

	<trap>
	<debuggerCompleteToSender>
	<primitive: 198>
	| deactivator complete result process |
	ENABLED ifFalse: [ ^ self trapMethodwith: arg1 with: arg2 with: arg3 ].
	process := Processor activeProcess.
	process isMeta ifTrue: [ ^ self trapMethodwith: arg1 with: arg2 with: arg3 ].
	deactivator := #slowdeactivator.
	result := self trapMethodwith: arg1 with: arg2 with: arg3.
	complete := true.
	^ result
]

{ #category : 'as yet unclassified' }
OTMethodProxyPassThrough class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 [
	"The unwind handler should be the first temp.
	The complete flag should be the second temp."

	<trap>
	<debuggerCompleteToSender>
	<primitive: 198>
	| deactivator complete result process |
	ENABLED ifFalse: [
			^ self
				  trapMethodwith: arg1
				  with: arg2
				  with: arg3
				  with: arg4 ].
	process := Processor activeProcess.
	process isMeta ifTrue: [
			^ self
				  trapMethodwith: arg1
				  with: arg2
				  with: arg3
				  with: arg4 ].
	deactivator := #slowdeactivator.
	result := self
		          trapMethodwith: arg1
		          with: arg2
		          with: arg3
		          with: arg4.
	complete := true.
	^ result
]

{ #category : 'as yet unclassified' }
OTMethodProxyPassThrough class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 with: arg5 [
	"The unwind handler should be the first temp.
	The complete flag should be the second temp."

	<trap>
	<debuggerCompleteToSender>
	<primitive: 198>
	| deactivator complete result process |
	ENABLED ifFalse: [
			^ self
				  trapMethodwith: arg1
				  with: arg2
				  with: arg3
				  with: arg4
				  with: arg5 ].
	process := Processor activeProcess.
	process isMeta ifTrue: [
			^ self
				  trapMethodwith: arg1
				  with: arg2
				  with: arg3
				  with: arg4
				  with: arg5 ].
	deactivator := #slowdeactivator.
	result := self
		          trapMethodwith: arg1
		          with: arg2
		          with: arg3
		          with: arg4
		          with: arg5.
	complete := true.
	^ result
]

{ #category : 'as yet unclassified' }
OTMethodProxyPassThrough class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 [
	"The unwind handler should be the first temp.
	The complete flag should be the second temp."

	<trap>
	<debuggerCompleteToSender>
	<primitive: 198>
	| deactivator complete result process |
	ENABLED ifFalse: [
			^ self
				  trapMethodwith: arg1
				  with: arg2
				  with: arg3
				  with: arg4
				  with: arg5
				  with: arg6 ].
	process := Processor activeProcess.
	process isMeta ifTrue: [
			^ self
				  trapMethodwith: arg1
				  with: arg2
				  with: arg3
				  with: arg4
				  with: arg5
				  with: arg6 ].
	deactivator := #slowdeactivator.
	result := self
		          trapMethodwith: arg1
		          with: arg2
		          with: arg3
		          with: arg4
		          with: arg5
		          with: arg6.
	complete := true.
	^ result
]

{ #category : 'as yet unclassified' }
OTMethodProxyPassThrough class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 with: arg7 [
	"The unwind handler should be the first temp.
	The complete flag should be the second temp."

	<trap>
	<debuggerCompleteToSender>
	<primitive: 198>
	| deactivator complete result process |
	ENABLED ifFalse: [
			^ self
				  trapMethodwith: arg1
				  with: arg2
				  with: arg3
				  with: arg4
				  with: arg5
				  with: arg6
				  with: arg7 ].
	process := Processor activeProcess.
	process isMeta ifTrue: [
			^ self
				  trapMethodwith: arg1
				  with: arg2
				  with: arg3
				  with: arg4
				  with: arg5
				  with: arg6
				  with: arg7 ].
	deactivator := #slowdeactivator.
	result := self
		          trapMethodwith: arg1
		          with: arg2
		          with: arg3
		          with: arg4
		          with: arg5
		          with: arg6
		          with: arg7.
	complete := true.
	^ result
]

{ #category : 'as yet unclassified' }
OTMethodProxyPassThrough class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 with: arg7 with: arg8 [
	"The unwind handler should be the first temp.
	The complete flag should be the second temp."

	<trap>
	<debuggerCompleteToSender>
	<primitive: 198>
	| deactivator complete result process |
	ENABLED ifFalse: [
			^ self
				  trapMethodwith: arg1
				  with: arg2
				  with: arg3
				  with: arg4
				  with: arg5
				  with: arg6
				  with: arg7
				  with: arg8 ].
	process := Processor activeProcess.
	process isMeta ifTrue: [
			^ self
				  trapMethodwith: arg1
				  with: arg2
				  with: arg3
				  with: arg4
				  with: arg5
				  with: arg6
				  with: arg7
				  with: arg8 ].
	deactivator := #slowdeactivator.
	result := self
		          trapMethodwith: arg1
		          with: arg2
		          with: arg3
		          with: arg4
		          with: arg5
		          with: arg6
		          with: arg7
		          with: arg8.
	complete := true.
	^ result
]

{ #category : 'as yet unclassified' }
OTMethodProxyPassThrough class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 with: arg7 with: arg8 with: arg9 [
	"The unwind handler should be the first temp.
	The complete flag should be the second temp."

	<trap>
	<debuggerCompleteToSender>
	<primitive: 198>
	| deactivator complete result process |
	ENABLED ifFalse: [
			^ self
				  trapMethodwith: arg1
				  with: arg2
				  with: arg3
				  with: arg4
				  with: arg5
				  with: arg6
				  with: arg7
				  with: arg8
				  with: arg9 ].
	process := Processor activeProcess.
	process isMeta ifTrue: [
			^ self
				  trapMethodwith: arg1
				  with: arg2
				  with: arg3
				  with: arg4
				  with: arg5
				  with: arg6
				  with: arg7
				  with: arg8
				  with: arg9 ].
	deactivator := #slowdeactivator.
	result := self
		          trapMethodwith: arg1
		          with: arg2
		          with: arg3
		          with: arg4
		          with: arg5
		          with: arg6
		          with: arg7
		          with: arg8
		          with: arg9.
	complete := true.
	^ result
]

{ #category : 'as yet unclassified' }
OTMethodProxyPassThrough class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 with: arg7 with: arg8 with: arg9 with: arg10 [
	"The unwind handler should be the first temp.
	The complete flag should be the second temp."

	<trap>
	<debuggerCompleteToSender>
	<primitive: 198>
	| deactivator complete result process |
	ENABLED ifFalse: [
			^ self
				  trapMethodwith: arg1
				  with: arg2
				  with: arg3
				  with: arg4
				  with: arg5
				  with: arg6
				  with: arg7
				  with: arg8
				  with: arg9
				  with: arg10 ].
	process := Processor activeProcess.
	process isMeta ifTrue: [
			^ self
				  trapMethodwith: arg1
				  with: arg2
				  with: arg3
				  with: arg4
				  with: arg5
				  with: arg6
				  with: arg7
				  with: arg8
				  with: arg9
				  with: arg10 ].
	deactivator := #slowdeactivator.
	result := self
		          trapMethodwith: arg1
		          with: arg2
		          with: arg3
		          with: arg4
		          with: arg5
		          with: arg6
		          with: arg7
		          with: arg8
		          with: arg9
		          with: arg10.
	complete := true.
	^ result
]

{ #category : 'as yet unclassified' }
OTMethodProxyPassThrough class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 with: arg7 with: arg8 with: arg9 with: arg10 with: arg11 [
	"The unwind handler should be the first temp.
	The complete flag should be the second temp."

	<trap>
	<debuggerCompleteToSender>
	<primitive: 198>
	| deactivator complete result process |
	ENABLED ifFalse: [
			^ self
				  trapMethodwith: arg1
				  with: arg2
				  with: arg3
				  with: arg4
				  with: arg5
				  with: arg6
				  with: arg7
				  with: arg8
				  with: arg9
				  with: arg10
				  with: arg11 ].
	process := Processor activeProcess.
	process isMeta ifTrue: [
			^ self
				  trapMethodwith: arg1
				  with: arg2
				  with: arg3
				  with: arg4
				  with: arg5
				  with: arg6
				  with: arg7
				  with: arg8
				  with: arg9
				  with: arg10
				  with: arg11 ].
	deactivator := #slowdeactivator.
	result := self
		          trapMethodwith: arg1
		          with: arg2
		          with: arg3
		          with: arg4
		          with: arg5
		          with: arg6
		          with: arg7
		          with: arg8
		          with: arg9
		          with: arg10
		          with: arg11.
	complete := true.
	^ result
]

{ #category : 'as yet unclassified' }
OTMethodProxyPassThrough class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 with: arg7 with: arg8 with: arg9 with: arg10 with: arg11 with: arg12 [
	"The unwind handler should be the first temp.
	The complete flag should be the second temp."

	<trap>
	<debuggerCompleteToSender>
	<primitive: 198>
	| deactivator complete result process |
	ENABLED ifFalse: [
			^ self
				  trapMethodwith: arg1
				  with: arg2
				  with: arg3
				  with: arg4
				  with: arg5
				  with: arg6
				  with: arg7
				  with: arg8
				  with: arg9
				  with: arg10
				  with: arg11
				  with: arg12 ].
	process := Processor activeProcess.
	process isMeta ifTrue: [
			^ self
				  trapMethodwith: arg1
				  with: arg2
				  with: arg3
				  with: arg4
				  with: arg5
				  with: arg6
				  with: arg7
				  with: arg8
				  with: arg9
				  with: arg10
				  with: arg11
				  with: arg12 ].
	deactivator := #slowdeactivator.
	result := self
		          trapMethodwith: arg1
		          with: arg2
		          with: arg3
		          with: arg4
		          with: arg5
		          with: arg6
		          with: arg7
		          with: arg8
		          with: arg9
		          with: arg10
		          with: arg11
		          with: arg12.
	complete := true.
	^ result
]

{ #category : 'as yet unclassified' }
OTMethodProxyPassThrough class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 with: arg7 with: arg8 with: arg9 with: arg10 with: arg11 with: arg12 with: arg13 [
	"The unwind handler should be the first temp.
	The complete flag should be the second temp."

	<trap>
	<debuggerCompleteToSender>
	<primitive: 198>
	| deactivator complete result process |
	ENABLED ifFalse: [
			^ self
				  trapMethodwith: arg1
				  with: arg2
				  with: arg3
				  with: arg4
				  with: arg5
				  with: arg6
				  with: arg7
				  with: arg8
				  with: arg9
				  with: arg10
				  with: arg11
				  with: arg12
				  with: arg13 ].
	process := Processor activeProcess.
	process isMeta ifTrue: [
			^ self
				  trapMethodwith: arg1
				  with: arg2
				  with: arg3
				  with: arg4
				  with: arg5
				  with: arg6
				  with: arg7
				  with: arg8
				  with: arg9
				  with: arg10
				  with: arg11
				  with: arg12
				  with: arg13 ].
	deactivator := #slowdeactivator.
	result := self
		          trapMethodwith: arg1
		          with: arg2
		          with: arg3
		          with: arg4
		          with: arg5
		          with: arg6
		          with: arg7
		          with: arg8
		          with: arg9
		          with: arg10
		          with: arg11
		          with: arg12
		          with: arg13.
	complete := true.
	^ result
]

{ #category : 'as yet unclassified' }
OTMethodProxyPassThrough class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 with: arg7 with: arg8 with: arg9 with: arg10 with: arg11 with: arg12 with: arg13 with: arg14 [
	"The unwind handler should be the first temp.
	The complete flag should be the second temp."

	<trap>
	<debuggerCompleteToSender>
	<primitive: 198>
	| deactivator complete result process |
	ENABLED ifFalse: [
			^ self
				  trapMethodwith: arg1
				  with: arg2
				  with: arg3
				  with: arg4
				  with: arg5
				  with: arg6
				  with: arg7
				  with: arg8
				  with: arg9
				  with: arg10
				  with: arg11
				  with: arg12
				  with: arg13
				  with: arg14 ].
	process := Processor activeProcess.
	process isMeta ifTrue: [
			^ self
				  trapMethodwith: arg1
				  with: arg2
				  with: arg3
				  with: arg4
				  with: arg5
				  with: arg6
				  with: arg7
				  with: arg8
				  with: arg9
				  with: arg10
				  with: arg11
				  with: arg12
				  with: arg13
				  with: arg14 ].
	deactivator := #slowdeactivator.
	result := self
		          trapMethodwith: arg1
		          with: arg2
		          with: arg3
		          with: arg4
		          with: arg5
		          with: arg6
		          with: arg7
		          with: arg8
		          with: arg9
		          with: arg10
		          with: arg11
		          with: arg12
		          with: arg13
		          with: arg14.
	complete := true.
	^ result
]

{ #category : 'as yet unclassified' }
OTMethodProxyPassThrough class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 with: arg7 with: arg8 with: arg9 with: arg10 with: arg11 with: arg12 with: arg13 with: arg14 with: arg15 [
	"The unwind handler should be the first temp.
	The complete flag should be the second temp."

	<trap>
	<debuggerCompleteToSender>
	<primitive: 198>
	| deactivator complete result process |
	ENABLED ifFalse: [
			^ self
				  trapMethodwith: arg1
				  with: arg2
				  with: arg3
				  with: arg4
				  with: arg5
				  with: arg6
				  with: arg7
				  with: arg8
				  with: arg9
				  with: arg10
				  with: arg11
				  with: arg12
				  with: arg13
				  with: arg14
				  with: arg15 ].
	process := Processor activeProcess.
	process isMeta ifTrue: [
			^ self
				  trapMethodwith: arg1
				  with: arg2
				  with: arg3
				  with: arg4
				  with: arg5
				  with: arg6
				  with: arg7
				  with: arg8
				  with: arg9
				  with: arg10
				  with: arg11
				  with: arg12
				  with: arg13
				  with: arg14
				  with: arg15 ].
	deactivator := #slowdeactivator.
	result := self
		          trapMethodwith: arg1
		          with: arg2
		          with: arg3
		          with: arg4
		          with: arg5
		          with: arg6
		          with: arg7
		          with: arg8
		          with: arg9
		          with: arg10
		          with: arg11
		          with: arg12
		          with: arg13
		          with: arg14
		          with: arg15.
	complete := true.
	^ result
]

{ #category : 'installation' }
OTMethodProxyPassThrough >> install [

	| slowdeactivator newTrap index trapSelector |
	self disableInstrumentation.

	thisProcess runInMetaLevel: [
			(proxifiedMethod hasPragmaNamed: #noInstrumentation) ifTrue: [ ^ MpCannotInstall signalWith: self ].

			slowdeactivator := OTMethodProxyPassThroughDeactivator withHandler: handler.

			newTrap := self prototypeTrapMethod copy.
			trapSelector := newTrap selector.
			newTrap selector: proxifiedMethod selector.
			newTrap methodClass: proxifiedMethod methodClass.

			hiddenSelector := MpHiddenSelector new
				                  proxifiedSelector: proxifiedMethod selector;
				                  yourself.

			index := newTrap literals indexOf: trapSelector.
			newTrap literalAt: index put: hiddenSelector.

			index := newTrap literals indexOf: #slowdeactivator.
			newTrap literalAt: index put: slowdeactivator.

			wrappedMethod := proxifiedMethod methodClass methodDict at: proxifiedMethod selector.

			proxifiedMethod methodClass methodDict at: hiddenSelector put: proxifiedMethod.
			proxifiedMethod methodClass methodDict at: proxifiedMethod selector put: newTrap.

			trapMethod := newTrap ]
]

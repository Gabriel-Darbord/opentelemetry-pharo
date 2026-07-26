"
I am the specialized MethodProxy trap used when an instrumentation only needs an after hook.

I execute the original method first, then run the handler on normal completion while preserving MethodProxy unwind behavior.
"
Class {
	#name : 'OTMethodProxyAfter',
	#superclass : 'MpMethodProxy',
	#category : 'OpenTelemetry-Instrumentation-MethodProxy',
	#package : 'OpenTelemetry-Instrumentation-MethodProxy'
}

{ #category : 'class initialization' }
OTMethodProxyAfter class >> initialize [

	self buildPrototypesUpToArguments: 15
]

{ #category : 'evaluating' }
OTMethodProxyAfter class >> prototypeTrap [
	"The unwind handler should be the first temp.
	The complete flag should be the second temp.
	The last temp variable should be the wasMeta flag."

	<trap>
	<debuggerCompleteToSender>
	<primitive: 198>
	| deactivator complete result process wasMeta |
	ENABLED ifFalse: [ ^ self originalMessage ].
	process := Processor activeProcess.
	process isMeta ifTrue: [ ^ self originalMessage ].
	deactivator := #slowdeactivator.
	result := self originalMessage.
	process shiftLevelUp.
	wasMeta := true.
	result := #handler afterExecutionWithReceiver: self arguments: #argumentList returnValue: result.
	process shiftLevelDown.
	wasMeta := false.
	complete := true.
	^ result
]

{ #category : 'generated traps' }
OTMethodProxyAfter class >> trapMethod [
	"The unwind handler should be the first temp.
	The complete flag should be the second temp.
	The last temp variable should be the wasMeta flag."

	<trap>
	<debuggerCompleteToSender>
	<primitive: 198>
	| deactivator complete result process wasMeta |
	ENABLED ifFalse: [ ^ self trapMethod ].
	process := Processor activeProcess.
	process isMeta ifTrue: [ ^ self trapMethod ].
	deactivator := #slowdeactivator.
	result := self trapMethod.
	process shiftLevelUp.
	wasMeta := true.
	result := #handler afterExecutionWithReceiver: self arguments: {  } returnValue: result.
	process shiftLevelDown.
	wasMeta := false.
	complete := true.
	^ result
]

{ #category : 'generated traps' }
OTMethodProxyAfter class >> trapMethodwith: arg1 [
	"The unwind handler should be the first temp.
	The complete flag should be the second temp.
	The last temp variable should be the wasMeta flag."

	<trap>
	<debuggerCompleteToSender>
	<primitive: 198>
	| deactivator complete result process wasMeta |
	ENABLED ifFalse: [ ^ self trapMethodwith: arg1 ].
	process := Processor activeProcess.
	process isMeta ifTrue: [ ^ self trapMethodwith: arg1 ].
	deactivator := #slowdeactivator.
	result := self trapMethodwith: arg1.
	process shiftLevelUp.
	wasMeta := true.
	result := #handler afterExecutionWithReceiver: self arguments: { arg1 } returnValue: result.
	process shiftLevelDown.
	wasMeta := false.
	complete := true.
	^ result
]

{ #category : 'generated traps' }
OTMethodProxyAfter class >> trapMethodwith: arg1 with: arg2 [
	"The unwind handler should be the first temp.
	The complete flag should be the second temp.
	The last temp variable should be the wasMeta flag."

	<trap>
	<debuggerCompleteToSender>
	<primitive: 198>
	| deactivator complete result process wasMeta |
	ENABLED ifFalse: [ ^ self trapMethodwith: arg1 with: arg2 ].
	process := Processor activeProcess.
	process isMeta ifTrue: [ ^ self trapMethodwith: arg1 with: arg2 ].
	deactivator := #slowdeactivator.
	result := self trapMethodwith: arg1 with: arg2.
	process shiftLevelUp.
	wasMeta := true.
	result := #handler
		          afterExecutionWithReceiver: self
		          arguments: {
				          arg1.
				          arg2 }
		          returnValue: result.
	process shiftLevelDown.
	wasMeta := false.
	complete := true.
	^ result
]

{ #category : 'generated traps' }
OTMethodProxyAfter class >> trapMethodwith: arg1 with: arg2 with: arg3 [
	"The unwind handler should be the first temp.
	The complete flag should be the second temp.
	The last temp variable should be the wasMeta flag."

	<trap>
	<debuggerCompleteToSender>
	<primitive: 198>
	| deactivator complete result process wasMeta |
	ENABLED ifFalse: [ ^ self trapMethodwith: arg1 with: arg2 with: arg3 ].
	process := Processor activeProcess.
	process isMeta ifTrue: [ ^ self trapMethodwith: arg1 with: arg2 with: arg3 ].
	deactivator := #slowdeactivator.
	result := self trapMethodwith: arg1 with: arg2 with: arg3.
	process shiftLevelUp.
	wasMeta := true.
	result := #handler
		          afterExecutionWithReceiver: self
		          arguments: {
				          arg1.
				          arg2.
				          arg3 }
		          returnValue: result.
	process shiftLevelDown.
	wasMeta := false.
	complete := true.
	^ result
]

{ #category : 'generated traps' }
OTMethodProxyAfter class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 [
	"The unwind handler should be the first temp.
	The complete flag should be the second temp.
	The last temp variable should be the wasMeta flag."

	<trap>
	<debuggerCompleteToSender>
	<primitive: 198>
	| deactivator complete result process wasMeta |
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
	process shiftLevelUp.
	wasMeta := true.
	result := #handler
		          afterExecutionWithReceiver: self
		          arguments: {
				          arg1.
				          arg2.
				          arg3.
				          arg4 }
		          returnValue: result.
	process shiftLevelDown.
	wasMeta := false.
	complete := true.
	^ result
]

{ #category : 'generated traps' }
OTMethodProxyAfter class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 with: arg5 [
	"The unwind handler should be the first temp.
	The complete flag should be the second temp.
	The last temp variable should be the wasMeta flag."

	<trap>
	<debuggerCompleteToSender>
	<primitive: 198>
	| deactivator complete result process wasMeta |
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
	process shiftLevelUp.
	wasMeta := true.
	result := #handler
		          afterExecutionWithReceiver: self
		          arguments: {
				          arg1.
				          arg2.
				          arg3.
				          arg4.
				          arg5 }
		          returnValue: result.
	process shiftLevelDown.
	wasMeta := false.
	complete := true.
	^ result
]

{ #category : 'generated traps' }
OTMethodProxyAfter class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 [
	"The unwind handler should be the first temp.
	The complete flag should be the second temp.
	The last temp variable should be the wasMeta flag."

	<trap>
	<debuggerCompleteToSender>
	<primitive: 198>
	| deactivator complete result process wasMeta |
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
	process shiftLevelUp.
	wasMeta := true.
	result := #handler
		          afterExecutionWithReceiver: self
		          arguments: {
				          arg1.
				          arg2.
				          arg3.
				          arg4.
				          arg5.
				          arg6 }
		          returnValue: result.
	process shiftLevelDown.
	wasMeta := false.
	complete := true.
	^ result
]

{ #category : 'generated traps' }
OTMethodProxyAfter class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 with: arg7 [
	"The unwind handler should be the first temp.
	The complete flag should be the second temp.
	The last temp variable should be the wasMeta flag."

	<trap>
	<debuggerCompleteToSender>
	<primitive: 198>
	| deactivator complete result process wasMeta |
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
	process shiftLevelUp.
	wasMeta := true.
	result := #handler
		          afterExecutionWithReceiver: self
		          arguments: {
				          arg1.
				          arg2.
				          arg3.
				          arg4.
				          arg5.
				          arg6.
				          arg7 }
		          returnValue: result.
	process shiftLevelDown.
	wasMeta := false.
	complete := true.
	^ result
]

{ #category : 'generated traps' }
OTMethodProxyAfter class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 with: arg7 with: arg8 [
	"The unwind handler should be the first temp.
	The complete flag should be the second temp.
	The last temp variable should be the wasMeta flag."

	<trap>
	<debuggerCompleteToSender>
	<primitive: 198>
	| deactivator complete result process wasMeta |
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
	process shiftLevelUp.
	wasMeta := true.
	result := #handler
		          afterExecutionWithReceiver: self
		          arguments: {
				          arg1.
				          arg2.
				          arg3.
				          arg4.
				          arg5.
				          arg6.
				          arg7.
				          arg8 }
		          returnValue: result.
	process shiftLevelDown.
	wasMeta := false.
	complete := true.
	^ result
]

{ #category : 'generated traps' }
OTMethodProxyAfter class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 with: arg7 with: arg8 with: arg9 [
	"The unwind handler should be the first temp.
	The complete flag should be the second temp.
	The last temp variable should be the wasMeta flag."

	<trap>
	<debuggerCompleteToSender>
	<primitive: 198>
	| deactivator complete result process wasMeta |
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
	process shiftLevelUp.
	wasMeta := true.
	result := #handler
		          afterExecutionWithReceiver: self
		          arguments: {
				          arg1.
				          arg2.
				          arg3.
				          arg4.
				          arg5.
				          arg6.
				          arg7.
				          arg8.
				          arg9 }
		          returnValue: result.
	process shiftLevelDown.
	wasMeta := false.
	complete := true.
	^ result
]

{ #category : 'generated traps' }
OTMethodProxyAfter class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 with: arg7 with: arg8 with: arg9 with: arg10 [
	"The unwind handler should be the first temp.
	The complete flag should be the second temp.
	The last temp variable should be the wasMeta flag."

	<trap>
	<debuggerCompleteToSender>
	<primitive: 198>
	| deactivator complete result process wasMeta |
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
	process shiftLevelUp.
	wasMeta := true.
	result := #handler
		          afterExecutionWithReceiver: self
		          arguments: {
				          arg1.
				          arg2.
				          arg3.
				          arg4.
				          arg5.
				          arg6.
				          arg7.
				          arg8.
				          arg9.
				          arg10 }
		          returnValue: result.
	process shiftLevelDown.
	wasMeta := false.
	complete := true.
	^ result
]

{ #category : 'generated traps' }
OTMethodProxyAfter class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 with: arg7 with: arg8 with: arg9 with: arg10 with: arg11 [
	"The unwind handler should be the first temp.
	The complete flag should be the second temp.
	The last temp variable should be the wasMeta flag."

	<trap>
	<debuggerCompleteToSender>
	<primitive: 198>
	| deactivator complete result process wasMeta |
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
	process shiftLevelUp.
	wasMeta := true.
	result := #handler
		          afterExecutionWithReceiver: self
		          arguments: {
				          arg1.
				          arg2.
				          arg3.
				          arg4.
				          arg5.
				          arg6.
				          arg7.
				          arg8.
				          arg9.
				          arg10.
				          arg11 }
		          returnValue: result.
	process shiftLevelDown.
	wasMeta := false.
	complete := true.
	^ result
]

{ #category : 'generated traps' }
OTMethodProxyAfter class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 with: arg7 with: arg8 with: arg9 with: arg10 with: arg11 with: arg12 [
	"The unwind handler should be the first temp.
	The complete flag should be the second temp.
	The last temp variable should be the wasMeta flag."

	<trap>
	<debuggerCompleteToSender>
	<primitive: 198>
	| deactivator complete result process wasMeta |
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
	process shiftLevelUp.
	wasMeta := true.
	result := #handler
		          afterExecutionWithReceiver: self
		          arguments: {
				          arg1.
				          arg2.
				          arg3.
				          arg4.
				          arg5.
				          arg6.
				          arg7.
				          arg8.
				          arg9.
				          arg10.
				          arg11.
				          arg12 }
		          returnValue: result.
	process shiftLevelDown.
	wasMeta := false.
	complete := true.
	^ result
]

{ #category : 'generated traps' }
OTMethodProxyAfter class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 with: arg7 with: arg8 with: arg9 with: arg10 with: arg11 with: arg12 with: arg13 [
	"The unwind handler should be the first temp.
	The complete flag should be the second temp.
	The last temp variable should be the wasMeta flag."

	<trap>
	<debuggerCompleteToSender>
	<primitive: 198>
	| deactivator complete result process wasMeta |
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
	process shiftLevelUp.
	wasMeta := true.
	result := #handler
		          afterExecutionWithReceiver: self
		          arguments: {
				          arg1.
				          arg2.
				          arg3.
				          arg4.
				          arg5.
				          arg6.
				          arg7.
				          arg8.
				          arg9.
				          arg10.
				          arg11.
				          arg12.
				          arg13 }
		          returnValue: result.
	process shiftLevelDown.
	wasMeta := false.
	complete := true.
	^ result
]

{ #category : 'generated traps' }
OTMethodProxyAfter class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 with: arg7 with: arg8 with: arg9 with: arg10 with: arg11 with: arg12 with: arg13 with: arg14 [
	"The unwind handler should be the first temp.
	The complete flag should be the second temp.
	The last temp variable should be the wasMeta flag."

	<trap>
	<debuggerCompleteToSender>
	<primitive: 198>
	| deactivator complete result process wasMeta |
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
	process shiftLevelUp.
	wasMeta := true.
	result := #handler
		          afterExecutionWithReceiver: self
		          arguments: {
				          arg1.
				          arg2.
				          arg3.
				          arg4.
				          arg5.
				          arg6.
				          arg7.
				          arg8.
				          arg9.
				          arg10.
				          arg11.
				          arg12.
				          arg13.
				          arg14 }
		          returnValue: result.
	process shiftLevelDown.
	wasMeta := false.
	complete := true.
	^ result
]

{ #category : 'generated traps' }
OTMethodProxyAfter class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 with: arg7 with: arg8 with: arg9 with: arg10 with: arg11 with: arg12 with: arg13 with: arg14 with: arg15 [
	"The unwind handler should be the first temp.
	The complete flag should be the second temp.
	The last temp variable should be the wasMeta flag."

	<trap>
	<debuggerCompleteToSender>
	<primitive: 198>
	| deactivator complete result process wasMeta |
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
	process shiftLevelUp.
	wasMeta := true.
	result := #handler
		          afterExecutionWithReceiver: self
		          arguments: {
				          arg1.
				          arg2.
				          arg3.
				          arg4.
				          arg5.
				          arg6.
				          arg7.
				          arg8.
				          arg9.
				          arg10.
				          arg11.
				          arg12.
				          arg13.
				          arg14.
				          arg15 }
		          returnValue: result.
	process shiftLevelDown.
	wasMeta := false.
	complete := true.
	^ result
]

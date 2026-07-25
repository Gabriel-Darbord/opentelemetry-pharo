Class {
	#name : 'OTMethodProxyPassThroughProxy',
	#superclass : 'MpMethodProxy',
	#category : 'OpenTelemetry-Instrumentation-MethodProxy',
	#package : 'OpenTelemetry-Instrumentation-MethodProxy'
}

{ #category : 'class initialization' }
OTMethodProxyPassThroughProxy class >> initialize [

	self buildPrototypesUpToArguments: 15
]

{ #category : 'evaluating' }
OTMethodProxyPassThroughProxy class >> prototypeTrap [
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
	#handler.
	result := self originalMessage.
	complete := true.
	^ result
]

{ #category : 'as yet unclassified' }
OTMethodProxyPassThroughProxy class >> trapMethod [
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
	#handler.
	result := self trapMethod.
	complete := true.
	^ result
]

{ #category : 'as yet unclassified' }
OTMethodProxyPassThroughProxy class >> trapMethodwith: arg1 [
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
	#handler.
	result := self trapMethodwith: arg1.
	complete := true.
	^ result
]

{ #category : 'as yet unclassified' }
OTMethodProxyPassThroughProxy class >> trapMethodwith: arg1 with: arg2 [
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
	#handler.
	result := self trapMethodwith: arg1 with: arg2.
	complete := true.
	^ result
]

{ #category : 'as yet unclassified' }
OTMethodProxyPassThroughProxy class >> trapMethodwith: arg1 with: arg2 with: arg3 [
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
	#handler.
	result := self trapMethodwith: arg1 with: arg2 with: arg3.
	complete := true.
	^ result
]

{ #category : 'as yet unclassified' }
OTMethodProxyPassThroughProxy class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 [
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
	#handler.
	result := self
		          trapMethodwith: arg1
		          with: arg2
		          with: arg3
		          with: arg4.
	complete := true.
	^ result
]

{ #category : 'as yet unclassified' }
OTMethodProxyPassThroughProxy class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 with: arg5 [
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
	#handler.
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
OTMethodProxyPassThroughProxy class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 [
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
	#handler.
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
OTMethodProxyPassThroughProxy class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 with: arg7 [
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
	#handler.
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
OTMethodProxyPassThroughProxy class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 with: arg7 with: arg8 [
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
	#handler.
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
OTMethodProxyPassThroughProxy class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 with: arg7 with: arg8 with: arg9 [
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
	#handler.
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
OTMethodProxyPassThroughProxy class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 with: arg7 with: arg8 with: arg9 with: arg10 [
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
	#handler.
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
OTMethodProxyPassThroughProxy class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 with: arg7 with: arg8 with: arg9 with: arg10 with: arg11 [
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
	#handler.
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
OTMethodProxyPassThroughProxy class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 with: arg7 with: arg8 with: arg9 with: arg10 with: arg11 with: arg12 [
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
	#handler.
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
OTMethodProxyPassThroughProxy class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 with: arg7 with: arg8 with: arg9 with: arg10 with: arg11 with: arg12 with: arg13 [
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
	#handler.
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
OTMethodProxyPassThroughProxy class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 with: arg7 with: arg8 with: arg9 with: arg10 with: arg11 with: arg12 with: arg13 with: arg14 [
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
	#handler.
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
OTMethodProxyPassThroughProxy class >> trapMethodwith: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 with: arg7 with: arg8 with: arg9 with: arg10 with: arg11 with: arg12 with: arg13 with: arg14 with: arg15 [
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
	#handler.
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

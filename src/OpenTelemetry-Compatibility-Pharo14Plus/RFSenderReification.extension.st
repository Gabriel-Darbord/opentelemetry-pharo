Extension { #name : 'RFSenderReification' }

{ #category : '*OpenTelemetry-Compatibility-Pharo14Plus' }
RFSenderReification >> genForASTMethodNode [
	"shortcut: carry the sender fix until supported images include Pharo #20118/#20119."

	^ OCMessageNode
		  receiver: (OCMessageNode receiver: OCVariableNode thisContextNode selector: (OCSelectorNode value: #sender))
		  selector: (OCSelectorNode value: #receiver)
]

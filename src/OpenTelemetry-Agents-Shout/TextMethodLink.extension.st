Extension { #name : 'TextMethodLink' }

{ #category : '*OpenTelemetry-Agents-Shout' }
TextMethodLink class >> sourceNodeCustomizer [

	<stonCustomizationFor: #sourceNode>
	^ STONCustomizer new writeBlock: [ :link | nil ]
]

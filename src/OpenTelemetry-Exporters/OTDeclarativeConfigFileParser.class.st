"
I parse the small YAML subset used by the OpenTelemetry migration config and
resolve scalar environment substitutions.
"
Class {
	#name : 'OTDeclarativeConfigFileParser',
	#superclass : 'Object',
	#instVars : [
		'lines',
		'position',
		'environmentLookupBlock'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'instance creation' }
OTDeclarativeConfigFileParser class >> parse: aString environmentLookup: aBlock [

	^ self new
		environmentLookupBlock: aBlock;
		lines: (self meaningfulLinesFrom: aString);
		parseDocument
]

{ #category : 'private' }
OTDeclarativeConfigFileParser class >> meaningfulLinesFrom: aString [

	^ Array streamContents: [ :stream |
		aString lines do: [ :each |
			| content indent trimmed |
			each ifEmpty: [  ] ifNotEmpty: [
				indent := 0.
				[ indent < each size and: [ (each at: indent + 1) = Character space ] ]
					whileTrue: [ indent := indent + 1 ].
				content := indent = each size
					ifTrue: [ '' ]
					ifFalse: [ each copyFrom: indent + 1 to: each size ].
				trimmed := content trimBoth.
				(trimmed isEmpty or: [ trimmed first = $# ]) ifFalse: [
					stream nextPut: { indent. content } ] ] ] ]
]

{ #category : 'private' }
OTDeclarativeConfigFileParser >> advance [

	position := position + 1
]

{ #category : 'private' }
OTDeclarativeConfigFileParser >> atEnd [

	^ position > lines size
]

{ #category : 'private' }
OTDeclarativeConfigFileParser >> currentContent [

	^ (lines at: position) second
]

{ #category : 'private' }
OTDeclarativeConfigFileParser >> currentIndent [

	^ (lines at: position) first
]

{ #category : 'private' }
OTDeclarativeConfigFileParser >> environmentLookupBlock: aBlock [

	environmentLookupBlock := aBlock
]

{ #category : 'private' }
OTDeclarativeConfigFileParser >> keyValuePartsFrom: aString [

	1 to: aString size do: [ :index |
		(aString at: index) = $: ifTrue: [
			(index = aString size or: [ (aString at: index + 1) = Character space ]) ifTrue: [
				| key value |
				key := (aString copyFrom: 1 to: index - 1) trimBoth.
				key isEmpty ifTrue: [
					Error signal: 'Declarative configuration keys must not be empty' ].
				value := index = aString size
					ifTrue: [ '' ]
					ifFalse: [ (aString copyFrom: index + 2 to: aString size) trimBoth ].
				^ { key. value } ] ] ].
	Error signal: 'Unsupported declarative configuration line: ', aString printString
]

{ #category : 'private' }
OTDeclarativeConfigFileParser >> lines: aCollection [

	lines := aCollection.
	position := 1
]

{ #category : 'private - parsing' }
OTDeclarativeConfigFileParser >> parseDocument [

	lines ifEmpty: [ ^ OrderedDictionary new ].
	^ self parseNodeAtIndent: lines first first
]

{ #category : 'private - parsing' }
OTDeclarativeConfigFileParser >> parseMappingAtIndent: anInteger [

	| mapping |
	mapping := OrderedDictionary new.
	[ self atEnd not
		and: [ self currentIndent = anInteger
		and: [ (self currentContent beginsWith: '- ') not ] ] ]
		whileTrue: [
			| pair value valueText |
			pair := self keyValuePartsFrom: self currentContent.
			self advance.
			valueText := pair second.
			value := valueText isEmpty
				ifTrue: [
					(self atEnd or: [ self currentIndent <= anInteger ])
						ifTrue: [ nil ]
						ifFalse: [ self parseNodeAtIndent: self currentIndent ] ]
				ifFalse: [ self scalarFrom: valueText ].
			(mapping includesKey: pair first) ifTrue: [
				Error signal: 'Duplicate declarative configuration key: ', pair first printString ].
			mapping at: pair first put: value ].
	^ mapping
]

{ #category : 'private - parsing' }
OTDeclarativeConfigFileParser >> parseNodeAtIndent: anInteger [

	self atEnd ifTrue: [ ^ nil ].
	self currentIndent < anInteger ifTrue: [ ^ nil ].
	(self currentContent beginsWith: '- ')
		ifTrue: [ ^ self parseSequenceAtIndent: anInteger ].
	^ self parseMappingAtIndent: anInteger
]

{ #category : 'private - parsing' }
OTDeclarativeConfigFileParser >> parseSequenceAtIndent: anInteger [

	| sequence |
	sequence := OrderedCollection new.
	[ self atEnd not
		and: [ self currentIndent = anInteger
		and: [ self currentContent beginsWith: '- ' ] ] ]
		whileTrue: [
			| content extraMapping item pair value valueText |
			content := (self currentContent allButFirst: 2) trimBoth.
			self advance.
			content isEmpty ifTrue: [
				sequence add: (self parseNodeAtIndent: anInteger + 2) ]
			ifFalse: [
				item := nil.
				(content includes: $:)
					ifTrue: [
						pair := self keyValuePartsFrom: content.
						item := OrderedDictionary new.
						valueText := pair second.
						value := valueText isEmpty
							ifTrue: [
								(self atEnd or: [ self currentIndent <= anInteger ])
									ifTrue: [ nil ]
									ifFalse: [ self parseNodeAtIndent: self currentIndent ] ]
							ifFalse: [ self scalarFrom: valueText ].
						item at: pair first put: value.
						(self atEnd not
							and: [ self currentIndent > anInteger
							and: [ (self currentContent beginsWith: '- ') not ] ]) ifTrue: [
							extraMapping := self parseMappingAtIndent: anInteger + 2.
							extraMapping associationsDo: [ :each |
								item at: each key put: each value ] ] ]
					ifFalse: [ item := self scalarFrom: content ].
				sequence add: item ] ].
	^ sequence asArray
]

{ #category : 'private - substitution' }
OTDeclarativeConfigFileParser >> replacementForSubstitutionContent: aString [

	| defaultIndex defaultValue envName prefix prefixIndex value variableContent |
	prefixIndex := aString indexOf: $: ifAbsent: [ 0 ].
	(prefixIndex > 0 and: [ prefixIndex < aString size and: [ (aString at: prefixIndex + 1) ~= $- ] ]) ifTrue: [
		prefix := aString copyFrom: 1 to: prefixIndex - 1.
		(self isValidSubstitutionPrefix: prefix) ifFalse: [
			Error signal: 'Unsupported substitution prefix: ', prefix printString ].
		prefix = 'env' ifFalse: [
			Error signal: 'Unsupported substitution prefix: ', prefix printString ].
		variableContent := aString copyFrom: prefixIndex + 1 to: aString size ]
	ifFalse: [ variableContent := aString ].
	defaultIndex := variableContent findString: ':-' startingAt: 1.
	defaultIndex = 0
		ifTrue: [
			envName := variableContent.
			defaultValue := nil ]
		ifFalse: [
			envName := variableContent copyFrom: 1 to: defaultIndex - 1.
			defaultValue := variableContent copyFrom: defaultIndex + 2 to: variableContent size ].
	(self isValidEnvironmentVariableName: envName) ifFalse: [
		Error signal: 'Invalid environment substitution reference: ', aString printString ].
	value := environmentLookupBlock value: envName.
	(value isNil or: [ value isEmpty ]) ifTrue: [ ^ defaultValue ifNil: [ '' ] ifNotNil: [ defaultValue ] ].
	^ value
]

{ #category : 'private - substitution' }
OTDeclarativeConfigFileParser >> resolveSubstitutionsIn: aString [

	| index stream |
	stream := String new writeStream.
	index := 1.
	[ index <= aString size ] whileTrue: [
		(index < aString size and: [ (aString at: index) = $$ and: [ (aString at: index + 1) = $$ ] ])
			ifTrue: [
				stream nextPut: $$.
				index := index + 2 ]
			ifFalse: [
				(index < aString size and: [ (aString at: index) = $$ and: [ (aString at: index + 1) = ${ ] ])
					ifTrue: [
						| closingIndex |
						closingIndex := aString indexOf: $} startingAt: index + 2 ifAbsent: [
							Error signal: 'Unterminated environment substitution reference' ].
						stream nextPutAll:
							(self replacementForSubstitutionContent:
								(aString copyFrom: index + 2 to: closingIndex - 1)).
						index := closingIndex + 1 ]
					ifFalse: [
						stream nextPut: (aString at: index).
						index := index + 1 ] ] ].
	^ stream contents
]

{ #category : 'private - parsing' }
OTDeclarativeConfigFileParser >> scalarFrom: aString [

	| quoted resolved trimmed |
	quoted := aString size >= 2
		and: [
			((aString first = $' and: [ aString last = $' ])
				or: [ aString first = $" and: [ aString last = $" ] ]) ].
	resolved := self resolveSubstitutionsIn: (quoted
		ifTrue: [ aString copyFrom: 2 to: aString size - 1 ]
		ifFalse: [ aString ]).
	quoted ifTrue: [ ^ resolved ].
	trimmed := resolved trimBoth.
	^ trimmed isEmpty ifTrue: [ nil ] ifFalse: [ trimmed ]
]

{ #category : 'private - substitution' }
OTDeclarativeConfigFileParser >> isValidEnvironmentVariableName: aString [

	aString ifEmpty: [ ^ false ].
	((aString first isLetter) or: [ aString first = $_ ]) ifFalse: [ ^ false ].
	^ aString allSatisfy: [ :each |
		each isLetter or: [ each isDigit or: [ each = $_ ] ] ]
]

{ #category : 'private - substitution' }
OTDeclarativeConfigFileParser >> isValidSubstitutionPrefix: aString [

	aString ifEmpty: [ ^ false ].
	aString first isLetter ifFalse: [ ^ false ].
	^ aString allSatisfy: [ :each |
		each isLetter or: [ each isDigit or: [ each = $_ ] ] ]
]

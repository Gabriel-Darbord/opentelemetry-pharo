"
Please describe the package using the class comment of the included manifest class. The manifest class also includes other additional metadata for the package. These meta data are used by other tools such as the SmalllintManifestChecker and the critics Browser
"
Class {
	#name : 'ManifestOpenTelemetryInstrumentationMetaLink',
	#superclass : 'PackageManifest',
	#category : 'OpenTelemetry-Instrumentation-MetaLink-Manifest',
	#package : 'OpenTelemetry-Instrumentation-MetaLink',
	#tag : 'Manifest'
}

{ #category : 'code-critics' }
ManifestOpenTelemetryInstrumentationMetaLink class >> ruleTempsReadBeforeWrittenRuleV1FalsePositive [

	<ignoreForCoverage>
	^ #(#(#(#RGMethodDefinition #(#'OTMetaLinkInstrumentation class' #run: #true)) #'2023-11-27T00:00:00.000000+01:00') )
]

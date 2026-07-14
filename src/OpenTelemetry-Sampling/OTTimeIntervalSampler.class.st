"
I enforce a minimum sampling interval using a very low-overhead time check.

This sampler is optimized for instrumentation hot paths. It uses a fast millisecond clock and keeps the decision logic intentionally simple to minimize runtime cost.

The design favors performance over strict synchronization guarantees. When the same sampler instance is shared concurrently, sampling remains best-effort: contention may allow more than one sample within an interval, and exact minimum-interval guarantees are not enforced across threads.

The clock can roll over, but *rarely*. Assuming 31 bits, a cycle lasts `((2 raisedTo: 31) - 1) milliSeconds days` = 24 days. The clock is also restarted along with the VM. For performance reasons, sampling is accepted in both scenarios, ignoring the interval.
"
Class {
	#name : 'OTTimeIntervalSampler',
	#superclass : 'OTSampler',
	#instVars : [
		'interval',
		'last'
	],
	#category : 'OpenTelemetry-Sampling',
	#package : 'OpenTelemetry-Sampling'
}

{{! -----------------------------------
	JSON partial template for RHC
	It is used to construct a partial JSON message at each sampling interval
	This partial JSON message will be added later to the master JSON message to be sent to server

	SYSTEM info

	xmo requests needed :
	- Device/DeviceInfo
	--------------------------------------- }}
{
	"eventTime" : {{timestamp.epoch}},
	"nodeIMEI" : "{{DeviceInfo.SerialNumber}}",
	"uptime" : {{DeviceInfo.UpTime}},
{{#DeviceInfo.ProcessStatus.LoadAverage}}
	"load1" : {{Load1}},
	"load5" : {{Load5}},
	"load15" : {{Load15}},
{{/DeviceInfo.ProcessStatus.LoadAverage}}
{{#DeviceInfo.MemoryStatus}}
	"memTotal" : {{Total|null}},
	"memFree" : {{Free|null}},
	"memCached" : {{Cached|null}},
	"memCommittedAs" : {{CommittedAs|null}}
{{/DeviceInfo.MemoryStatus}}
}
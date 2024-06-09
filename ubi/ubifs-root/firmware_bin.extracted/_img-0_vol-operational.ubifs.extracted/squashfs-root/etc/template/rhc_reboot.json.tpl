{{! -----------------------------------
	JSON partial template for RHC
	It is used to construct a partial JSON message at each sampling interval
	This partial JSON message will be added later to the master JSON message to be sent to server

	REBOOT info

	xmo requests needed :
	- Device/DeviceInfo
	- Device/WatchDog
	--------------------------------------- }}
{
	"eventTime" : {{timestamp.epoch}},
	"nodeIMEI" : "{{DeviceInfo.SerialNumber}}",
	"rebootCount" : {{DeviceInfo.RebootCount}},
	"lastRebootReason" : "{{WatchDog.LastReboot}}",
	"lastRebootSource" : null
}

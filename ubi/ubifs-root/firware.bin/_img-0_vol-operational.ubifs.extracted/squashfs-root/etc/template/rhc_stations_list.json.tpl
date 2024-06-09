{{! -----------------------------------
	JSON partial template for station message
	It is used to construct a partial JSON message at each sampling interval
	This partial JSON message will be added later to the master JSON message to be sent to server

	xmo requests needed :
	- Device/DeviceInfo
	- Device/Hosts/Hosts
	- Device/WiFi/AccessPoints/AccessPoint/AssociatedDevices/AssociatedDevice[@Active=CONNECTED]
	- Device/WiFi/SSIDs/SSID
	- Device/WiFi/Radios/Radio
	- Device/Ethernet/Interfaces/Interface
	--------------------------------------- }}
{{#Host}}
{{#Active=true}}
{
{{#InterfaceType=Ethernet}}
	"eventTime": {{timestamp.epoch}},
	"extenderIMEI": "{{DeviceInfo.SerialNumber}}",
	"hostname": {{#UserHostName=!}}"{{UserHostName}}",{{/UserHostName=!}}
				{{#UserHostName=}}
				{{#HostName=!}}"{{HostName}}",{{/HostName=!}}
				{{#HostName=}}null,{{/HostName=}}
				{{/UserHostName=}}
	"dType": {{#DetectedDeviceType=!}}
				{{#UserDeviceType=!MISCELLANEOUS}}"{{UserDeviceType}}",{{/UserDeviceType=!MISCELLANEOUS}}
				{{#UserDeviceType=MISCELLANEOUS}}"{{DetectedDeviceType}}",{{/UserDeviceType=MISCELLANEOUS}}
			 {{/DetectedDeviceType=!}}
			 {{#DetectedDeviceType=}}"{{UserDeviceType}}",{{/DetectedDeviceType=}}
	"ipv4": "{{IPAddress}}",
	"rssi": null,
	"stationMACAddr": "{{PhysAddress}}",
	"bssid": "((Interface.<<@Interface.*.Name={{&Layer1Interface}}@>>.MACAddress))",
	"lastDataDownlinkRate": null,
	"lastDataUplinkRate": 	null,
	"txMcastPkts":	((Interface.<<@Interface.*.Name={{&Layer1Interface}}@>>.Stats.MulticastPacketsSent | null)),
	"bytesSent":	((Interface.<<@Interface.*.Name={{&Layer1Interface}}@>>.Stats.BytesSent | null)),
	"txMcastBytes": null,
	"txUcastBytes": null,
	"rxUcastPkts":	((Interface.<<@Interface.*.Name={{&Layer1Interface}}@>>.Stats.UnicastPacketsReceived | null)),
	"rxUcastBytes": null,
	"rxMcastBytes": null,
	"rxPktsRetried":	null,
	"rxDecryptSucceeds":	null,
	"rxDecryptFailures":	null,
	"noise":	null,
	"channel":	null,
	"channelsInUse": null,
	"currentOperatingChannelBandwidth" : null,
	"maxBitRate":	((Interface.<<@Interface.*.Name={{&Layer1Interface}}@>>.CurrentBitRate | 0)),
	"band": "ETH",
	"ethernetPort":	((Interface.<<@Interface.*.Name={{&Layer1Interface}}@>>.PhyNum)),
	"rxMcastPkts": ((Interface.<<@Interface.*.Name={{&Layer1Interface}}@>>.Stats.MulticastPacketsReceived | null)),
	"bytesReceived":	((Interface.<<@Interface.*.Name={{&Layer1Interface}}@>>.Stats.BytesReceived | null)),
	"packetsReceived":	((Interface.<<@Interface.*.Name={{&Layer1Interface}}@>>.Stats.PacketsReceived | null)),
	"errorsSent":	((Interface.<<@Interface.*.Name={{&Layer1Interface}}@>>.Stats.ErrorsSent | null)),
	"txPkts":	null,
	"retryCount":	null,
	"packetsSent":	((Interface.<<@Interface.*.Name={{&Layer1Interface}}@>>.Stats.PacketsSent | null)),
	"uptime":	null,
	"retransCount": null,
	"failedRetransCount":	null,
	"staCapabilities": null,
	"operatingStandard": null,
	"bandSteeringDecisions2to5": null,
	"bandSteeringDecisions5to2": null,
	"bandSteeringCount2to5": null,
	"bandSteeringCount5to2": null,
	"airtimeUtilization":null,
	"airtimeTransmit":null,
	"airtimeReceiveSelf":null,
	"airtimeReceiveOther":null,
	"airtimeIdle":null,
	"airtimeInterference":null,
	"glitchCount":null
{{/InterfaceType=Ethernet}}
{{#InterfaceType=WiFi}}
((#AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>))
	"eventTime": {{timestamp.epoch}},
	"extenderIMEI": "{{DeviceInfo.SerialNumber}}",
	"hostname": {{#UserHostName=!}}"{{UserHostName}}",{{/UserHostName=!}}
				{{#UserHostName=}}
				{{#HostName=!}}"{{HostName}}",{{/HostName=!}}
				{{#HostName=}}null,{{/HostName=}}
				{{/UserHostName=}}
	"dType": {{#DetectedDeviceType=!}}
				{{#UserDeviceType=!MISCELLANEOUS}}"{{UserDeviceType}}",{{/UserDeviceType=!MISCELLANEOUS}}
				{{#UserDeviceType=MISCELLANEOUS}}"{{DetectedDeviceType}}",{{/UserDeviceType=MISCELLANEOUS}}
			 {{/DetectedDeviceType=!}}
			 {{#DetectedDeviceType=}}"{{UserDeviceType}}",{{/DetectedDeviceType=}}
	"ipv4": "{{IPAddress}}",
	"rssi": ((AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>.SignalStrength | null)),
	"stationMACAddr": "{{PhysAddress}}",
	"bssid": ((#SSID.<<@SSID.*.Alias=WL_PRIV@>>.LowerLayers={{&Layer1Interface}}))"((SSID.<<@SSID.*.Alias=WL_PRIV@>>.BSSID))",((/SSID.<<@SSID.*.Alias=WL_PRIV@>>.LowerLayers={{&Layer1Interface}}))
			 ((#SSID.<<@SSID.*.Alias=WL_VIDEO_5G@>>.LowerLayers={{&Layer1Interface}}))"((SSID.<<@SSID.*.Alias=WL_VIDEO_5G@>>.BSSID))",((/SSID.<<@SSID.*.Alias=WL_VIDEO_5G@>>.LowerLayers={{&Layer1Interface}}))
	"lastDataDownlinkRate": ((AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>.LastDataDownlinkRate | null)),
	"lastDataUplinkRate": 	((AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>.LastDataUplinkRate | null)),
	"txMcastPkts":	((AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>.Stats.TxMcastPkts | null)),
	"bytesSent":	((AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>.Stats.BytesSent | null)),
	"txMcastBytes": ((AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>.Stats.TxMcastBytes | null)),
	"txUcastBytes": ((AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>.Stats.TxUcastBytes | null)),
	"rxUcastPkts":	((AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>.Stats.RxUcastPkts | null)),
	"rxUcastBytes": ((AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>.Stats.RxUcastBytes | null)),
	"rxMcastBytes": ((AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>.Stats.RxMcastBytes | null)),
	"rxPktsRetried":	((AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>.Stats.RxPktsRetried | null)),
	"rxDecryptSucceeds":	((AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>.Stats.RxDecryptSucceeds | null)),
	"rxDecryptFailures":	((AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>.Stats.RxDecryptFailures | null)),
	"noise":	((Radio.<<@Radio.*.Name={{&Layer1Interface}}@>>.Stats.Noise  | -90)),
	"channel":	((Radio.<<@Radio.*.Name={{&Layer1Interface}}@>>.Channel | null)),
	"channelsInUse": "((Radio.<<@Radio.*.Name={{&Layer1Interface}}@>>.ChannelsInUse))",
	"currentOperatingChannelBandwidth" : "((Radio.<<@Radio.*.Name={{&Layer1Interface}}@>>.OperatingChannelBandwidth))",
	"maxBitRate":	((AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>.MaxBitRate | 0)),
	"band": "((Radio.<<@Radio.*.Name={{&Layer1Interface}}@>>.OperatingFrequencyBand))",
	"ethernetPort":	null,
	"rxMcastPkts": ((AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>.Stats.RxMcastPkts | null)),
	"bytesReceived":	((AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>.Stats.BytesReceived | null)),
	"packetsReceived":	((AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>.Stats.PacketsReceived | null)),
	"errorsSent":	((AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>.Stats.ErrorsSent | null)),
	"txPkts":	((AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>.Stats.TxUcastPkts | null)),
	"retryCount":	((AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>.Stats.RetryCount | null)),
	"packetsSent":	((AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>.Stats.PacketsSent | null)),
	"uptime":	((AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>.Stats.Uptime | null)),
	"retransCount": ((AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>.Stats.RetransCount | null)),
	"failedRetransCount":	((AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>.Stats.FailedRetransCount | null)),
	"staCapabilities": ((#AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>.SupportedStandards))
							"((AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>.SupportedStandards))",
						((/AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>.SupportedStandards))
						((^AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>.SupportedStandards))
							null,
						((/AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>.SupportedStandards))
	"operatingStandard": ((#AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>.OperatingStandard))
							"((AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>.OperatingStandard))",
						((/AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>.OperatingStandard))
						((^AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>.OperatingStandard))
							null,
						((/AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>.OperatingStandard))
	"bandSteeringDecisions2to5": null,
	"bandSteeringDecisions5to2": null,
	"bandSteeringCount2to5": null,
	"bandSteeringCount5to2": null,
	"airtimeUtilization": ((Radio.<<@Radio.*.Name={{&Layer1Interface}}@>>.Stats.Utilization | null)),
	"airtimeTransmit": ((Radio.<<@Radio.*.Name={{&Layer1Interface}}@>>.Stats.Transmit | null)),
	"airtimeReceiveSelf": ((Radio.<<@Radio.*.Name={{&Layer1Interface}}@>>.Stats.ReceiveSelf | null)),
	"airtimeReceiveOther": ((Radio.<<@Radio.*.Name={{&Layer1Interface}}@>>.Stats.ReceiveOther | null)),
	"airtimeIdle": ((Radio.<<@Radio.*.Name={{&Layer1Interface}}@>>.Stats.Idle | null)),
	"airtimeInterference": ((Radio.<<@Radio.*.Name={{&Layer1Interface}}@>>.Stats.Interfere | null)),
	"glitchCount":	((Radio.<<@Radio.*.Name={{&Layer1Interface}}@>>.Stats.Glitch | null))
((/AssociatedDevice.<<@AssociatedDevice.*.MACAddress={{PhysAddress}}@>>))
{{/InterfaceType=WiFi}}
}
{{/Active=true}}
{{/Host}}

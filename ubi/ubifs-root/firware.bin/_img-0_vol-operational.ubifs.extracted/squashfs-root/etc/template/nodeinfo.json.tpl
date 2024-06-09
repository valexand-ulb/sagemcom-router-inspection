{{! -----------------------------------
	JSON partial template for node_info object in wifi message
	It is used to construct a partial JSON message at boot time
	This partial JSON message will be added later to the master JSON message to be sent to server

	xmo requests needed :
	- Device/DeviceInfo
	- Device/Time
	- Device/DataCollector/Collections/Collection
	- Device/WiFi/SSIDs/SSID
	- Device/WiFi/Radios/Radio
	- Device/Ethernet/Interfaces/Interface
	- Device/Ethernet/Links/Link
	--------------------------------------- }}
{
	"IMEI": "{{DeviceInfo.SerialNumber}}",
	"manufacturerName": "{{DeviceInfo.Manufacturer}}",
	"modelName": "{{DeviceInfo.ModelNumber}}",
	"hardwareVersion": "{{DeviceInfo.HardwareVersion}}",
	"softwareVersion": "{{DeviceInfo.SoftwareVersion}}",
	"nCpuCores": 2,
	"nodeType": "GW",
	"timezone":"{{&Time.LocalTimeZone}}",
	"timezoneName":"{{&Time.LocalTimeZoneName}}",
	"samplingPeriod":((Collection.<<@Collection.*.Alias=rhc_master@>>.Interval | 0)),
	"sendingFrequency":((Collection.<<@Collection.*.Alias=rhc_master@>>.SendingFrequency | 0)),
	"interfaces": [
		{
			"band": "2_4GHZ",
			"nodeMACAddr": "((SSID.<<@SSID.*.Alias=WL_PRIV@>>.MACAddress))",
			"ssid": "((SSID.<<@SSID.*.Alias=WL_PRIV@>>.SSID))",
			"status": "((SSID.<<@SSID.*.Alias=WL_PRIV@>>.Status | NOTPRESENT))",
			"operatingStandard": "((Radio.<<@Radio.*.Alias=RADIO2G4@>>.OperatingStandards))",
			"possibleChannels" : "((Radio.<<@Radio.*.Alias=RADIO2G4@>>.PossibleChannels))",
			"channelsInUse" : "((Radio.<<@Radio.*.Alias=RADIO2G4@>>.ChannelsInUse))",
			"channel" : ((Radio.<<@Radio.*.Alias=RADIO2G4@>>.Channel)),
			"nodeMaxBitRate" : ((Radio.<<@Radio.*.Alias=RADIO2G4@>>.MaxBitRate)),
			"currentOperatingChannelBandwidth" : "((Radio.<<@Radio.*.Alias=RADIO2G4@>>.OperatingChannelBandwidth))",
			"supportedChannelBandwidth" : "((Radio.<<@Radio.*.Alias=RADIO2G4@>>.SupportedChannelBandwidth))",
			"autoChannelEnable" : ((Radio.<<@Radio.*.Alias=RADIO2G4@>>.AutoChannelEnable))
		},
		{
			"band": "5GHZ",
			"nodeMACAddr": "((SSID.<<@SSID.*.Alias=WL_VIDEO_5G@>>.MACAddress))",
			"ssid": "((SSID.<<@SSID.*.Alias=WL_VIDEO_5G@>>.SSID))",
			"status" : "((SSID.<<@SSID.*.Alias=WL_VIDEO_5G@>>.Status | NOTPRESENT))",
			"operatingStandard" : "((Radio.<<@Radio.*.Alias=RADIO5G@>>.OperatingStandards))",
			"possibleChannels" : "((Radio.<<@Radio.*.Alias=RADIO5G@>>.PossibleChannels))",
			"channelsInUse" : "((Radio.<<@Radio.*.Alias=RADIO5G@>>.ChannelsInUse))",
			"channel" : ((Radio.<<@Radio.*.Alias=RADIO5G@>>.Channel)),
			"nodeMaxBitRate" : ((Radio.<<@Radio.*.Alias=RADIO5G@>>.MaxBitRate)),
			"currentOperatingChannelBandwidth" : "((Radio.<<@Radio.*.Alias=RADIO5G@>>.OperatingChannelBandwidth))",
			"supportedChannelBandwidth" : "((Radio.<<@Radio.*.Alias=RADIO5G@>>.SupportedChannelBandwidth))",
			"autoChannelEnable" : ((Radio.<<@Radio.*.Alias=RADIO5G@>>.AutoChannelEnable))
		},
		{
			"band": "ETH1000",
			"nodeMACAddr":	"((Interface.<<@Interface.*.Alias=PHY6_WAN_MPTCP@>>.MACAddress))",
			"ssid": null,
			"status": "((Interface.<<@Interface.*.Alias=PHY6_WAN_MPTCP@>>.Status | NOTPRESENT))",
			"operatingStandard": null,
			"possibleChannels" : null,
			"channelsInUse" : null,
			"channel" : null,
			"nodeMaxBitRate" : 1000,
			"currentOperatingChannelBandwidth" : null,
			"supportedChannelBandwidth" : null,
			"autoChannelEnable" : null
		}
	],
	"wanInterfaceType": ((#Link.<<@Link.*.Alias=FTTH_DATA@>>.Status=UP))"FTTH_ETHERNET"((/Link.<<@Link.*.Alias=FTTH_DATA@>>.Status=UP))
						((#Link.<<@Link.*.Alias=FTTH_DATA@>>.Status=!UP))
						((#Link.<<@Link.*.Alias=VDSL_DATA@>>.Status=UP))"VDSL"((/Link.<<@Link.*.Alias=VDSL_DATA@>>.Status=UP))
						((#Link.<<@Link.*.Alias=VDSL_DATA@>>.Status=!UP))
						((#Link.<<@Link.*.Alias=ETHOA_DATA@>>.Status=UP))"ADSL"((/Link.<<@Link.*.Alias=ETHOA_DATA@>>.Status=UP))
						((#Link.<<@Link.*.Alias=ETHOA_DATA@>>.Status=!UP))"UNKNOWN"((/Link.<<@Link.*.Alias=ETHOA_DATA@>>.Status=!UP))
						((/Link.<<@Link.*.Alias=VDSL_DATA@>>.Status=!UP))
						((/Link.<<@Link.*.Alias=FTTH_DATA@>>.Status=!UP))
}

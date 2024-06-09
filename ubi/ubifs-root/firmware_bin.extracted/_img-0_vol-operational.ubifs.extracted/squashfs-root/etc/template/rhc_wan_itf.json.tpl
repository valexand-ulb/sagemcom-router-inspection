{{! -----------------------------------
	JSON partial template for RHC
	It is used to construct a partial JSON message at each sampling interval
	This partial JSON message will be added later to the master JSON message to be sent to server

	WAN Interface info

	xmo requests needed :
	- Device/IP/Interfaces/Interface[Alias='IP_DATA']
	--------------------------------------- }}
{
	"eventTime" : {{timestamp.epoch}},
{{#Interface.0}}
	"status" : "{{Status}}",
{{/Interface.0}}
{{#Interface.0.Stats}}
	"bytesSent": {{BytesSent}},
	"bytesReceived": {{BytesReceived}},
	"packetsSent": {{PacketsSent}},
	"packetsReceived": {{PacketsReceived}},
	"errorsSent": {{ErrorsSent}},
	"errorsReceived": {{ErrorsReceived}},
	"discardPacketsSent": {{DiscardPacketsSent}},
	"discardPacketsReceived": {{DiscardPacketsReceived}},
	"collisionsPackets": {{CollisionsPackets|0}}
{{/Interface.0.Stats}}
}
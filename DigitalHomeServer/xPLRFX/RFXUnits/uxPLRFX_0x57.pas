(***********************************************************)
(* xPLRFX                                                  *)
(* part of Digital Home Server project                     *)
(* http://www.digitalhomeserver.net                        *)
(* info@digitalhomeserver.net                              *)
(***********************************************************)
unit uxPLRFX_0x57;

interface

Uses uxPLRFXConst, u_xPL_Message, u_xpl_common, uXPLRFXMessages;

procedure RFX2xPL(Buffer : BytesArray; xPLMessages : TxPLRFXMessages);

implementation

Uses SysUtils;

(*

Type $57 - UV Sensors

Buffer[0] = packetlength = $09;
Buffer[1] = packettype
Buffer[2] = subtype
Buffer[3] = seqnbr
Buffer[4] = id1
Buffer[5] = id2
Buffer[6] = uv
Buffer[7] = temperaturehigh:7/temperaturesign:1
Buffer[8] = temperaturelow
Buffer[9] = battery_level:4/rssi:4

xPL Schema

sensor.basic
{
  device=uv1|uv2|uv3 0x<hex sensor id>
  type=uv
  current=(0-12)
}

sensor.basic
{
  device=uv1|uv2|uv30x<hex sensor id>
  type=temp
  current=<degrees celsius>
  units=c
}

sensor.basic
{
  device=uv1|uv2|uv30x<hex sensor id>
  type=battery
  current=0-100
}

*)

const
  // Type
  UV  = $5;

  // Subtype
  UV1  = $01;
  UV2  = $02;
  UV3  = $03;

var
  SubTypeArray : array[1..3] of TRFXSubTypeRec =
    ((SubType : UV1; SubTypeString : 'uv1'),
     (SubType : UV2; SubTypeString : 'uv2'),
     (SubType : UV3; SubTypeString : 'uv3'));


procedure RFX2xPL(Buffer : BytesArray; xPLMessages : TxPLRFXMessages);
var
  DeviceID : String;
  SubType : Byte;
  UV : Extended;
  Temperature : Extended;
  TemperatureSign : String;
  BatteryLevel : Integer;
  xPLMessage : TxPLMessage;
begin
  SubType := Buffer[2];
  DeviceID := GetSubTypeString(SubType,SubTypeArray)+IntToHex(Buffer[4],2)+IntToHex(Buffer[5],2);
  UV := Buffer[6] / 10;
  if SubType = UV3 then
    begin
      if Buffer[7] and $80 > 0 then
        TemperatureSign := '-';    // negative value
      Buffer[7] := Buffer[7] and $7F;  // zero out the temperature sign
      Temperature := ((Buffer[7] shl 8) + Buffer[8]) / 10;
    end;

  if (Buffer[9] and $0F) = 0 then  // zero out rssi
    BatteryLevel := 0
  else
    BatteryLevel := 100;

  // Create sensor.basic messages
  xPLMessage := TxPLMessage.Create(nil);
  xPLMessage.schema.RawxPL := 'sensor.basic';
  xPLMessage.MessageType := trig;
  xPLMessage.source.RawxPL := XPLSOURCE;
  xPLMessage.target.IsGeneric := True;
  xPLMessage.Body.AddKeyValue('device='+DeviceID);
  xPLMessage.Body.AddKeyValue('current='+FloatToStr(UV));
  xPLMessage.Body.AddKeyValue('type=uv');
  xPLMessages.Add(xPLMessage.RawXPL);
  xPLMessage.Free;

  if SubType = UV3 then
    begin
      xPLMessage := TxPLMessage.Create(nil);
      xPLMessage.schema.RawxPL := 'sensor.basic';
      xPLMessage.MessageType := trig;
      xPLMessage.source.RawxPL := XPLSOURCE;
      xPLMessage.target.IsGeneric := True;
      xPLMessage.Body.AddKeyValue('device='+DeviceID);
      xPLMessage.Body.AddKeyValue('current='+TemperatureSign+FloatToStr(Temperature));
      xPLMessage.Body.AddKeyValue('units=c');
      xPLMessage.Body.AddKeyValue('type=temperature');
      xPLMessages.Add(xPLMessage.RawXPL);
      xPLMessage.Free;
    end;

  xPLMessage := TxPLMessage.Create(nil);
  xPLMessage.schema.RawxPL := 'sensor.basic';
  xPLMessage.MessageType := trig;
  xPLMessage.source.RawxPL := XPLSOURCE;
  xPLMessage.target.IsGeneric := True;
  xPLMessage.Body.AddKeyValue('device='+DeviceID);
  xPLMessage.Body.AddKeyValue('current='+IntToStr(BatteryLevel));
  xPLMessage.Body.AddKeyValue('type=battery');
  xPLMessages.Add(xPLMessage.RawXPL);
  xPLMessage.Free;

end;


end.

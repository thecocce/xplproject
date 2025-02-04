(***********************************************************)
(* xPLRFX                                                  *)
(* part of Digital Home Server project                     *)
(* http://www.digitalhomeserver.net                        *)
(* info@digitalhomeserver.net                              *)
(***********************************************************)
unit uxPLRFX_0x28;

interface

Uses uxPLRFXConst, u_xPL_Message, u_xpl_common, uxPLRFXMessages;

procedure RFX2xPL(Buffer : BytesArray; xPLMessages : TxPLRFXMessages);
procedure xPL2RFX(aMessage : TxPLMessage; var Buffer : BytesArray);

implementation

Uses SysUtils;

(*

Type $28 - Camera1/Robocam

Buffer[0] = packetlength = $06;
Buffer[1] = packettype
Buffer[2] = subtype
Buffer[3] = seqnbr
Buffer[4] = housecode
Buffer[5] = cmnd
Buffer[6] = filler:4/rssi:4

xPL Schema

control.basic
{
  device=<housecode>
  protocol=ninja
  current=left|right|up|down|p1|prog_p1|p2|prog_p2|p3|prog_p3|p4|prog_p4|center|prog_center|sweep|prog_sweep
}

*)

const
  // Packet length
  PACKETLENGTH     = $06;

  // Type
  CAMERA1          = $28;

  // Subtype
  X10_NINJA        = $00;

  // Commands
  COMMAND_LEFT        = 'left';
  COMMAND_RIGHT       = 'right';
  COMMAND_UP          = 'up';
  COMMAND_DOWN        = 'down';
  COMMAND_P1          = 'p1';
  COMMAND_PROG_P1     = 'prog_p1';
  COMMAND_P2          = 'p2';
  COMMAND_PROG_P2     = 'prog_p2';
  COMMAND_P3          = 'p3';
  COMMAND_PROG_P3     = 'prog_p3';
  COMMAND_P4          = 'p4';
  COMMAND_PROG_P4     = 'prog_p4';
  COMMAND_CENTER      = 'center';
  COMMAND_PROG_CENTER = 'prog_center';
  COMMAND_SWEEP       = 'sweep';
  COMMAND_PROG_SWEEP  = 'prog_sweep';


var
  // Lookup table for commands
  RFXCommandArray : array[1..16] of TRFXCommandRec =
    ((RFXCode : $00; xPLCommand : COMMAND_LEFT),
     (RFXCode : $01; xPLCommand : COMMAND_RIGHT),
     (RFXCode : $02; xPLCommand : COMMAND_UP),
     (RFXCode : $03; xPLCommand : COMMAND_DOWN),
     (RFXCode : $04; xPLCommand : COMMAND_P1),
     (RFXCode : $05; xPLCommand : COMMAND_PROG_P1),
     (RFXCode : $06; xPLCommand : COMMAND_P2),
     (RFXCode : $07; xPLCommand : COMMAND_PROG_P2),
     (RFXCode : $08; xPLCommand : COMMAND_P3),
     (RFXCode : $09; xPLCommand : COMMAND_PROG_P3),
     (RFXCode : $0A; xPLCommand : COMMAND_P4),
     (RFXCode : $0B; xPLCommand : COMMAND_PROG_P4),
     (RFXCode : $0C; xPLCommand : COMMAND_CENTER),
     (RFXCode : $0D; xPLCommand : COMMAND_PROG_CENTER),
     (RFXCode : $0E; xPLCommand : COMMAND_SWEEP),
     (RFXCode : $0F; xPLCommand : COMMAND_PROG_SWEEP)
    );

procedure RFX2xPL(Buffer : BytesArray; xPLMessages : TxPLRFXMessages);
var
  DeviceID : String;
  Current : String;
  xPLMessage : TxPLMessage;
begin
  DeviceID := Chr(Buffer[4]);
  Current := GetxPLCommand(Buffer[5],RFXCommandArray);

  // Create control.basic message
  xPLMessage := TxPLMessage.Create(nil);
  xPLMessage.schema.RawxPL := 'control.basic';
  xPLMessage.MessageType := trig;
  xPLMessage.source.RawxPL := XPLSOURCE;
  xPLMessage.target.IsGeneric := True;
  xPLMessage.Body.AddKeyValue('device='+DeviceID);
  xPLMessage.Body.AddKeyValue('current='+current);
  xPLMessage.Body.AddKeyValue('protocol=ninja');
  xPLMessages.Add(xPLMessage.RawXPL);
end;

procedure xPL2RFX(aMessage : TxPLMessage; var Buffer : BytesArray);
begin
  ResetBuffer(Buffer);
  Buffer[0] := PACKETLENGTH;
  Buffer[1] := CAMERA1;  // Type
  Buffer[2] := X10_NINJA;
  Buffer[4] := Ord(aMessage.Body.Strings.Values['device'][1]);
  Buffer[5] := GetRFXCode(aMessage.Body.Strings.Values['current'],RFXCommandArray);
end;

end.

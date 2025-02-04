﻿Readme file for UPnP-2-xPL gateway
==================================
Copyright 2010-2011 Thijs Schreijer


Schema used for UPnP gateway

A UPnP device will be dissected into its components and each component will get 
its own unique ID. The components are;
 - Device
 - Subdevice
 - Service
 - Variable
 - Method
 - Argument
The ID tag for the elements are a comma-separated list, of which the first one 
is the ID of that element, the others are sub elements (child elements).

== Uniqueness ==
The component IDs will NOT remain the same over sessions, they will be 
regenerated for each new session. So you should not rely on them. You should
rely only on the UDN (unique device name, usually a UUID) of the UPnP device.

== Announcing a new UPnP device ==
When a new device is added, it is dissected into its components. For each 
component a separate announce message will be send. Its a trigger message
defined as follows;
upnp.announce
{
announce = <device|subdevice|service|variable|method|argument|left>
id = <comma separated ID list>
[parent = <parentid>]
[element specific data]
}
Remarks;
 - only a 'device' and 'left' anounce message will NOT have a 'parent' key
 - The <comma separated ID list> is a list starting with the elements own ID
   and followed by any children it has (only 1st level children, not recursive)
 - an 'announce=left' message is used to indicate a device leaving, it will
   only have the 'id=...' key value pair. Indicating who has left.
   There will always be only 1 root device leaving per message, and hence the
   id will only contain the id of the root device leaving (no child IDs).
   
== Devices leaving ==
A special case of the announce message will be send. See 'Announcing a new UPnP
device'.

== Announce requests ==
To request a device to announce again, send a command message;

upnp.basic
{
command = announce
[id = <ID>]
[id = ...]
}
This will trigger a new announce cycle, which will announce all elements of the
requested ID again. If no ID is provided, then all devices known by the getway 
will announce again. At start up an application may broadcast this command to 
discover all UPnP devices available. Multiple requests can be combined by 
having multiple ID keys, each with 1 ID requested.

== Value updates (StateVariable events) ==
Whenever an evented state variable changes its value, the event will result
in a trigger message;

upnp.basic
{
<id> = <value>
[<id> = <value>]
}
The keys of this message will correspond to the ID's of the statevariable who's
value changed. The value, is the new value of the variable.
Generally, its only a single value per message. Devices that use the 
'LastUpdate' mechanism as described in the AV Rendering Control description 
(version 1.0, par 2.3) will get more than one value. 
NOTE: the 'LastUpdate' type updates are for devices supporting multiple 
instances, the gateway will only handle the first.

== call methods ==
To call a method on a device, use the following command message;

upnp.method
{
command=methodcall
method=<id of method>
[callid=<uniqueid>]
[<id arg 1>=<value argument 1>]
[<id arg n>=<value argument n>]
}
the key 'callid' is optional and is returned with the response so the command
and its response can be connected back together (calls are async).

The response will be a trigger message;
upnp.method
{
[callid=<uniqueid>]
success=<true|false>
[error=error text]
[retval=<return value>]
<id>=<value>
[<id>=<value>]
}
The callid value will be only be present if provided with the command, and will 
have the same value that was provided with the command.
The key 'success' is a boolean indicating success.
In case of failure the 'error' key indicates the error message, no other keys
will be provided.
In case of success, no 'error' key will be available, but the returnvalue 
(retval) will be present along with all id's and values of arguments with 
direction 'out'.

{
    This file is part of the Free Component Library

    MCP LCL control - resource strings
    Copyright (c) 2026 by Michael Van Canneyt michael@freepascal.org

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit mcp.lcl.strings;

{$mode objfpc}{$H+}

interface

Resourcestring
  SErrMainThreadTimeout = 'Timed out waiting for the GUI main thread';
  SErrLocatorNotFound = 'Control not found for locator: %s';
  SErrControlDisabled = 'Control of the running application is disabled';
  SErrNoProperty = 'Published property not found: %s';
  SErrNotAControl = 'Target is not a paintable control: %s';
  SErrPropertyType = 'Value type does not match property: %s';
  SErrNotActionable = 'Target is not actionable (no OnClick handler or bound action): %s';
  SErrNotInjectable = 'Target cannot receive injected input events: %s';
  SErrWaitTimeout = 'Timed out waiting for property to reach the expected value: %s';
  SErrNoAccessor = 'Accessor not registered: %s';
  SErrOSInputUnavailable = 'OS-level input injection is not available on this platform: %s';
  SFormOpened = 'Form opened: %s (%s)';
  SFormClosed = 'Form closed: %s (%s)';

implementation

end.

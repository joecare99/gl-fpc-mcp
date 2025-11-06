unit mcpstrings;

{$mode objfpc}{$H+}

interface

const
  cMCPToolName = 'MCPTool';
  cDefaultToolClassName = 'TMyMCPTool';

resourcestring
  rsAITab = 'AI';
  rsMCPCategory  = 'MCP';
  rsMcpToolName = 'MCP Tool';
  rsMcpToolDescription = 'A unit with a single MCP tool';
  rsDefaultToolName = 'My MCP tool';
  rsDefaultToolDescription = 'My first MCP tool';
  rsToolClassNameRequired = 'The tool class name is required';
  rsToolClassNameIdentifier = 'The tool class name needs to be a valid identifier';
  rsToolNameRequired = 'A tool name is required';
  rsToolDescriptionRequired = 'A tool description is required';
  rsToolReturnRequired = 'A tool return type is required';
  rsIncomplete = 'MCP Tool information incomplete';

implementation

end.


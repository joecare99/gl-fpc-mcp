# MCP

MCP is a Free Pascal implementation of the [Model Context Protocol](https://modelcontextprotocol.io/specification/2025-06-18)
It offers classes to implement a MCP server as well as a MCP client.

It also offers the start of a MCP tool server that will allow an AI agent to control Lazarus.

## License
This code is licensed with the usual FPC LGPL with linking exception license.

## Repo layout

The [docs](docs) directory contains a presentation of the framework given at
the Pascal AI workshop organized by Blaise Pascal Magazine on 2025-07-12.

* [Src/Base](Src/Base) contains the source code for all classes to create a
  MCP server
* [Src/IDE] Contains the packages for Lazarus IDE integration
* [Src/proxy] Contains the MCP proxy (using the private socket protocol)




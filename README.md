# About

A docker image that allows you to convert Studio Exports (.xml exports) into the UDL format used by the VS Code extension and the atelier API.

# Usage
## Build Image

1. Clone this repository
2. docker build -t xml-to-udl:latest .

## Convert

The following can be executed in any arbitary directry:

``
docker run --rm -v "path-to-xml.xml:/irisrun/export.xml" -v "export-src:/irisrun/udl-export"  xml-to-udl
``

Wait for it to complete and shtudown iris, then exit the container. Done!
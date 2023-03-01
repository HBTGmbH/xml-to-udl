# XML-to-UDL

A docker image that allows you to convert a InterSystems Studio export (.xml) into UDL format used by the InterSystems ObjectScript extension for VS Code and the atelier API (without using the IRIS Studio). 

## Prerequisites

Make sure you have [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) and [Docker Desktop](https://www.docker.com/products/docker-desktop) installed. Windows users should use the PowerShell for executing the following docker commands (e.g. ${pwd} only works in the PowerShell). For Linux users we provide a bash script `ìmport-studio-export.sh` that handles permission problems when mounting the docker volume for the UDL export.

## Features

- Docker container that starts a IRIS instance which converts a Studio export to sources and stops afterwards
- generation of sources within seconds using only one command
- preparation of the Studio export content for version control with Git
- generation of folder hierarchy based on the class names
- handling of the most common file types (for example ".cls", ".lut", ".hl7", ".inc", ".gbl").
- convenient use in combination with the VS Code Extensions from InterSystems


## Good to know

The tool was created based on our own project requirements and will be developed further as needed. Among other things, it creates a folder hierarchy based on the class name. So the class "App.TCPTestServiceRoutingRule" mentioned in the export is created as follows "src/App/TCPTestServiceRoutingRule.cls". 

This results in a problem with a folder name "CON" because no folder with this name can be created on Windows machines. If this occurs, the tool ensures that the folder is renamed to "C0N". **Please consider this behavior if your Studio export contains the path "CON" at any point.**

## Usage

Pull the image.

```
docker pull ghcr.io/hbtgmbh/xml-to-udl/converter:latest
```
Add a Studio export file (.xml) in any arbitary directory and add a folder named "src".

Replace **<YOUR_STUDIO_EXPORT>** with the filename of your export file and execute the following command in this directory.

On Windows:
```
docker run -v "${pwd}/<YOUR_STUDIO_EXPORT>.xml:/irisrun/export.xml" -v "${pwd}/src:/irisrun/udl-export" --rm ghcr.io/hbtgmbh/xml-to-udl/converter:latest
```
On Linux:
```
./import-studio-export.sh
```

After the conversion is finished you should now see the generated sources under "src".

## Examples

You can find a sample [studio export](
https://github.com/HBTGmbH/xml-to-udl/blob/master/studio-export-sample/studio-export.xml) in this repository. 
 This export contains samples of the most common file types (for example ".cls", ".lut", ".hl7", ".inc", ".gbl"). 

It's a good practice to use this tool in combination with the [ObjectScript Docker template](https://github.com/intersystems-community/objectscript-docker-template). This template already provides a "src" directory. So you just need to clone/forke this template for your project, add the studio export to the root directory and execute:

```
docker run -v "${pwd}/studio-export.xml:/irisrun/export.xml" -v "${pwd}/src:/irisrun/udl-export" --rm ghcr.io/hbtgmbh/xml-to-udl/converter:latest
```
After generating the source files it's quite easy to use version control with Git and keep track of your changes during the project.

## Contributing
For major changes, please open an issue first
to discuss what you would like to change.

## Demo

This video demonstrates how you can use the tool in combination with the ObjectScript Docker template. At the end you can see the generated sources that you can commit to your Git repository.


https://user-images.githubusercontent.com/73107657/215094182-48eab487-417f-4533-aba9-646d63abf7c2.mp4



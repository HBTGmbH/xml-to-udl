
# XML-to-UDL

A docker image that allows you to convert InterSystems Studio exports (.xml) into UDL format used by the InterSystems ObjectScript extension for VS Code and the atelier API. 

## Prerequisites

Make sure you have [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) and [Docker Desktop](https://www.docker.com/products/docker-desktop) installed. 

Windows users should use the PowerShell for executing the following docker commands (e.g. ${pwd} only works in the PowerShell).
## Usage

1. Pull the image 

`docker pull ghcr.io/hbtgmbh/xml-to-udl/converter:latest`

2. Add a Studio export (.xml) in any arbitary directory and add a folder named "src"

3. Replace **<YOUR_STUDIO_EXPORT>** with the filename of your export file and execute the following command in this directory

`docker run -v "${pwd}/<YOUR_STUDIO_EXPORT>.xml:/irisrun/export.xml" -v "${pwd}/src:/irisrun/udl-export" --rm ghcr.io/hbtgmbh/xml-to-udl/converter`

4. Wait until the conversion is finished

5. You should now see the generated sources under "src"

## Examples

You can find a sample studio export under **/studio-export-sample/studio-export.xml** in this repository. 

This export contains some of the most common file types (for example ".cls", ".lut", ".hl7", ".inc", ".gbl"). 

It's a good practice to use this tool in combination with the [ObjectScript Docker Template](https://github.com/intersystems-community/objectscript-docker-template). This template already provides a "src" directory. So you just need to add the studio export to the root directory and execute:

`docker run --rm -v "${pwd}/studio-export.xml:/irisrun/export.xml" -v "${pwd}/src:/irisrun/udl-export" xml-to-udl:latest`

After generating the source files it's quite easy to use version control with Git and keep track of your changes during the project.
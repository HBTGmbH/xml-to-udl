
# XML-to-UDL

A docker image that allows you to convert InterSystems Studio exports (.xml) into the UDL format used by the VS Code extension and the atelier API.


## Prerequisites

Make sure you have [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) and [Docker Desktop](https://www.docker.com/products/docker-desktop) installed.
## Usage

1. Clone this repository into any local directory  
`git clone https://github.com/HBTGmbH/xml-to-udl.git`

2. Run the following command in the root directory to build the image locally 
`docker build -t xml-to-udl:latest .`

3. Now you need to know the path to your Studio export file (.xml) 

4. Replace <PATH_TO_STUDIO_EXPORT> with the filename of your export and execute the following command in any arbitary directory  
`docker run --rm -v "${pwd}/<PATH_TO_STUDIO_EXPORT>.xml:/irisrun/export.xml" -v "${pwd}/src:/irisrun/udl-export"  xml-to-udl:latest`

5. Wait for it to complete and shutdown IRIS, then exit the container. Done!

## Examples

You can find a sample studio export under **/studio-export-sample/studio-export.xml**. This export contains some of the most common file types (for example ".cls", ".lut", ".hl7", ".inc", ".gbl"). 

Just copy the export file to a directory of your choice, add a folder called "src" and build the image like it's described in the "Usage" section. Finally execute `docker run --rm -v "${pwd}/studio-export.xml:/irisrun/export.xml" -v "${pwd}/src:/irisrun/udl-export"  xml-to-udl:latest` to test the functionality. You should now find some sample files in the "src" directory.

It's a good practice to use this tool in combination with the [ObjectScript Docker Template](https://github.com/intersystems-community/objectscript-docker-template). It allows you to set up a local IRIS instance and use the sources from a existing project without the need to use IRIS Studio.

After generating the source files it's quite easy to use version control with Git and keep track of your changes.




#!/bin/bash
# Run Docker Container to generate source files from studio-export.xml

# Default XML file
XML_FILE="studio-export.xml"

# Parse command line arguments
NEWLINE=1
while [[ $# -gt 0 ]]; do
    case "$1" in
        -x|--xml)
            XML_FILE="$2"
            shift 2
            ;;
        -n|--no-newline)
            NEWLINE=0
            shift 2
            ;;
        *)
            # Unknown option
            echo "Error: Unrecognized option '$1'"
            echo "Usage: $0 [-x|--xml XML_FILE]"
            exit 1
            ;;
    esac
done

# If a different XML file is specified, move it to studio-export.xml
if [ "$XML_FILE" != "studio-export.xml" ]; then
    echo "Moving $XML_FILE to studio-export.xml..."
    mv "$XML_FILE" "studio-export.xml"
    XML_FILE="studio-export.xml"
fi

docker run -v "`pwd`/$XML_FILE:/irisrun/export.xml" -v "`pwd`/src/:/irisrun/udl-export" --name xml-to-udl --rm xml-to-udl:latest

# Run Script to Fix inconsistencies on MacOs
#if [ "$NEWLINE" -eq 1 ]; then
#    fix-after-import.sh
#else
#fix-after-import.sh --no-newline
#fi
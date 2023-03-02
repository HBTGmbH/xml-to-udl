#!/bin/bash

# start IRIS
iris start IRIS quietly > /dev/null

# if sucessfully started, call conversion method and print terminal session to stdout
if [[ $? -eq 0 ]]; then
    cat << EOF | iris session IRIS
Do ##class(HBT.XMLToUDL).ImportUDLFromDefault()
Halt
EOF
fi

# stop IRIS after conversion
iris stop $ISC_PACKAGE_INSTANCENAME quietly

# exit with same exit code as previous command
exit $?

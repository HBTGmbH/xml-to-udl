#!/bin/bash

# prepare web application configurations
if [ "$(ls -A /webapplications/ | grep -E '.*xml$')" != "" ] ; then
    echo "found web application confiugurations ..."
    cp /webapplications/*.xml /converted-webapps/
    for inputfile in /converted-webapps/*.xml ; do
        echo "prepare web appclication config file '$inputfile' for import"
        # replace namespace with default namespace USER
        sed -i -E "s/<NameSpace>.*<\/NameSpace>/<NameSpace>USER<\/NameSpace>/" $inputfile
    done
fi

# start IRIS
iris start IRIS quietly > /dev/null

# import web application configurations
if [ "$(ls -A /converted-webapps/ | grep -E '.*xml$')" != "" ] ; then
    for inputfile in /converted-webapps/*.xml ; do
        echo "import web application config from $inputfile"
        # call web application import-method from IRIS terminal session
        cat << EOF | iris session IRIS
zn "%SYS"
Write !,##class(Security.Applications).Import("$inputfile")
zn "USER"
Halt
EOF
    done
fi


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

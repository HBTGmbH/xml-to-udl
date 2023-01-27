#!/bin/bash
iris session IRIS <<< 'zwrite ##class(HBT.XMLToUDL).ImportUDLFromDefault()'
echo "Successfully Converted!"
kill $(ps aux | grep 'iris-main' | awk '{print $2}')
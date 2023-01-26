#!/bin/bash
iris session IRIS <<< 'zwrite ##class(HBT.XMLToUDL).ImportUDLFromDefault()'
echo "Successfully Converted!"
iris stop IRIS quietly
iris force IRIS quietly
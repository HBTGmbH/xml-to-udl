#!/bin/bash
iris session IRIS <<< 'zwrite ##class(HBT.XMLToUDL).ImportUDLFromDefault()'
echo "Successfully Converted!"
iris stop iris quietly
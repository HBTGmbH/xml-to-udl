#!/bin/bash
iris session IRIS <<< 'zwrite ##class(HBT.Utility.XMLToUDL).ImportUDLFromDefault()'
echo "Successfully Converted!"
iris stop iris quietly
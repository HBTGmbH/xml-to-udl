ROUTINE HBT.Utility [Type=INC]

#Define StringEndsWith(%str, %match) $extract(%str, *-$length(%match)+1, *) = %match
#Define StringStartsWith(%str, %match) $extract(%str, 0, $length(%match)) = %match

#Define StringRemoveLast(%str) $extract(%str, 0, *-1)
#Define StringRemoveLastN(%str, %count) $extract(%str, 0, *-%count)

#Define StringToLower(%str) $ZCONVERT(%str, "L")
#Define StringToUpper(%str) $ZCONVERT(%str, "Z")
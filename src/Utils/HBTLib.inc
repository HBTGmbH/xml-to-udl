ROUTINE Utils.HBTLib [Type=INC]

#Define StringEndsWith(%str, %match) $extract(%str, *-$length(%match)+1, *) = %match
#Define StringStartsWith(%str, %match) $extract(%str, 0, $length(%match)) = %match

#Define StringRemoveLast(%str) $extract(%str, 0, *-1)
#Define StringRemoveLastN(%str, %count) $extract(%str, 0, *-%count)

#Define StringToLower(%str) $ZCONVERT(%str, "L")
#Define StringToUpper(%str) $ZCONVERT(%str, "Z")

#Define isGenerated(%code) ##class(%RoutineMgr).IsGenerated(%code)
#Define isPercented(%code) ("%" = $e(%code))
#Define isMapped(%code) ##class(%RoutineMgr).IsMapped(%code)

#Define log(%dir,%sc) w "mkdir ", %dir, " ", sc, !
#Define GetExtension(%str) $ZCONVERT($PIECE(%str,".",*), "l")
Include HBT.Utility

/// Description
Class HBT.Utility.XMLToUDL
{

Parameter WORKINGDIRECTORY = "/irisrun/udl-export";

/// This method is the entrypoint for the transformation of the studio export file into UDL sources.
/// The export process will be started for every item in the export, after it's verified that the item is not part of a ignore list. 
ClassMethod ImportUDLFromDefault() As %Status
{
    #Dim tSC As %Status
    #Dim tSE As %Exception.StatusException
    #Dim tImportedItems as %String // CSV list of imported items
    #Dim tLocation as %String
    #Dim tFixedLocation as %String
    #Dim tItemName as %String

    Try {
        Set tLocation = "/irisrun/udl-export/aa/studio-export.xml"
        Set tFixedLocation = "/opt/irisbuild/export-fixed.xml"
        $$$ThrowOnError(##class(cls.HBT.Utility.CustomizedHelper).FixExportFile(tLocation, tFixedLocation))
        Write "Importing from location: '"_tFixedLocation,!
        Do $SYSTEM.OBJ.Load(tFixedLocation,"",.%errorlog,.tImportedItems,0,,)
        Write "Imported: ",!, tImportedItems,!,!
        Set tItemList = $LISTFROMSTRING(tImportedItems, ",")
        For i=1:1:$LISTLENGTH(tItemList) {
            Set tItemName = $LIST(tItemList,i)
            $$$ThrowOnError(##class(cls.HBT.Utility.CustomizedHelper).GetIgnoreStatus(tItemName, .pIgnoreItem))
            If ('pIgnoreItem) {
                Write !,"Exporting Item: ", tItemName,!
                $$$ThrowOnError(..ExportFile(tItemName))
            } Else {
                Write !,"Skip exporting Item, because it's on the ignore list: ", tItemName,!
            }
        }
        Set tSC = $$$OK
    } Catch tSE {
        Set tSC = tSE.AsStatus()
        Quit
    }
    Quit tSC
}

ClassMethod ExportFile(pItemName As %String) As %Status
{
    #Dim rSC As %Status
    #Dim tSE As %Exception.StatusException
    #Dim tClassAndRoutinesExtensions As List of %String
    #Dim tItemExtension As %String

    Try {
        Set tClassAndRoutinesExtensions = $LISTBUILD("cls","mac","int","inc")
        Set tItemExtension = $$$GetExtension(pItemName)
        Write "Extension: ", tItemExtension, !
        If $LISTFIND(tClassAndRoutinesExtensions, tItemExtension) {
            $$$ThrowOnError(..ExportClassAndRoutine(pItemName))
        } Else {
            $$$ThrowOnError(..ExportCommonItemsByExtension(tItemExtension,pItemName))
        }
        Set rSC = $$$OK
    } Catch tSE {
        Set rSC = tSE.AsStatus()
        Quit
    }
    Quit rSC
}

/// This method triggers the export of classes and routines.
ClassMethod ExportClassAndRoutine(pClassName As %String) As %Status
{
    #Dim tSC As %Status
    #Dim tSE As %Exception.StatusException
    #Dim tFileName As %String

    Try {
        // TODO Die If Abfragen kann man auch noch optimieren
        If ($$$isGenerated(pClassName)) Return $$$OK
        If ($$$isPercented(pClassName)) Return $$$OK
        If ($$$isMapped(pClassName)) Return $$$OK
        
        Set tFileName = ..CreateFileName(pClassName)
        Write "Export data ...",!
        Write "File: '", tFileName,!
        Write "Class: '", pClassName,!
        $$$ThrowOnError(..MakeDirectory(tFileName))
        $$$ThrowOnError($SYSTEM.OBJ.ExportUDL(pClassName, tFileName))
        Set tSC = $$$OK
    } Catch tSE {
        Set tSC = tSE.AsStatus()
        Quit
    }
    Quit tSC
}

/// This method triggers the export of common files that are not classes or routines (for example .hl7 or .lut files).
/// Depending on the file type, the file name will set accordingly.
ClassMethod ExportCommonItemsByExtension(pItemExtension As %String, pItemName As %String) As %Status
{
    #Dim tSC As %Status
    #Dim tSE As %Exception.StatusException
    #Dim tFileName As %String
    
    Try {
        If (pItemExtension = "hl7") || (pItemExtension = "csp") || (pItemExtension = "lut") {
            Set tFileName = ..CreateFileName(pItemName)
        } ElseIf (pItemExtension = "dfi") {
            Set tFileName = ..CreateFileName($REPLACE(pItemName,"-","/"))
            Set tFileName = $EXTRACT(tFileName,1,*-4)_".xml"
        } Else {
            Set tFileName = ..CreateFileName($REPLACE(pItemName,"-","/"))
        }
        Do ..MakeDirectory(tFileName)
        Do ##class(cls.HBT.Utility.CustomizedHelper).FixXMLLine(pItemName, tFileName)
        Set tSC = $$$OK
    } Catch tSE {
        Set tSC = tSE.AsStatus()
        Quit
    }
    Quit tSC
}

ClassMethod CreateFileName(pItemName As %String) As %Status
{
    #Dim tSC As %Status
    #Dim tSE As %Exception.StatusException
    #Dim tWorkingDirectory As %String
    #Dim tExtension As %String
    #Dim tSplitFiles As %Boolean
    #Dim tFileName As %String
    #Dim tDirectory As %String
    #Dim tRelativePath As %String

    Try {
        Set tWorkingDirectory = ..#WORKINGDIRECTORY
        If '##class(%File).DirectoryExists(tWorkingDirectory) {
		    $$$ThrowOnError(##class(%File).CreateDirectoryChain(tWorkingDirectory))
	    }
        Set tExtension = $$$GetExtension(pItemName)
        Write "Directory: ",tWorkingDirectory,!
        Set tFileName = ##class(%File).NormalizeFilename(pItemName,tWorkingDirectory)
        // Don't split HL7 schema files by dots
        If (tExtension '= "hl7") {
            Set tDirectory = $PIECE(pItemName, ".",1, *-2 )
            Set tDirectory = $TRANSLATE(tDirectory, ".", "/")
            Set tRelativePath = tDirectory_"/"_$PIECE(pItemName, ".", *-1, *)
            Set tFileName = ##class(%File).NormalizeFilename(tRelativePath, tWorkingDirectory)
        }
        // Make sure that the files are stored in the "src" directory of the project 
        Write "Filename before IF: ",tFileName,!
        If ('$FIND(tFileName, tWorkingDirectory)) {
            Write "Did not found WD String: ",tWorkingDirectory,!
            Set tFileName = tWorkingDirectory_tFileName
        }
        Write "Filename after IF: ",tFileName,!
        Return tFileName
        Set tSC = $$$OK
    }
    Catch tSE {
            Set tSC = tSE.AsStatus()
            Quit
        }
    Quit tSC
}

/// This method creates the directory for a specific file if it it does not exist yet.
ClassMethod MakeDirectory(pFileName As %String) As %Status
{
    #Dim tSC As %Status
    #Dim tSE As %Exception.StatusException
    #Dim tPath As %String
    #Dim tPathToCreate As %String

    Try {
        Set tPath = ##class(%File).GetDirectory(pFileName)
        If ($$$StringEndsWith(tPath, "/")) {
            Set tPath = $$$StringRemoveLast(tPath)
        }
        If '##class(%File).DirectoryExists(tPath){
            If ('$$$StringStartsWith(tPath, "/irisrun/udl-export")) {
                Set tPathToCreate = "/irisrun/udl-export"_tPath
            } Else {
                Set tPathToCreate = tPath
            }
            Write !, "Directory does not exist. Creating: "_tPathToCreate, ! 
            Set tResult = ##class(%File).CreateDirectoryChain(tPathToCreate, .tReturn)
            Write "Directory create status: ", tResult, !
            If ('tResult) {
                ZWrite tReturn
            }
	    }
        Set tSC = $$$OK
    } Catch tSE {
        Set tSC = tSE.AsStatus()
        Quit
    }
    Quit tSC
}

}

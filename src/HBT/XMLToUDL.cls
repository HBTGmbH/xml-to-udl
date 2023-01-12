Include Utils.HBTLib

/// This class offers the functionality to transform a studio export file (.xml) into UDL sources (.cls, .hl7, .lut etc.) and to set up a directory and folder structure.
Class HBT.XMLToUDL
{

Parameter WORKINGDIRECTORY = "/irisrun/udl-export";

/// This method is the entrypoint for the transformation of the studio export file into UDL sources.
ClassMethod ImportUDLFromDefault() As %Status
{
    #Dim tSC As %Status
    #Dim tSE As %Exception.StatusException
    #Dim tLocation as %String
    #Dim tFixedLocation as %String
    #Dim tImportedItems as %String // CSV list of imported items

    Try {
        Set tLocation = "/irisrun/export.xml"
        Set tFixedLocation = "/opt/irisbuild/export-fixed.xml"
        Set tWorkingDirectory = ..#WORKINGDIRECTORY
        If '##class(%File).DirectoryExists(tWorkingDirectory) {
		    $$$ThrowOnError(##class(%File).CreateDirectoryChain(tWorkingDirectory))
	    }
        $$$ThrowOnError(##class(Utils.CustomizedHelper).FixExportFile(tLocation, tFixedLocation))
        $$$ThrowOnError($SYSTEM.OBJ.Load(tFixedLocation,"",.%errorlog,.tImportedItems,0,,))
        $$$ThrowOnError(..ExportFiles(tImportedItems))
        Set tSC = $$$OK
    } Catch tSE {
        Set tSC = tSE.AsStatus()
        Quit
    }
    Quit tSC
}

/// This method checks the file type and decides which export method must be used to export the corresponding item.
/// The export process will be started for every item in the export, after it's verified that the item is not part of a ignore list. 
ClassMethod ExportFiles(pImportedItems As %String) As %Status
{
    #Dim tSC As %Status
    #Dim tSE As %Exception.StatusException
    #Dim tItemList As List of %String
    #Dim tClassAndRoutinesExtensions As List of %String
    #Dim tItemName As %String
    #Dim tIgnoreItem As %Boolean
    #Dim tItemExtension As %String

    Try {
        Set tItemList = $LISTFROMSTRING(pImportedItems, ",")
        Set tClassAndRoutinesExtensions = $LISTBUILD("cls", "mac", "int", "inc")
        For i=1:1:$LISTLENGTH(tItemList) {
            Set tItemName = $LIST(tItemList, i)
            // check if the file should be ignored
            $$$ThrowOnError(##class(Utils.CustomizedHelper).GetIgnoreStatus(tItemName, .tIgnoreItem))
            If ('tIgnoreItem) {
                Write !,"Exporting File: ", tItemName,!
                Set tItemExtension = $$$GetExtension(tItemName)
                If $LISTFIND(tClassAndRoutinesExtensions, tItemExtension) {
                    $$$ThrowOnError(..ExportClassAndRoutine(tItemName))
                } Else {
                    $$$ThrowOnError(..ExportOtherItem(tItemName))
                }
            } Else {
                Write !,"Skip exporting file, because it is on the ignore list: ", tItemName,!
            }
        }
        Set tSC = $$$OK
    } Catch tSE {
        Set tSC = tSE.AsStatus()
        Quit
    }
    Quit tSC
}

/// This method triggers the export of classes and routines.
ClassMethod ExportClassAndRoutine(pClassName As %String) As %Status
{
    #Dim tSC As %Status
    #Dim tSE As %Exception.StatusException
    #Dim tFileName As %String

    Try {
        If ($$$isGenerated(pClassName)) || ($$$isPercented(pClassName)) || ($$$isMapped(pClassName)) {
            Return $$$OK
        } 
        $$$ThrowOnError(..CreateFileName(pClassName, .tFileName))
        $$$ThrowOnError(..CreateDirectory(tFileName))
        $$$ThrowOnError($SYSTEM.OBJ.ExportUDL(pClassName, tFileName))
        Set tSC = $$$OK
    } Catch tSE {
        Set tSC = tSE.AsStatus()
        Quit
    }
    Quit tSC
}

/// This method triggers the export of common files that are not classes or routines (for example .hl7 or .lut files).
/// Depending on the file type, the file name will be set accordingly.
ClassMethod ExportOtherItem(pItemName As %String) As %Status
{
    #Dim tSC As %Status
    #Dim tSE As %Exception.StatusException
    #Dim tItemExtension As %String
    #Dim tCommonItemTypes As List of %String
    #Dim tFileName As %String
    
    Try {
        Set tItemExtension = $$$GetExtension(pItemName)
        Set tCommonItemTypes = $LISTBUILD("hl7","csp","lut")
        If '$LISTFIND(tCommonItemTypes, tItemExtension) { 
            Set pItemName = $REPLACE(pItemName,"-","/")
        }
        $$$ThrowOnError(..CreateFileName(pItemName, .tFileName))
        $$$ThrowOnError(..CreateDirectory(tFileName))
        $$$ThrowOnError(##class(Utils.CustomizedHelper).FixXMLLine(pItemName, tFileName))
        Set tSC = $$$OK
    } Catch tSE {
        Set tSC = tSE.AsStatus()
        Quit
    }
    Quit tSC
}

/// This method creates the file name and therefore it is the foundation to generate the path to set up the directory structure.
ClassMethod CreateFileName(pItemName As %String, Output oFileName As %String) As %Status
{
    #Dim tSC As %Status
    #Dim tSE As %Exception.StatusException
    #Dim tWorkingDirectory As %String
    #Dim tExtension As %String
    #Dim tDirectory As %String

    Try {
        Set tWorkingDirectory = ..#WORKINGDIRECTORY
        Set tExtension = $$$GetExtension(pItemName)
        // don't split HL7 schema files by dots
        If (tExtension '= "hl7") {
            Set tDirectory = $PIECE(pItemName, ".",1, *-2 )
            Set tDirectory = $TRANSLATE(tDirectory, ".", "/")
            Set pItemName = tDirectory_"/"_$PIECE(pItemName, ".", *-1, *)
        }
        Set oFileName = ##class(%File).NormalizeFilename(pItemName, tWorkingDirectory)
        If (tExtension = "dfi") {
            Set oFileName = $EXTRACT(oFileName,1,*-4)_".xml"
        }
        // make sure that the files are stored in the "src" directory of the project 
        If ('$FIND(oFileName, tWorkingDirectory)) {
            Set oFileName = tWorkingDirectory_oFileName
        }
        Write "Filename: ",oFileName,!
        Set tSC = $$$OK
    }
    Catch tSE {
            Set tSC = tSE.AsStatus()
            Quit
        }
    Quit tSC
}

/// This method creates the directory structure for a specific file if it it does not exist yet.
ClassMethod CreateDirectory(pFileName As %String) As %Status
{
    #Dim tSC As %Status
    #Dim tSE As %Exception.StatusException
    #Dim tPath As %String
    #Dim tPathToCreate As %String

    Try {
        Set tWorkingDirectory = ..#WORKINGDIRECTORY
        Set tPath = ##class(%File).GetDirectory(pFileName)
        If ($$$StringEndsWith(tPath, "/")) {
            Set tPath = $$$StringRemoveLast(tPath)
        }
        If '##class(%File).DirectoryExists(tPath){
            If ('$$$StringStartsWith(tPath, tWorkingDirectory)) {
                Set tPathToCreate = tWorkingDirectory_tPath
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

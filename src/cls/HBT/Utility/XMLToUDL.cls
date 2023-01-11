Include HBT.Utility

/// Description
Class HBT.Utility.XMLToUDL
{

/*
TODO Refactoring

Aufgaben:
- Methoden nach NestorIT Standard refactoren+
    - Try-Catch
    - korrekte Benamung der Parameter (tAbc; pAbc etc.)
    - Rückgabetyp %Status
    - #Dim zur Deklaration der Variablen
    - $$$ThrowOnError statt Do ##class()...


Aufrufhierarchie:
- ImportUDLFormDefault() wird aus dem Skript des entsprechende Projekts aufgerufen
- ImportUDL() bekommt den Studio Export
- FixExportFile() ersetzt zunächst die "CON" Bezeichnungen, damit die Ordner später unter Windows angelegt werden können
- Das neue File wird abgelegt
- Mit $SYSTEM.OBJ.Load() werden die Items aus dem Studio Export geladen und in einer Liste gespeichert
- Für jedes Item (z.B. eine Klasse, eine LUT etc.) wird die Methode ExportFile() aufgerufen
- Dort wird entschieden um was für einen Dateitypen es sich handelt
- Für Klassen und Routinen wird die Methode ExportClassAndRoutine aufgerufen
- Für sonstiges Dateien wird die Methode ExportCommonItemsByExtension aufgerufen

*/
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
        $$$ThrowOnError(..FixExportFile(tLocation, tFixedLocation))
        Write "Importing from location: '"_tFixedLocation,!
        Do $SYSTEM.OBJ.Load(tFixedLocation,"",.%errorlog,.tImportedItems,0,,)
        Write "Imported: ",!, tImportedItems,!,!
        Set tItemList = $LISTFROMSTRING(tImportedItems, ",")
        For i=1:1:$LISTLENGTH(tItemList) {
            Set tItemName = $LIST(tItemList,i)
            $$$ThrowOnError(..GetIgnoreStatus(tItemName, .pIgnoreItem))
            If ('pIgnoreItem) {
                Write !,"Exporting Item: ", tItemName,!
                $$$ThrowOnError(..ExportFile(tItemName, "/irisrun/udl-export"))
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

/// This method checks if a item within the studio export is part of a list of filenames that should be ignored.
/// If it is part of the list, "oIgnoreItem" will be TRUE.
/// You can add more files to "tIgnoreList" if needed.
ClassMethod GetIgnoreStatus(pItemName As %String, Output oIgnoreItem As %Boolean) As %Status
{
    #Dim tSC As %Status
    #Dim tSE As %Exception.StatusException
    #Dim tIgnoreList As List of %String
    
    Try {
        Set tIgnoreList = $LISTBUILD("dev.code.CLS",
						"dev.deepsee.CLS",
						"dev.FileManExtension.CLS",
						"dev.diff.gitHub.CLS",
						"dev.diff.gitLocal.CLS",
						"dev.diff.utils.CLS")
        Set oIgnoreItem = $LISTFIND(tIgnoreList, pItemName)
        Set tSC = $$$OK
    } Catch tSE {
        Set tSC = tSE.AsStatus()
        Quit
    }
    Quit tSC
}

ClassMethod ExportFile(pItemName As %String, pDirectory As %String) As %Status
{
    #Dim rSC As %Status
    #Dim tSE As %Exception.StatusException
    #Dim tClassAndRoutinesExtensions As List of %String
    #Dim tItemExtension As %String

    Try {
        Set tClassAndRoutinesExtensions = $LISTBUILD("cls","mac","int","inc")
        Set tItemExtension = $ZCONVERT($PIECE(pItemName,".",*), "l")
        Write "Extension: ", tItemExtension, !
        If $LISTFIND(tClassAndRoutinesExtensions, tItemExtension) {
            $$$ThrowOnError(..ExportClassAndRoutine(pItemName, pDirectory))
        } Else {
            $$$ThrowOnError(..ExportCommonItemsByExtension(tItemExtension,pItemName,pDirectory))
        }
        Set rSC = $$$OK
    } Catch tSE {
        Set rSC = tSE.AsStatus()
        Quit
    }
    Quit rSC
}

// From: https://github.com/intersystems-community/isc-dev/blob/master/src/dev/FileManExtension.cls

ClassMethod ExportClassAndRoutine(pClassName As %String, pDirectory As %String) As %Status
{
    #Dim tSC As %Status
    #Dim tSE As %Exception.StatusException
    #Dim tFileName As %String

    Try {
        // TODO Die If Abfragen kann man auch noch optimieren
        If ($$$isGenerated(pClassName)) Return $$$OK
        If ($$$isPercented(pClassName)) Return $$$OK
        If ($$$isMapped(pClassName)) Return $$$OK
        
        Set tFileName = ..filename(pClassName, pDirectory)
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
ClassMethod ExportCommonItemsByExtension(pItemExtension As %String, pItemName As %String, pDirectory As %String) As %Status
{
    #Dim tSC As %Status
    #Dim tSE As %Exception.StatusException
    #Dim tFileName As %String
    
    Try {
        If (pItemExtension = "hl7") || (pItemExtension = "csp") || (pItemExtension = "lut") {
            Set tFileName = ..filename(pItemName, pDirectory)
        } ElseIf (pItemExtension = "dfi") {
            Set tFileName = ..filename($REPLACE(pItemName,"-","/"))
            Set tFileName = $EXTRACT(tFileName,1,*-4)_".xml"
        } Else {
            Set tFileName = ..filename($REPLACE(pItemName,"-","/"), pDirectory)
        }
        Do ..MakeDirectory(tFileName)
        Do ..fixXMLLine(pItemName, tFileName)
        Set tSC = $$$OK
    } Catch tSE {
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

// From: https://github.com/intersystems-community/isc-dev/blob/master/src/dev/code.cls

ClassMethod filename(code As %String, directory As %String)
{
	Set wd = directory

	If '##class(%File).DirectoryExists( wd ) {
		Set sc = ##class(%File).CreateDirectoryChain( wd )
		$$$log(wd,sc)
	}

	Set ext = $PIECE( code, ".", * ), ext = $ZCONVERT( ext, "l" )
    Set splitFiles = ##class(%SYSTEM.Util).GetEnviron("SPLIT_FILES_IN_DIRECTORIES") = "true"
	#; for each type - different directory
	#; except cls,int,inc,mac
    #; 
    Write "Directory: ",wd,!
    If (splitFiles) {
        If ext'="cls",ext'="mac",ext'="int",ext'="inc",ext'="" Set wd = ##class(%File).NormalizeDirectory( ext, wd )
    }

	#; directory must exist before any call (%File).NormalizeFilename( , wd)
	If '##class(%File).DirectoryExists( wd ) 
	{
		Set sc = ##class(%File).CreateDirectoryChain( wd )
		$$$log(wd,sc)
	}

	Set filename = ##class(%File).NormalizeFilename( code, wd )
	#; lowercase file extension
	Set $PIECE(filename,".",*)=ext
	//B:code="DPRep.Rest.JSON.cls" "L"
	#; for *.cls Package.Subpackage.ClassName.cls -> Folder/Subfolder/ClassName.cls
    If (splitFiles) {
        If (ext="cls") || (ext="gbl") 
        {
            Set dirs = $PIECE( code, ".",1, *-2 ), dirs = $TRANSLATE( dirs, ".", "/" )
            Set relpath = dirs _ "/" _ $PIECE( code, ".", *-1, * ) ;
            Set filename = ##class(%File).NormalizeFilename( relpath, wd )
        }
    } Else {
        // Don't split hl7 by dots!
        If (ext '= "hl7") {
            Set dirs = $PIECE( code, ".",1, *-2 ), dirs = $TRANSLATE( dirs, ".", "/" )
            Set relpath = dirs _ "/" _ $PIECE( code, ".", *-1, * ) ;
            Set filename = ##class(%File).NormalizeFilename( relpath, wd )
        }
    }
    // Make sure that the files are stored in the "src" directory of the project 
    If ($FIND(filename,"irisrun/udl-export") = 0) {
        Set filename = "/irisrun/udl-export"_filename
    }
    Write "Filename: ",filename,!
	Return filename
}

ClassMethod fixXMLLine(documentName, filename) As %Status
{
    Write "FixXMLLine documentName="_documentName_" and filename="_filename,!
	Set stream = ##class(%Stream.FileBinary).%New()
	Do stream.LinkToFile(filename)
	Do $SYSTEM.OBJ.ExportToStream(documentName, .stream)

	Set matcher=##class(%Regex.Matcher).%New("<Export generator=.+>")
	Set matcher.Text = stream.Read(stream.Size)
	Set data = matcher.ReplaceFirst("<Export generator=""Cache"">")
	
	Do stream.Clear()
	Do stream.Write(data)
	Return stream.%Save()
}

/// This method replaces all occurences of the String "CON" within in the Studio export file.
/// This is necessary because it's not allowed to create folders that are named "CON" on Windows machines.
/// A pipeline command will do the opposite when the sources are transformed back into a export.xml.
ClassMethod FixExportFile(pFileIn As %String, pFileOut As %String) As %Status
{
  #Dim tSC As %Status
  #Dim tSE As %Exception.StatusException
  #Dim tFile as %File
  #Dim tOutStream as %Stream.FileCharacter

  Try {
    Write "Fixing export file",!
    Set tFile = ##class(%File).%New(pFileIn)
    Set tOutStream = ##class(%Stream.FileCharacter).%New()
    Set tOutStream.Filename = pFileOut
    $$$ThrowOnError(tFile.Open("R"))
    While 'tFile.AtEnd {
        Set tLine = tFile.ReadLine() 
        Set tFixedLine = $REPLACE(tLine, ".CON.", ".C0N.")
        $$$ThrowOnError(tOutStream.WriteLine(tFixedLine))
    }
    $$$ThrowOnError(tOutStream.Flush())
    $$$ThrowOnError(tOutStream.%Save())
    // TODO Prüfen warum $$$ThrowOnError den Fehler "Function must return a value" wirft; laut Doku wird nichts zurückgegeben 
    // $$$ThrowOnError(tFile.Close()) 
    Do tFile.Close()
    Set tSC = $$$OK
  } Catch tSE {
    Set tSC = tSE.AsStatus()
    Quit
  }
  Quit tSC
}

}

Include HBT.Utility

/// Description
Class HBT.Utility.XMLToUDL
{

// Call as zwrite ##class(HBT.Utility.XMLToUDL).ImportUDLFromDefault()

ClassMethod ImportUDLFromDefault() As %Status
{
    #Dim rSC As %Status
    #Dim tSE As %Exception.StatusException
    Try {
        $$$ThrowOnError(..ImportUDL("/irisrun/export.xml"))
        Set rSC = $$$OK
    } Catch tSE {
        Set rSC = tSE.AsStatus()
        Quit
    }
    Quit rSC
}

// Call as zwrite ##class(HBT.Utility.XMLToUDL).ImportUDL("/path/to/udl")

ClassMethod ImportUDL(pLocation As %String) As %Status
{
    #Dim rSC As %Status
    #Dim tSE As %Exception.StatusException
    #Dim tImportedItems as %String // CSV list of imported items
    Try {
        Write "Fixing export file",!
        Set tFixedLocation = "/opt/irisbuild/export-fixed.xml"
        $$$ThrowOnError(..FixExportFile(pLocation, tFixedLocation))
        Write "Importing from location = '"_tFixedLocation,!
        Do $SYSTEM.OBJ.Load(tFixedLocation,"",.%errorlog,.tImportedItems,0,,)
        Write "Imported:",!, tImportedItems,!,!
        Set tItemList = $LISTFROMSTRING(tImportedItems, ",")
        For i=1:1:$LISTLENGTH(tItemList) {
            Set tItem = $LIST(tItemList,i)
            Write !,"Exporting Item ", tItem,!
            $$$ThrowOnError(..ExportFile(tItem, "/irisrun/udl-export"))
        }
        Set rSC = $$$OK
    } Catch tSE {
        Set rSC = tSE.AsStatus()
        Quit
    }
    Quit rSC
}

ClassMethod ExportFile(className As %String, directory As %String) As %Status
{
    #Dim rSC As %Status
    #Dim tSE As %Exception.StatusException
    Try {
        Set ignorList = $LISTBUILD("dev.code.CLS",
						"dev.deepsee.CLS",
						"dev.FileManExtension.CLS",
						"dev.diff.gitHub.CLS",
						"dev.diff.gitLocal.CLS",
						"dev.diff.utils.CLS")
        Return:$LISTFIND(ignorList, className)=1 $$$OK
                            
        Set classAndRoutinesExts = $LISTBUILD("cls","mac","int","inc")
        
        Set ext = $ZCONVERT($PIECE(className,".",*), "l")
        Write "Extension:", ext, !
        
        If $LISTFIND(classAndRoutinesExts, ext)
        {
            Do ..exportClassAndRoutine($PIECE(className, ".", 1, *-1)_"."_ext, directory)
        }
        ElseIf ext = "dfi"
        {
            Set fileName = ..filename($REPLACE(className,"-","/"))
            Set fileName = $EXTRACT(fileName,1,*-4)_".xml"
            
            Do ..mkdir(fileName)
            Do ..fixXMLLine(className, fileName)
        }
        ElseIf ext = "hl7"
        {
            Set fileName = ..filename(className, directory)
            Do ..mkdir(fileName)
            Do ..fixXMLLine(className, fileName)
        }
        ElseIf ext = "csp"
        {
            Set fileName = ..filename(className, directory)
            Set fileName = "/irisrun/udl-export"_fileName
            Do ..mkdir(fileName)
            Do ..fixXMLLine(className, fileName)
        }
        ElseIf ext = "prj"
        {
            // Skip the export of studio project definitions
            Set rSC = $$$OK
        }
        Else
        {
            Set fileName = ..filename($REPLACE(className,"-","/"), directory)
            Do ..mkdir(fileName)
            Do ..fixXMLLine(className, fileName)
        }
        Set rSC = $$$OK
    } Catch tSE {
        Set rSC = tSE.AsStatus()
        Quit
    }
    Quit rSC
}

// From: https://github.com/intersystems-community/isc-dev/blob/master/src/dev/FileManExtension.cls

ClassMethod exportClassAndRoutine(className As %String, directory As %String) As %Status
{
    #Dim rSC As %Status
    #Dim tSE As %Exception.StatusException
    Try {
        #define isGenerated(%code) ##class(%RoutineMgr).IsGenerated( %code )
        #define isPercented(%code) ("%" = $e(%code))
        #define isMapped(%code) ##class(%RoutineMgr).IsMapped( %code )
        
        If ($$$isGenerated(className)) Return $$$OK
        If ($$$isPercented(className)) Return $$$OK
        If ($$$isMapped(className)) Return $$$OK
        
        Set tFilename = ..filename(className, directory)
        Write "Export data: "
        Write "File = '", tFilename, "' | "
        Write "Class = '", className, "'"
        Write !
        $$$ThrowOnError(..mkdir(tFilename))
        $$$ThrowOnError($SYSTEM.OBJ.ExportUDL(className, tFilename))
        Set rSC = $$$OK
    } Catch tSE {
        Set rSC = tSE.AsStatus()
        Quit
    }
    Quit rSC
}

ClassMethod mkdir(filename As %String) As %Status
{
	Set sc = $$$OK
	Set path = ##class(%File).GetDirectory(filename)
    If ($$$StringEndsWith(path, "/")) {
        Set path = $$$StringRemoveLast(path)
    }
	If '##class(%File).DirectoryExists(path) 
	{
        If ('$$$StringStartsWith(path, "/irisrun/udl-export")) {
            Set toCreate = "/irisrun/udl-export"_path
        } Else {
            Set toCreate = path
        }
      
        Write !, "Directory does not exist. Creating: "_toCreate, ! 
	    Set tResult = ##class(%File).CreateDirectoryChain(toCreate, .tReturn)
        Write "Directory create status: ", tResult, !
        If ('tResult) {
            ZWrite tReturn
        }
	}
	Return sc
}

// From: https://github.com/intersystems-community/isc-dev/blob/master/src/dev/code.cls

ClassMethod filename(code As %String, directory As %String)
{
	#define log(%dir,%sc) w "mkdir ", %dir, " ", sc, !

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

ClassMethod FixExportFile(tFileIn As %String, tFileOut As %String) As %Status
{
  #Dim rSC As %Status
  #Dim tSE As %Exception.StatusException
  Try {
    #dim tFile as %File
    #dim tOutStream as %Stream.FileCharacter
    Set tFile = ##class(%File).%New(tFileIn)
    Set tOutStream = ##class(%Stream.FileCharacter).%New()
    Set tOutStream.Filename = tFileOut
    $$$ThrowOnError(tFile.Open("R"))
    While 'tFile.AtEnd {
        Set tLine = tFile.ReadLine() 
        Set tFixedLine = $REPLACE(tLine, ".CON.", ".C0N.")
        $$$ThrowOnError(tOutStream.WriteLine(tFixedLine))
    }
    Do tOutStream.Flush()
    Do tOutStream.%Save()
    Do tFile.Close()
    Set rSC = $$$OK
  } Catch tSE {
    Set rSC = tSE.AsStatus()
    Quit
  }
  Quit rSC
}

}

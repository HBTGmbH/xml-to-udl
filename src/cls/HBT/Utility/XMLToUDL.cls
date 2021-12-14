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
        write "Importing from location = '"_pLocation,!
        do $System.OBJ.Load(pLocation,"",.%errorlog,.tImportedItems,0,,)
        write "Imported:",!, tImportedItems,!,!
        set tItemList = $listFromString(tImportedItems, ",")
        for i=1:1:$LISTLENGTH(tItemList) {
            set tItem = $LIST(tItemList,i)
            write !,"Exporting Item", tItem,!
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
        set ignorList = $lb("dev.code.CLS",
						"dev.deepsee.CLS",
						"dev.FileManExtension.CLS",
						"dev.diff.gitHub.CLS",
						"dev.diff.gitLocal.CLS",
						"dev.diff.utils.CLS")
        return:$lf(ignorList, className)=1 $$$OK
                            
        set classAndRoutinesExts = $lb("cls","mac","int","inc")
        
        set ext = $zcvt($p(className,".",*), "l")
        write "Extension:", ext, !
        
        if $lf(classAndRoutinesExts, ext)
        {
            do ..exportClassAndRoutine($p(className, ".", 1, *-1)_"."_ext, directory)
        }
        elseif ext = "dfi"
        {
            set fileName = ..filename($replace(className,"-","/"))
            set fileName = $extract(fileName,1,*-4)_".xml"
            
            do ..mkdir(fileName)
            do ..fixXMLLine(className, fileName)
        }
        elseif ext = "hl7"
        {
            set fileName = ..filename(className, directory)
            do ..mkdir(fileName)
            do ..fixXMLLine(className, fileName)
        }
        elseif ext = "csp"
        {
            set fileName = ..filename(className, directory)
            set fileName = "/irisrun/udl-export"_fileName
            do ..mkdir(fileName)
            do ..fixXMLLine(className, fileName)
        }
        else
        {
            set fileName = ..filename($replace(className,"-","/"), directory)
            do ..mkdir(fileName)
            do ..fixXMLLine(className, fileName)
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
        
        if ($$$isGenerated(className)) return $$$OK
        if ($$$isPercented(className)) return $$$OK
        if ($$$isMapped(className)) return $$$OK
        
        set tFilename = ..filename(className, directory)
        write "Export data: "
        write "File = '", tFilename, "' | "
        write "Class = '", className, "'"
        write !
        $$$ThrowOnError(..mkdir(tFilename))
        $$$ThrowOnError($system.OBJ.ExportUDL(className, tFilename))
        Set rSC = $$$OK
    } Catch tSE {
        Set rSC = tSE.AsStatus()
        Quit
    }
    Quit rSC
}

ClassMethod mkdir(filename As %String) As %Status
{
	set sc = $$$OK
	set path = ##class(%File).GetDirectory(filename)
    if ($$$StringEndsWith(path, "/")) {
        set path = $$$StringRemoveLast(path)
    }
	if '##class(%File).DirectoryExists(path) 
	{
        if ('$$$StringStartsWith(path, "/irisrun/udl-export")) {
            set toCreate = "/irisrun/udl-export"_path
        } else {
            set toCreate = path
        }
      
        write !, "Directory does not exist. Creating: "_toCreate, ! 
	    set tResult = ##class(%File).CreateDirectoryChain(toCreate, .tReturn)
        write "Directory create status: ", tResult, !
        if ('tResult) {
            zwrite tReturn
        }
	}
	return sc
}

// From: https://github.com/intersystems-community/isc-dev/blob/master/src/dev/code.cls

ClassMethod filename(code As %String, directory As %String)
{
	#define log(%dir,%sc) w "mkdir ", %dir, " ", sc, !

	set wd = directory

	if '##class(%File).DirectoryExists( wd ) {
		set sc = ##class(%File).CreateDirectoryChain( wd )
		$$$log(wd,sc)
	}

	set ext = $p( code, ".", * ), ext = $zcvt( ext, "l" )
    set splitFiles = ##class(%SYSTEM.Util).GetEnviron("SPLIT_FILES_IN_DIRECTORIES") = "true"
	#; for each type - different directory
	#; except cls,int,inc,mac
    if (splitFiles) {
        if ext'="cls",ext'="mac",ext'="int",ext'="inc",ext'="" set wd = ##class(%File).NormalizeDirectory( ext, wd )
    }

	#; directory must exist before any call (%File).NormalizeFilename( , wd)
	if '##class(%File).DirectoryExists( wd ) 
	{
		set sc = ##class(%File).CreateDirectoryChain( wd )
		$$$log(wd,sc)
	}

	set filename = ##class(%File).NormalizeFilename( code, wd )
	#; lowercase file extension
	set $p(filename,".",*)=ext
	//B:code="DPRep.Rest.JSON.cls" "L"
	#; for *.cls Package.Subpackage.ClassName.cls -> Folder/Subfolder/ClassName.cls
    if (splitFiles) {
        if (ext="cls") || (ext="gbl") 
        {
            set dirs = $piece( code, ".",1, *-2 ), dirs = $translate( dirs, ".", "/" )
            set relpath = dirs _ "/" _ $piece( code, ".", *-1, * ) ;
            set filename = ##class(%File).NormalizeFilename( relpath, wd )
        }
    } else {
        // Don't split hl7 by dots!
        if (ext '= "hl7") {
            set dirs = $piece( code, ".",1, *-2 ), dirs = $translate( dirs, ".", "/" )
            set relpath = dirs _ "/" _ $piece( code, ".", *-1, * ) ;
            set filename = ##class(%File).NormalizeFilename( relpath, wd )
        }

    }
	

	return filename
}

ClassMethod fixXMLLine(documentName, filename) As %Status
{
    write "FixXMLLine documentName="_documentName_" and filename="_filename,!
	set stream = ##class(%Stream.FileBinary).%New()
	do stream.LinkToFile(filename)
	do $system.OBJ.ExportToStream(documentName, .stream)

	set matcher=##class(%Regex.Matcher).%New("<Export generator=.+>")
	set matcher.Text = stream.Read(stream.Size)
	set data = matcher.ReplaceFirst("<Export generator=""Cache"">")
	
	do stream.Clear()
	do stream.Write(data)
	return stream.%Save()
}

}

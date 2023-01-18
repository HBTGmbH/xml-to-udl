Include Utils.HBTLib

Class Utils.CustomizedHelper
{

/// This method replaces all occurences of the String "CON" in item names within in the Studio export file.
/// This is necessary because it's not allowed to create folders that are named "CON" on Windows machines.
/// A pipeline command is needed to do the opposite when the sources are transformed back into a export.xml.
ClassMethod FixExportFile(pFileIn As %String, pFileOut As %String) As %Status
{
  #Dim tSC As %Status
  #Dim tSE As %Exception.StatusException
  #Dim tFile as %File
  #Dim tOutStream as %Stream.FileCharacter

  Try {
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
    Do tFile.Close()
    Set tSC = $$$OK
  } Catch tSE {
    Set tSC = tSE.AsStatus()
    Quit
  }
  Quit tSC
}

/// This method replaces a tag in the XML body (for example in .lut and .hl7) to assure downward compatibility from IRIS to Caché.
ClassMethod FixXMLLine(pDocumentName As %String, pFileName As %String) As %Status
{
    #Dim tSC As %Status
    #Dim tSE As %Exception.StatusException
    #Dim tFileStream As %Stream.FileBinary
    #Dim tRegExMatcher As %Regex.Matcher
    #Dim tData As %String

    Try {
	    Set tFileStream = ##class(%Stream.FileBinary).%New()
        $$$ThrowOnError(tFileStream.LinkToFile(pFileName))
        $$$ThrowOnError($SYSTEM.OBJ.ExportToStream(pDocumentName, .tFileStream))
        Set tRegExMatcher = ##class(%Regex.Matcher).%New("<Export generator=.+>")
	    Set tRegExMatcher.Text = tFileStream.Read(tFileStream.Size)
	    Set tData = tRegExMatcher.ReplaceFirst("<Export generator=""Cache"">")
        $$$ThrowOnError(tFileStream.Write(tData))
        $$$ThrowOnError(tFileStream.%Save())
        Set tSC = $$$OK
    } Catch tSE {
        Set tSC = tSE.AsStatus()
        Quit
    }
    Quit tSC
}

/// This method checks if a item within the studio export is part of a list of file names that should be ignored.
/// If it is part of the list, "oIgnoreItem" will be set to TRUE.
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

/// This method checks if a class is generated, is a %class or mapped. If yes, "oSkipItem" will be set to TRUE. 
ClassMethod GetClassStatus(pItemName As %String, Output oSkipItem As %Boolean) As %Status
{
    #Dim tSC As %Status
    #Dim tSE As %Exception.StatusException
    
    Try {
        If ($$$isGenerated(pItemName)) || ($$$isPercented(pItemName)) || ($$$isMapped(pItemName)) {
            Set oSkipItem = 1
        } Else {
            Set oSkipItem = 0
        }
        Set tSC = $$$OK
    } Catch tSE {
        Set tSC = tSE.AsStatus()
        Quit
    }
    Quit tSC
}

}

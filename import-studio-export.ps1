# Run this script to import the current studio export as UDL into "src"

$pwd = Get-Location | Foreach-Object { $_.Path }
if ($PSScriptRoot -eq $pwd) {
    cd ..
}

& docker build -t xmltoudl xml-to-udl/
if ($LastExitCode -ne 0) {
    throw "Could not build docker imgae for studio-export import"
}

& docker run --rm -v "${pwd}/studio-export.xml:/irisrun/export.xml" -v "${pwd}/src:/irisrun/udl-export"  xmltoudl
if ($LastExitCode -ne 0) {
    throw "studio-export import failed"
}

#!/bin/bash
##  This is a helper script for importing a studio-export-xml-file (via the xml-to-udl tool) on linux.
##  
##  Usage: import-studio-export.sh [-d,--delete] -x,--xml-file /abs/path/to/export.xml -s,--source-folder /abs/path/to/source-folder [-i,--image tag-of-converter-image]
##
##  Background:
##  The need for such a script is that on linux the local file permission and ownership are passed to the docker volume and
##  since the xml-to-udl container runs as non-root user it lacks the necessary permissions to write to the source directory.
##  This script provides the necessary permission and ownership for the source directory before the container is started.
##  But after the conversion is done the files in the source directory have different permissions and ownership that before and 
##  thus git considers every file as modified. To prevent this, the script undoes the changes to ownership and permissions.
##


# default parameters
IRIS_OWNER_ID=51773
XML_FILE=""
SOURCE_DIR=""
XML_TO_UDL_IMAGE="ghcr.io/hbtgmbh/xml-to-udl/converter:latest"
DELETE_EXTRANEOUS_FILES=false

# get script arguments
ARGS=$(getopt -o 'dx:s:i' --long 'delete,xml-file:,source-folder:,image::' -- "$@") || exit
eval "set -- $ARGS"

# handle script arguments
while true; do
    case $1 in
        # handle xml file argument
        (-x|--xml-file)
            XML_FILE=$2; shift 2;;
        # handle source folder argument
        (-s|--source-folder)
            SOURCE_DIR=$2; shift 2;;
        # handle docker image of converter argument
        (-i|--image)
            XML_TO_UDL_IMAGE=$2; shift 2;;
        # handle delete flag
        (-d|--delete)
            DELETE_EXTRANEOUS_FILES=true; shift;;
        (--)
            shift; break;;
        # any other arg
        (*)
            exit 1;;    # return with error
    esac
done

check_for_abspath_to_dir () {
    local argument_designator=$1
    local path=$2
    case $path in
        (/*)
            # check if path is an actual directory or file
            if [[ ! -d "$path" && ! -f "$path" ]]; then
                echo "The provided $argument_designator is not an actual path: $path" >&2
                exit 1
            fi;;
        (*)
            echo -e "Please provide an absolute path to the $argument_designator." >&2
            exit 1;;
    esac
}

# check for path to xml-file
if [[ ! $XML_FILE ]]; then
    echo -e "Argument -x,--xml-file is missing. Please provide a path to a studio export file." >&2
    exit 1
else
    check_for_abspath_to_dir "studio export file" $XML_FILE
fi

# check for source folder path
if [[ ! $SOURCE_DIR ]]; then
    echo -e "Argument -s,--source-folder is missing. Please provide a path to a source directory." >&2
    exit 1
else
    check_for_abspath_to_dir "source folder" $SOURCE_DIR
fi

# store current owner of source directory
USER=`ls -ld $SOURCE_DIR | awk '{print $3}'`
GROUP=`ls -ld $SOURCE_DIR | awk '{print $4}'`

# delete all content of source dir
if [ "$DELETE_EXTRANEOUS_FILES" = true ]; then
    echo "[STEP] Remove all sources."
    sudo rm -rf src/*
fi

# change owner of source folder to iris owner
echo "[STEP] Prepare source folder with necessary ownership."
sudo chown -R $IRIS_OWNER_ID $SOURCE_DIR

# run xml-to-udl converter
echo "[STEP] Start converter container image $XML_TO_UDL_IMAGE."
docker run -v "$XML_FILE:/irisrun/export.xml" -v "$SOURCE_DIR/:/irisrun/udl-export" --rm --name xml-to-udl $XML_TO_UDL_IMAGE

# change owner of source folder back to original owner
echo "[STEP] Change owner of source files back to $USER:$GROUP."
sudo chown -R $USER:$GROUP $SOURCE_DIR

# replace files with uppercase extension .HL7 oder .INC with lower case extension (only for compatibilty reasons)
# echo "[STEP] Replacing files extensions HL7 or INC with lowercase extension."
find $SOURCE_DIR \( -name '*.HL7' -o -name '*.INC' \) -type f -exec sh -c \
    'a=$(echo "$0" | sed -r "s/([^.]*)\$/\L\1/"); [ "$a" != "$0" ] && mv -v -- "$0" "$a"' {} \;

# create reverting patch for permission mode changes
echo "[STEP] Create patch for reverting permission changes."
REVERTING_PERMISSION_PATCH="$(git diff -p -R --no-ext-diff --no-color | \
    # include only diff's and permission mode changes
    grep -E "^(diff|(old|new) mode)" --color=never | \
    # ignore diff's where no permission mode was changed:
    awk '{if ($0 !~ /^diff/ || (NR>1 && prev !~ /^diff/ )) print prev; prev=$0} END {if ($0 !~ /^diff/ || (NR>1 && prev !~ /^diff/ )) print prev}' )"
# check if patch is empty
if [ -z "$REVERTING_PERMISSION_PATCH" ]; then
    echo -e "Nothing to patch."
else
    echo -e "Patch:\n$REVERTING_PERMISSION_PATCH"

    # reverting permissions
    echo "[STEP] Applying patch."
    git apply <<< $REVERTING_PERMISSION_PATCH
fi

echo -e "\nImport done!"
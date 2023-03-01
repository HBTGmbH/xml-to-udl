#!/bin/bash
# This is a helper script for importing a studio-export-xml-file (via the xml-to-udl tool) on linux.
# 
# The need for such a script is taht on linux the local file permission and ownership are passed to the docker volume and
# since the xml-to-udl container runs as non-root user it lacks the necessary permissions to write to the source directory.
# This script provides the necessary permission and ownership for the source directory before the container is started.
# But after the conversion is done the files in the source directory have different permissions and ownership that before and 
# thus git considers every file as modified. To prevent this, the script undoes the changes to ownership and permissions.

# TODO: parameterize script (https://www.baeldung.com/linux/use-command-line-arguments-in-bash-script#flags)

IRIS_OWNER_ID=51773
EXPORT_FILE="$(pwd)/studio-export.xml"
SOURCE_DIR="$(pwd)/src"
XML_TO_UDL_IMAGE="ghcr.io/hbtgmbh/xml-to-udl/converter:latest"

# store current owner of source directory
USER=`ls -ld $SOURCE_DIR | awk '{print $3}'`
GROUP=`ls -ld $SOURCE_DIR | awk '{print $4}'`

# delete all content of source dir
echo "[STEP] Remove all sources."
sudo rm -rf src/*

# change owner of source folder to iris owner
echo "[STEP] Prepare source folder with necessary ownership."
sudo chown $IRIS_OWNER_ID $SOURCE_DIR

# run xml-to-udl converter
echo "[STEP] Start converter container image $XML_TO_UDL_IMAGE."
docker run -v "$EXPORT_FILE:/irisrun/export.xml" -v "$SOURCE_DIR/:/irisrun/udl-export" --rm --name xml-to-udl $XML_TO_UDL_IMAGE

# change owner of source folder back to original owner
echo "[STEP] Change owner of source files back to $USER:$GROUP."
sudo chown -R $USER:$GROUP $SOURCE_DIR

# TODO: compare the case handling of extensions of the converter on windows and linux
# replace files with uppercase extension .HL7 oder .INC with lower case extension (only for compatibilty reasons)
echo "[STEP] Replacing files extensions HL7 or INC with lowercase extension."
find $SOURCE_DIR \( -name '*.HL7' -o -name '*.INC' \) -type f -exec sh -c \
    'a=$(echo "$0" | sed -r "s/([^.]*)\$/\L\1/"); [ "$a" != "$0" ] && mv -v -- "$0" "$a"' {} \;

# create reverting patch for permission mode changes
echo "[STEP] Create patch for reverting permission changes."
REVERTING_PERMISSION_PATCH="$(git diff -p -R --no-ext-diff --no-color | \
    # include only diff's and permission mode changes
    grep -E "^(diff|(old|new) mode)" --color=never | \
    # ignore diff's where no permission mode was changed:
    awk '{if ($0 !~ /^diff/ || (NR>1 && prev !~ /^diff/ )) print prev; prev=$0} END {if ($0 !~ /^diff/ || (NR>1 && prev !~ /^diff/ )) print prev}')"
echo "Patch:\n$REVERTING_PERMISSION_PATCH"

# reverting permissions
echo "[STEP] Applying patch."
git apply <<< $REVERTING_PERMISSION_PATCH

echo -e "\nImport done!"
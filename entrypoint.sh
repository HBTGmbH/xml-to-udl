#!/bin/bash
/iris-main -a /opt/irisbuild/do-conversion.sh -l /usr/irissys/mgr/messages.log --check-caps false --ISCAgent false
echo "[INFO] Stop container..."
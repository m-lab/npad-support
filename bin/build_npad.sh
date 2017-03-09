#!/bin/bash

REPO=${1:?Please provide full github repository slug}
BRANCH=${2:?Please provide repository branch or tag}
cd ~/builder
~/builder/build_one.sh https://github.com/$REPO $BRANCH iupui_npad

# When this exits, the rpm should be available under slicebase-i386/i686


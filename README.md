# npad-support [![Test Status](https://travis-ci.org/m-lab/npad-support.svg?branch=master)](https://travis-ci.org/m-lab/npad-support.svg?branch=master) [![Coverage Status](https://coveralls.io/repos/github/m-lab/npad-support/badge.svg?branch=master)](https://coveralls.io/github/m-lab/npad-support?branch=master)
============

Support scripts for NPAD on M-Lab

## Travis built rpms
This repository is now configured with travis-ci integration through
it's .travis.yml file.  For any fork with travis enabled, pushes and
pull-requests trigger building the rpm on travis.

Pushes with successful builds will also trigger writing of the rpm to
google cloud storage at gs://legacy-rpms-mlab-sandbox.  See travis file
for details about which folder the rpm is pushed to.

## Legacy build
In the past, this package was built using an mlab-builder machine, using
the following commands:

    git clone --recursive https://github.com/m-lab-tools/npad-support.git
    cd npad-support
    git checkout <tag>
    ./package/slicebuild.sh npad


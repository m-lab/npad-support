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

## Possible new deployment process
With the build automation, rpm builds should be almost reproducible, with
exceptions for embedded dates, and possible library upgrades.

This opens the possibility of rebuilding the rpms between some of the 
verification steps.  With the current travis deployment rules, we could,
for example:
* Developer does basic testing on rpm pushed to 'private' folder.
* When PR merged with master, auto-deploy rpm from 'master' folder to
  test sites and verify correct behavior.
* On success deploy to test sites, tag the commit with a deployment tag,
  triggering new rpm pushed to 'staging'.  Auto-push new rpm to test-bed.
  If test-bed testing is successful, and test site monitoring is green,
  then auto-push to canary sites.  Copy rpm to canary folder.
* After successful monitoring on canary sites, manually promote the same
  rpm from canary folder to production folder, triggering full deployment
  to all sites.

## Legacy build
In the past, this package has been built using an mlab-builder machine,
using the following commands:

    git clone --recursive https://github.com/m-lab-tools/npad-support.git
    cd npad-support
    git checkout <tag>
    ./package/slicebuild.sh npad


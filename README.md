# npad-support [![Test Status](https://travis-ci.org/m-lab/npad-support.svg?branch=master)](https://travis-ci.org/m-lab/npad-support.svg?branch=master) [![Coverage Status](https://coveralls.io/repos/github/m-lab/npad-support/badge.svg?branch=master)](https://coveralls.io/github/m-lab/npad-support?branch=master)
============

Support scripts for NPAD on M-Lab

## Travis built rpms
This repository is now configured with travis-ci integration through
it's .travis.yml file.  For any fork with travis enabled, pushes and
pull-requests trigger building the rpm on travis.

Pushes with successful builds will also trigger writing of the rpm to
google cloud storage at gs://legacy-rpms-mlab-{sandbox, staging}.
See travis file for details about which folder the rpm is pushed to.

## Possible new deployment process
With the build automation, rpm builds should be almost reproducible, with
exceptions for embedded dates, and possible library upgrades.

This opens the possibility of rebuilding the rpms between some of the
verification steps.  With the slightly modified travis deployment rules,
we could, for example:
* Developer uses a private fork, or commits to a sandbox-* branch.   RPM
  is pushed to 'private' folder, and developer can test prior to review.
* When PR is merged into upstream 'dev' branch, travis will
  automatically write a new rpm into a testing folder.  From there it
  should be loaded onto the test-bed for initial testing.
* On successful testing, the same commit will be tagged, triggering
  rebuilding of the rpm, and writing to the staging project.  From there
  it will be used to canary the package on staging machines.
* On successful canary, the rpm should be PROMOTED to the production rpm
  repository, and the production machines triggered to install it.  The
  rpm is copied rather than rebuilt to ensure that we are deploying the
  same code that passed the canary tests.  At the same time, the 'dev'
  branch is merged into the master branch.  Since the tag is associated
  with the git hash, master HEAD is now associated with the tag as well.

## Legacy build
In the past, this package has been built using an mlab-builder machine,
using the following commands:

    git clone --recursive https://github.com/m-lab-tools/npad-support.git
    cd npad-support
    git checkout <tag>
    ./package/slicebuild.sh npad


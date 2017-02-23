#!/bin/bash
set -x
set -e

KEYFILE=${1:?Please provide the service account key file}

# Add gcloud to PATH.
source "${HOME}/google-cloud-sdk/path.bash.inc"


# All operations are performed as the service account named in KEYFILE.
# For all options see:
# https://cloud.google.com/sdk/gcloud/reference/auth/activate-service-account
gcloud auth activate-service-account --key-file "${KEYFILE}"

# For this to succeed, the provided keyfile must provide W access to the
# legacy-rpms-mlab-sandbox bucket.  This is arranged by executing this from
# a privileged account:
# gsutil acl ch -u legacy-rpm-writer@mlab-sandbox.iam.gserviceaccount.com:W \
#  gs://legacy-rpms-mlab-sandbox
gsutil cp slicebase-i386/i686/*.rpm gs://legacy-rpms-mlab-sandbox/new

exit 0

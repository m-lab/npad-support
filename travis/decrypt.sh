#!/bin/bash
# This script decrypts the service accounts required for writing
# to GCS.
#
# RECOVERING IF ENCRYPTION KEYS ARE OVERWRITTEN.
# Encryption keys may be overwritten if someone invokes encrypt-file
# from the same directory that the existing keys were generated from.
#
# In the event that the encryption keys are lost, there are a few
# steps that have to be taken to restore functionality.
#  1. If the SA keys are available, skip to step 4.
#  2. Create new service accounts for mlab-sandbox and mlab-staging,
#     downloading the key files during creation.
#  3. Update the ACLs, e.g.
#     gsutil acl ch -R -u \
#       legacy-rpm-writer@mlab-sandbox.iam.gserviceaccount.com:W \
#       gs://legacy-rpms-mlab-sandbox
#  4. Tar the SA keys:
#     tar cf service-accounts.tar legacy-rpm-writer.mlab*
#  5. Encrypt the tar file:
#     travis encrypt-file -f -p service-accounts.tar \
#       --repo m-lab/ndt-support
#     Optionally, if you want to provide the keys to some other,
#     copy the key and iv values into a command like:
#     travis encrypt-file -f -p service-accounts.tar --key \
#       AAA151324478927bbbbbbbbbcccccccccccccdddddddddd53223551235324324 \
#       --iv 632451671306d1842843a792250ce707 --repo gfr10598/ndt-support
#  6. Copy the keys printed when you encrypted the tar file,
#     and paste them in place of the three occurances in the script
#     commands below.
#  7. Copy the encrypted tar file to the travis directory (where
#     this script is located).
#  8. Commit to an appropriate branch, generate PR, and send for review.

set -x
set -e
if [[ -n "$encrypted_9bceeca3f3aa_iv" ]] ; then
  openssl aes-256-cbc -d \
    -K $encrypted_9bceeca3f3aa_key -iv $encrypted_9bceeca3f3aa_iv \
    -in $TRAVIS_BUILD_DIR/travis/service-accounts.tar.enc \
    -out /tmp/service-accounts.tar
  tar -C /tmp -xvf /tmp/service-accounts.tar ;
fi


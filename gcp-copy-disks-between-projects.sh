#!/bin/bash

set -e
set -x

# Setup your projets and zones
SRC_PRJ="--project company-staging"
SRC_ZONE="--zone northamerica-northeast1-b"
DST_PRJ="--project company-production"
DST_ZONE="--zone us-central1-b"


red=$(tput setaf 1)
grn=$(tput setaf 2)
rst=$(tput sgr0)
suffix=$(date +%Y%m%d-%H%M)
time="/bin/time -f ${grn}Elapsed${rst}: %E"

DISKS="$@"
if [ -z "${DISKS}" ]; then
  echo "Usage $0 disk1 disk2 ..."; exit 1
fi

for disk in ${DISKS?}; do
  echo "Copying from ${grn}${SRC_PRJ?}/${SRC_ZONE?}${rst} to ${grn}${DST_PRJ?}/${DST_ZONE?}${rst}"
  snap="${disk}-${suffix}"
  # SRC Project
  $time gcloud ${SRC_PRJ} compute disks     snapshot  ${disk} --snapshot-names=${snap} ${SRC_ZONE}
  $time gcloud ${SRC_PRJ} compute images    create    ${snap} --source-snapshot=${snap}

  # Create image
  #$time gcloud ${DST_PRJ} compute images    create    ${disk} --image ${snap} --image-project ${SRC_PRJ}
  # OR disk
  $time gcloud ${DST_PRJ} compute disks     create    ${disk} --image ${snap} --image-project ${SRC_PRJ}

  # cleanup
  $time gcloud ${SRC_PRJ} compute images    delete    --quiet ${snap}
  $time gcloud ${SRC_PRJ} compute snapshots delete    --quiet ${snap}
done


exit 0

# OR via export/import (slower)
#BUCKET="company-migration"
#VPC="company-staging-vpc"
#SUBNET="company-staging-vpc-subnet" # you need set VPC and subnet if no "default" VPC exists
#for disk in ${DISKS?}; do
#  echo "Copying from ${grn}${SRC_PRJ?}/${SRC_ZONE?}${rst} to ${grn}${DST_PRJ?}/${DST_ZONE?}${rst}"
#  snap="${disk}-${suffix}"
#  # SRC Project
#  $time gcloud ${SRC_PRJ} compute disks   snapshot  ${disk} --snapshot-names=${snap} ${SRC_ZONE}
#  $time gcloud ${SRC_PRJ} compute images  create    ${snap} --source-snapshot=${snap}
#  $time gcloud ${SRC_PRJ} compute images  export --image=${snap} --destination-uri=gs://${BUCKET?}/${disk}.tar.gz  --network=${VPC} --subnet=${SUBNET}
#  $time gcloud ${SRC_PRJ} compute images  delete    ${snap}
#
#  # DST Project
#  $time gcloud ${DST_PRJ} compute images  create ${snap} --source-uri=gs://${BUCKET}/${disk}.tar.gz #--network=main --subnet=c1-main
#  $time gcloud ${DST_PRJ} compute disks   create ${disk} --image=${snap}  ${DST_ZONE}
#done


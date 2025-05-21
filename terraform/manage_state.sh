#!/bin/bash

# from variables.tf charged terraform.tfvars
PROJECT_ID=$(grep 'project_id' terraform.tfvars | awk -F\" '{print $2}')
REGION=$(grep 'region' terraform.tfvars | awk -F\" '{print $2}')
BUCKET_NAME=$(grep 'bucket_name' terraform.tfvars | awk -F\" '{print $2}')

# Verify if gsutil is install
if ! command -v gsutil &> /dev/null
then
    echo "gsutil doesn't install. Install it with gcloud SDK."
    exit 1
fi

# create the bucket
echo "creation of the bucket : $BUCKET_NAME"
gsutil mb -p "$PROJECT_ID" -l "$REGION" gs://"$BUCKET_NAME"/

# show succefull messsage
if [ $? -eq 0 ]; then
    echo "successfull Bucket GCS created: gs://$BUCKET_NAME/"
else
    echo "an error occur when creating the bucket"
fi

#!/usr/bin/python
# This code is just an example and has been written to be run in production

import boto3
import logging
from datetime import date, datetime
from time import sleep
from botocore.exceptions import ClientError
from flask import Flask
from flask_restplus import Api, Resource
import os
import sys

YOUR_PRODUCT_CODE = "9t18jw267f6pjyeicgxtun5jb"
DEFAULT_REGION = "eu-central-1"
REGION = os.environ.get("AWS_REGION", DEFAULT_REGION)

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

h1 = logging.StreamHandler(sys.stdout)
h1.setLevel(logging.DEBUG)

logger.addHandler(h1)

def meter_usage ():
    client = boto3.client('meteringmarketplace',  region_name=REGION)
    error = ""
    utc_now = datetime.utcnow()
    try:
        response = client.meter_usage(
            ProductCode=YOUR_PRODUCT_CODE,
            Timestamp=utc_now,
            UsageDimension='1gb', 
            UsageQuantity=5
            )
        status_code = response["ResponseMetadata"]["HTTPStatusCode"]
        if (status_code == 200):
            logger.info ("I reached the MP API")
            logger.info (response)
        else:
            error = f"I got an error: {response}"
    except ClientError as e:
        error=f"I got an exception MP exception: {e}"
    except Exception as e:
        error=f"I got an exception: {e}"

    logger.error (error)

logger.info ("starting")
while (True):
    meter_usage()
    sleep(1)


"""S3 ObjectCreated -> Rekognition DetectModerationLabels -> SQS.

One message per uploaded image, so consumers never have to call Rekognition
themselves. Failures raise, which sends the event to the Lambda's DLQ instead
of silently dropping it.
"""

import json
import os
import urllib.parse

import boto3

rekognition = boto3.client("rekognition")
sqs = boto3.client("sqs")

QUEUE_URL = os.environ["RESULTS_QUEUE_URL"]
MIN_CONFIDENCE = float(os.environ.get("MIN_CONFIDENCE", "60"))


def handler(event, _context):
    for record in event.get("Records", []):
        bucket = record["s3"]["bucket"]["name"]
        key = urllib.parse.unquote_plus(record["s3"]["object"]["key"])

        result = rekognition.detect_moderation_labels(
            Image={"S3Object": {"Bucket": bucket, "Name": key}},
            MinConfidence=MIN_CONFIDENCE,
        )
        labels = [
            {
                "name": label["Name"],
                "parent": label.get("ParentName") or None,
                "confidence": round(label["Confidence"], 2),
            }
            for label in result.get("ModerationLabels", [])
        ]

        sqs.send_message(
            QueueUrl=QUEUE_URL,
            MessageBody=json.dumps(
                {
                    "bucket": bucket,
                    "key": key,
                    "flagged": bool(labels),
                    "labels": labels,
                    "modelVersion": result.get("ModerationModelVersion"),
                }
            ),
        )

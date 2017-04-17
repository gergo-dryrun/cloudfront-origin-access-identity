import os
import uuid

import boto3
import cfn_resource
from retrying import retry


handler = cfn_resource.Resource()


@retry(wait_exponential_multiplier=1000,
       wait_exponential_max=10000)
def create_oai():
    client = boto3.client('cloudfront')
    response = client.create_cloud_front_origin_access_identity(
        CloudFrontOriginAccessIdentityConfig={
            'CallerReference': str(uuid.uuid4()),
            'Comment': 'New identity for cloudfront %s' % os.environ['STACK_NAME']
        }
    )
    oai = response['CloudFrontOriginAccessIdentity']
    return oai


@handler.create
def create_resource(event, context):
    try:
        oai = create_oai()
        print("Origin Access Identity ID: %s" % oai['Id'])
        print("Origin Access Identity S3CanonicalUserId: %s" % oai['S3CanonicalUserId'])

        return {'Status': 'SUCCESS',
                'Reason': 'Origin Access Identity Created',
                'PhysicalResourceId': oai['Id'],
                'Data': {'oai_s3_user_id': oai['S3CanonicalUserId'],
                          'id': oai['Id']}
                }
    except Exception as e:
        return {'Status': 'FAILED',
                'Reason': str(e),
                'PhysicalResourceId': 'dummy_resource_id',
                'Data': {}
                }

@handler.update
def update_resource(event, context):
    return {'Status': 'SUCCESS',
            'Reason': 'Nothing to do',
            'Data': {}
            }


@retry(wait_exponential_multiplier=1000,
       wait_exponential_max=10000)
def delete_oai(oai_id):
    client = boto3.client('cloudfront')
    etag = client.get_cloud_front_origin_access_identity(Id=oai_id)['ETag']
    client.delete_cloud_front_origin_access_identity(Id=oai_id, IfMatch=etag)


@handler.delete
def delete_resource(event, context):
    try:
        oai_id = event['PhysicalResourceId']
        delete_oai(oai_id)
        return {'Status': 'SUCCESS',
                'Reason': 'Sucessfully deleted OAI',
                'Data': {}
                }
    except Exception as e:
        return {'Status': 'FAILED',
                'Reason': str(e),
                'Data': {}
                }


if __name__ == '__main__':
    create_resource(None, None)

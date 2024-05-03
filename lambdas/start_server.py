import boto3

def lambda_handler(event, context):
    session = boto3.Session()
    try:
        ec2 = session.client('ec2')
        described_instances = ec2.describe_instances(Filters=[
                {
                    'Name': 'tag:Name',
                    'Values': [
                        'conan-server',
                    ]
                },
            ])
        instance_id = described_instances['Reservations'][0]['Instances'][0]['InstanceId']
        instance = session.resource('ec2').Instance(instance_id)
        instance.start()
        instance.wait_until_running()
        return {"message": "Instance is running"}
    except Exception as e:
        print(e)
        raise ValueError("Error :(")
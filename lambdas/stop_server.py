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
        if instance.state['Name'] == 'stopped':
            return {"message": "Instance is already stopped"}
        elif instance.state['Name'] == 'running':
            instance.stop()
            instance.wait_until_stopped()
            return {"message": "Instance is stopped"}
        else:
            return ValueError("Unexpected instance state")
    except Exception as e:
        print(e)
        raise ValueError("Error :(")
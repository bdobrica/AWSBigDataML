from pathlib import Path
import boto3
import json
import configparser
import os

def create_profile():
    """
    Creates a profile in ~/.aws/profiles. The profile is needed to login to AWS
    as the credentials stored in ~/.aws/credentials are re-generated each time
    based on the selected profile, using the MFA token.
    """
    config_file = Path.home() / '.aws' / 'config'
    profile_file = Path.home() / '.aws' / 'profiles'

    profile_name = None
    while not profile_name:
        profile_name = input('profile name: [default]')
        if not profile_name:
            profile_name = 'default'
        
        config = configparser.ConfigParser()
        config.read(profile_file)
        if profile_name in config.sections():
            print('Profile already exists')
            profile_name = None
            continue

        break

    aws_region = input('AWS region: ')
    aws_access_key_id = input('AWS access key id: ')
    aws_secret_access_key = input('AWS secret access key: ')

    config[profile_name] = {
        'aws_access_key_id': aws_access_key_id,
        'aws_secret_access_key': aws_secret_access_key,
    }
    with profile_file.open('w') as fp:
        config.write(fp)
    
    config = configparser.ConfigParser()
    if config_file.is_file():
        config.read(config_file)
    config[profile_name] = {
        'region': aws_region,
        'output': 'json',
    }
    with config_file.open('w') as fp:
        config.write(fp)

def select_profile() -> str:
    """
    Get the profile from the ~/.aws/profiles file. The data will be used to
    retrieve the AWS credentials to ~/.aws/credentials using the MFA token.
    """
    config_file = Path.home() / '.aws' / 'profiles'

    config = configparser.ConfigParser()
    if config_file.is_file():
        config.read(config_file)

    profiles = config.sections()
    if len(profiles) == 0:
        print('there are no profiles in the config file')
        answer = input('do you want to create a new profile? [y/n] ')
        if answer == 'y':
            create_profile()
            return select_profile()
        else:
            exit()
    
    selected_profile = None
    while not selected_profile:
        print('select a profile:')
        for index, profile in enumerate(profiles):
            print(f'{index+1}. {profile}')
        print('0. create a new profile')

        try:
            selected = int(input('choose a profile: '))
        except ValueError:
            print('please enter a number')
            continue
        
        if selected == 0:
            create_profile()
            return select_profile()
        elif selected > len(profiles):
            print(f'please enter a number between 1 and {len(profiles)}')
        else:
            selected_profile = profiles[selected-1]
            break
    
    return selected_profile

def select_mfa_device() -> str:
    """
    Get the MFA device associated with the selected profile.
    """
    iam_client = boto3.client('iam')

    mfa_devices = []
    kwargs = {}
    while True:
        response = iam_client.list_mfa_devices(**kwargs)
        mfa_devices += [device['SerialNumber'] for device in response.get('MFADevices', [])]
        if response.get('IsTruncated'):
            kwargs['Marker'] = response['Marker']
            continue
        break

    if len(mfa_devices) == 0:
        print('there are no MFA devices')
        exit()
    if len(mfa_devices) == 1:
        return mfa_devices[0]
    
    selected_device = None
    while not selected_device:
        print('select a MFA device:')
        for index, device in enumerate(mfa_devices):
            print(f'{index+1}. {device}')
        try:
            selected = int(input('choose a device: '))
        except ValueError:
            print('please enter a number')
            continue
        
        if selected > len(mfa_devices):
            print(f'please enter a number between 1 and {len(mfa_devices)}')
        else:
            selected_device = mfa_devices[selected-1]
            break
    
    return selected_device


def login():
    """
    Login to AWS. The credentials are stored in ~/.aws/credentials.
    You need to have a profile in ~/.aws/profiles to select the profile.
    """
    config = configparser.ConfigParser()
    config.read(Path.home() / '.aws' / 'profiles')

    profile = select_profile()

    aws_access_key_id = config[profile]['aws_access_key_id']
    aws_secret_access_key = config[profile]['aws_secret_access_key']

    os.environ['AWS_ACCESS_KEY_ID'] = aws_access_key_id
    os.environ['AWS_SECRET_ACCESS_KEY'] = aws_secret_access_key

    mfa_device = select_mfa_device()
    mfa_token = input('MFA token: ')

    sts_client = boto3.client('sts')
    response = sts_client.get_session_token(
        SerialNumber=mfa_device,
        TokenCode=mfa_token
    )
    if 'Credentials' not in response:
        print('invalid MFA token')
        exit()

    credentials = response['Credentials']
    credentials_file = Path.home() / '.aws' / 'credentials'
    config = configparser.ConfigParser()
    config.read(credentials_file)
    config[profile] = {
        'aws_access_key_id': credentials['AccessKeyId'],
        'aws_secret_access_key': credentials['SecretAccessKey'],
        'aws_session_token': credentials['SessionToken'],   
        'aws_session_expiration': str(credentials['Expiration']),
    }
    with credentials_file.open('w') as fp:
        config.write(fp)

if __name__ == '__main__':
    try:
        login()
    except KeyboardInterrupt:
        print()
        exit()
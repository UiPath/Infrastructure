# Getting started

## Prerequisites

- Install `aws` cli. Download from [here](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- Configure credentials using `~/.aws/credentials` file. Credentials contain 3 values and are **valid for only 12 hours**:
    1. aws_access_key_id
    2. aws_secret_access_key
    3. aws_session_token
- git clone the repository
- the repo contains submodules, found in .gitmodules. The submodules are not cloned by default. Either use:
    1. `git clone --recursive [url to git repo]`
    2. `git submodule update --init`
- install the test utility [taskcat](https://pypi.org/project/taskcat/). *Please note that taskcat does not work on Windows*. Use [WSL](https://docs.microsoft.com/en-us/windows/wsl/about). On WSL run the usual:
    1. `sudo apt-get update` and `sudo apt-get upgrade`
    2. Install pip3: `sudo apt-get install python3-pip`
    3. Install taskcat: `pip3 install taskcat --user`
    4. (Optional) install the aws CLI on WSL as well with `sudo apt-get install awscli`. If `aws` throws exceptions, also execute `pip3 install --upgrade awscli`
    5. Add your AWS credentials to Ubuntu by copying the AWS credentials file from your Windows profile to your Linux profile (`~/.aws/credentials`). If you don't have a credentials file in your Windows profile, follow these [steps](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-config) to create one.  
    Note: In order to generate the credentials file you need to install AWS CLI
- create EC2 key pair as described [here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairshtml). Make sure the key pair is created in the region used during aws cli configuration
- for this project, a domain name needs to exist in Route53, to be used during testing/deployment
 
## Testing during development

Deploying the [stack](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/stacks.html) manually can be done using the aws cli. But, because of the functionality of `aws cloudformation` cli, which requires the templates to be uploaded to an S3 bucket, there are more than one step to it. 

The templates reference nested templates in S3 buckets: 
`https://${S3Bucket}.s3.${S3Region}.${AWS::URLSuffix}/${QSS3KeyPrefix}templates/orchestrator/security.template.yaml` 
And the bucket and region values need to be propagated via input parameters. 

For this reason, during development, the use of taskcat is strongly encouraged. To test the deployment of the project, simply run:

```shell script
taskcat test run -k -l
```

The `-k` modifier will keep failed stacks, and `-l` will skip the static linting of the templates
This command line will: 
- upload the project folders to an S3 bucket, with a dynamically generated name (as specified in `.taskcat.yaml`):
```yaml
      QSS3KeyPrefix: "quickstart-uipath-orchestrator/"
      QSS3BucketName: "$[taskcat_autobucket]"
      QSS3BucketRegion: "$[taskcat_current_region]"
``` 
- create a stack using the master template as an entry point and passing the input parameters

The main purpose of taskcat is to validate the deployment across multiple AWS regions

For values that are not to be uploaded to git, use the config file `~/.taskcat.yml` and add general parameters which supersede configurations inside the project config:

```yaml
general:
  s3_regional_buckets: true
  parameters:
    KeyPairName: <<key-value>>
```

### Deploy and update stack

If, during development, an upload-deploy-delete workflow is not convenient, and multiple updates of the stacks are required, a different set of commands should be used:

```shell script
taskcat upload -c ./dev-docs/.taskcat.yml
```

After the project is uploaded, the stack can be deployed with:

```shell script
aws cloudformation create-stack --stack-name <<test-stack-name>> --template-url https://tcat-temp-aws-tests-qmvx56m7.s3.amazonaws.com/quickstart-uipath-orchestrator/templates/orchestrator/master.template.yaml --parameters file://dev-docs/input-parameters.json --capabilities CAPABILITY_IAM --region <<region-name>>
```
Updating the stack:
```shell script
aws cloudformation update-stack --stack-name <<test-stack-name>> --template-url https://tcat-temp-aws-tests-qmvx56m7.s3.amazonaws.com/quickstart-uipath-orchestrator/templates/orchestrator/master.template.yaml --parameters file://dev-docs/input-parameters.json --capabilities CAPABILITY_IAM --region <<region-name>>
```

The `input-parameters.json` file should have this structure:
```json
[
  {
    "ParameterKey": "OrchestratorLicense",
    "ParameterValue": "primarykey"
  },
  {
    "ParameterKey": "RDSPassword",
    "ParameterValue": "QWbGk1VhWiN8m"
  },
  {
    "ParameterKey": "AdminPassword",
    "ParameterValue": "QWbGk1VhWiN8m"
  },
  {
    "ParameterKey": "HAAPassword",
    "ParameterValue": "QWbGk1VhWiN8m"
  }
]
```
with a value for each required input parameter

### Delete CloudWatch logs

While testing, logs will aggregate over time in CloudWatch. To clear all logs generated by the AWS Lambda functions deployed, run:

```shell script
aws logs describe-log-groups --query 'logGroups[*].logGroupName' --output table | \
awk '{print $2}' | grep ^/aws/lambda | while read x; do  echo "deleting $x" ; aws logs delete-log-group --log-group-name $x; done
```

## Running commands at instance launch

AWS employs a 3 tier bootstrapping architecture:
1. `EC2Launch` is always executed. Configures items such as Computer name, DNS suffixes and executes `user data` from instance metadata
2. `user data`, present at the instance metadata endpoint. It is interpreted by EC2Launch and executed
3. For more complex configurations it is strongly recommended to use `cfn-init`, called from inside the `user data` script. It too uses the metadata endpoint to get the required configuration information. Specifically, the information used by `cfn-init` needs to be in a specific format for it to be interpreted. When using cloudformation, the metadata needs to be added [here](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-init.html) 

The use of `cfn-init` is documented [here](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-init.html)

### Development

For dev work, since the deployment of the whole stack can be quite cumbersome, we would want to execute the `user data` with every reboot or update. For this, execute this command on the VM, as described [here](https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/ec2-windows-user-data.html):

```powershell
C:\ProgramData\Amazon\EC2-Windows\Launch\Scripts\InitializeInstance.ps1 –Schedule
```

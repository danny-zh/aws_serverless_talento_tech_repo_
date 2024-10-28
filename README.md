# Blog Project

A simple web Flask project running on a three tier (frontend, backend, database) AWS serveless infrastructure by using api gw, lambda, dynamodb, s3, ses, cloudfront and waf. 

## How do I deploy to this app to my aws account?
1. Install aws CLI following [AWS CLI setup](https://docs.aws.amazon.com/cli/v1/userguide/install-linux.html)
2. Configure aws CLI credentials following the method better suits your needs. See [AWS Credentials](https://docs.aws.amazon.com/cli/v1/userguide/cli-chap-configure.html)
2. Make sure you have the following binaries installed. 
    - Make
    - Terraform
    - Pip
2. CD to terraform folder of this project(cd terraform) and initialize the project (terraform init)
3. Check terrafom plan (terrraform plan) and apply changes (terraform apply --auto-approve)

## Important:
- You can define the email to be used as entity in [Simple Email Service (SES)](https://docs.aws.amazon.com/ses/latest/dg/Welcome.html) in your own terraform.tfvars. Check the variables.tf file to use the same name of the variable defined in the *.tfvars file. If not defined, after terraform apply you will be prompted to provide such value.
- SES is using email address entity which requires manual confirmation sent to your email. After this deployment is done succesfully, you need to check your inbox and click on the verification link. See [SES Verification](https://docs.aws.amazon.com/ses/latest/dg/creating-identities.html)


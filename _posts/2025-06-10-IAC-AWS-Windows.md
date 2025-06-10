---
title: Deploying Free AWS Windows EC2 with IAC
date: 2025-06-10 04:37:30 -0500
categories: [documentation,tutorial]
tags: [windows,aws,iac,ec2,openTofu]
---

# 🚀 Deploying a Free Tier Windows EC2 with Infrastructure as Code (IaC)

Are you interested in deploying a Windows Server EC2 instance on AWS for free, using Infrastructure as Code from your Windows workstation? This guide walks you through setting up a free tier-eligible Windows EC2 instance, with the option to enable AWS Systems Manager (SSM) for secure remote management. Follow along for a practical, step-by-step approach to automating your cloud infrastructure.

---

## 📔 A Note on AWS Tools: AWS CLI vs PowerShell Module

While I personally prefer and love working with PowerShell for most automation tasks, I've found that the AWS PowerShell modules have some limitations when it comes to the specific operations needed for this guide. The AWS CLI tools are currently more feature-complete and better documented for these particular workflows.

The AWS PowerShell cmdlets, while powerful, sometimes lack direct equivalents to certain CLI commands or require more complex parameter handling.

If you're a PowerShell enthusiast like me, you might prefer using the PowerShell modules, but be aware that you may need to do additional work to achieve the same results. Hopefully, AWS will continue improving their PowerShell modules over time to achieve feature parity with the CLI tools.

For this guide, we'll stick with the AWS CLI to ensure the most reliable experience.

---

## 📋 Prerequisites

- **AWS account** (free tier works great!)
- **Windows** (any modern version should be fine)
- **[OpenTofu](https://opentofu.org/)** (open-source Terraform-compatible IaC tool)
- **[AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)**

---

## 🔑 How to Get Your AWS Access Keys

> 📌 **Note:** The AWS Console changes frequently, so these exact instructions may vary slightly over time.

To use AWS Tools securely, you need an **Access Key ID** and **Secret Access Key** from an IAM user in your AWS account.  
**Do not use your root account for day-to-day AWS operations.**  
Instead, log in as the root user only to create an appropriate IAM user and assign the necessary permissions.

### Steps

1. **Log in as AWS Root User (one time, for setup):**
    - Go to the [AWS Console](https://console.aws.amazon.com/).
    - Select **Root user** and enter your AWS account email and password.
2. **Create an IAM Policy with Required Permissions:**
    - In the AWS Console, go to **IAM** > **Policies** > **Create policy**.
    - Switch to the **JSON** tab, and paste the following for full EC2, IAM, and SSM access (for demo/prototyping):

    ```json
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "ec2:*",
            "iam:*",
            "ssm:*",
            "cloudwatch:*",
            "logs:*"
          ],
          "Resource": "*"
        }
      ]
    }
    ```
    - Click **Next**, then give it a name like `AdminAccessFull`, and click **Create policy**.
3. **Create an IAM User for PowerShell Automation:**
    - Go to **IAM** > **Users** > **Create user**.
    - Enter a user name (e.g., `pwsh-automation`).
    - Select **Attach existing policies directly**.
    - Search for and check your new policy (`AdminAccessFull`).
    - Complete the wizard (**skip adding to groups, no tags needed**).
4. **Create the Access Keys:**
    - After user creation, click your new user and then click **Create access keys**.
    - *You will not be able to view the secret again after this step so save your keys safely.*
5. **(Optional: Secure best practice)**
    - After you’ve created your IAM user, sign out of root.
    - Use the IAM account for all future automation and scripting.
6. **Configure AWS CLI or PowerShell with Your Keys:**
    - Use the keys with the following commands.

> 📌 **Security Notes:**
> - Never use root credentials for scripting or applications.
> - Never share, commit, or email your secret access keys.
> - Restrict IAM permissions for production use as much as possible.
> - Rotate keys regularly and delete unused credentials.

---

## ⚙️ Configure AWS Credentials

```powershell
aws configure

# AWS Access Key ID [None]: yourKey
# AWS Secret Access Key [None]: yourOtherKey
# Default region name [None]: us-east-1
# Default output format [None]: json
```

---

## 🏗️ Infrastructure as Code with OpenTofu

[Download main.tf](/assets/files/openTofu/windowsDEMO/main.tf)

## 🧩 Breaking Down the `main.tf`: What Each Section Does

Curious what all those blocks in your `main.tf` actually do? Here’s a quick tour of each section, so you know exactly what’s happening when you deploy your Windows EC2 instance with SSM using OpenTofu!

---

### 1️⃣ Provider and Required Providers
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
```
This block sets up the AWS, TLS, and Local providers, and specifies the AWS region for resource creation.

---

### 🔑 SSH Key Pair Generation
```hcl
variable "ssh_key_path" { ... }
resource "tls_private_key" "ec2" { ... }
resource "local_sensitive_file" "ec2_private_key" { ... }
resource "aws_key_pair" "ec2" { ... }
```
This section generates a new SSH key pair for EC2 access, saves the private key locally, and registers the public key with AWS.

---

### 🌐 VPC and Subnet Data Sources
```hcl
data "aws_vpc" "default" { ... }
data "aws_subnets" "default" { ... }
```
These data sources automatically find your default VPC and its subnets, ensuring the instance launches in the right network.

---

### 🛡️ IAM Role, Policy Attachment, and Instance Profile for SSM
```hcl
resource "aws_iam_role" "ssm_role" { ... }
resource "aws_iam_role_policy_attachment" "ssm_attach" { ... }
resource "aws_iam_instance_profile" "ssm_profile" { ... }
```
This creates an IAM role and instance profile that allow the EC2 instance to use AWS Systems Manager (SSM) features.

---

### 🔒 Security Group for RDP and SSM
```hcl
resource "aws_security_group" "win_sg" { ... }
```
Defines a security group that allows inbound RDP (port 3389) and all outbound traffic. (For demo/testing only—restrict in production!)

---

### 🪟 Windows AMI Data Source
```hcl
data "aws_ami" "windows" { ... }
```
Finds the latest official Windows Server 2022 AMI from Amazon.

---

### 💻 EC2 Instance Resource
```hcl
resource "aws_instance" "win_ec2" { ... }
```
Launches a Windows EC2 instance using the latest Windows AMI, free tier-eligible instance type, the generated SSH key, the SSM-enabled IAM role, and the security group. The root volume is set to 30GB (required for Windows).

---

### 📦 Outputs
```hcl
output "windows_instance_public_ip" { ... }
output "key_pair_name" { ... }
output "private_key_path" { ... }
```
These outputs provide the public IP of the instance, the key pair name, and the path to your generated private key.

---

## 🚦 Getting Started: Set Up and Launch Your Project

With your `main.tf` file explained, here’s how to get your environment ready and deploy your Windows EC2 instance using OpenTofu:

1. 📁 **Create a folder for your project and navigate into it:**

```powershell
mkdir demo
cd demo
```

2. ⏬ **Download the main.tf file:**

[Download main.tf](/assets/files/openTofu/windowsDEMO/main.tf)

3. 🔨 **Initialize and apply the configuration:**

```powershell
tofu init
tofu plan
tofu apply
```
Make sure there are no errors, then type `yes` to confirm resource creation.

---

## 🖥️ Managing EC2

After your instance is running, you can manage and connect using AWS CLI:

### 🔍 Get the Instance ID and DNS

```powershell
# Get the instance ID (replace "demo" with your tag value if different)
aws ec2 describe-instances `
  --filters "Name=tag:Name,Values=demo" `
  --query "Reservations[*].Instances[*].InstanceId" `
  --output text

# Get the public DNS
aws ec2 describe-instances `
  --filters "Name=tag:Name,Values=demo" `
  --query "Reservations[*].Instances[*].PublicDnsName" `
  --output text
```

These commands will print the instance ID and public DNS for your Windows EC2 instance.

### 🔐 Get Windows Administrator Password


```powershell
aws ec2 get-password-data --instance-id i-xxxxxxxxxxxxxxxxx --priv-launch-key C:\path\to\demo\aws-ec2-key.pem --region us-east-1
```
- You’ll need the private key `aws-ec2-key.pem` to decrypt the password, it was created in the `demo` folder from earlier.

---

## 🎮 Time to Play!

Now that you have your Windows EC2 instance up and running, it's time to have some fun with it!

- **Try RDP**: Connect using the administrator password you retrieved and explore your fresh Windows Server environment
- **Experiment with SSM**: Use AWS Systems Manager to manage your instance without needing RDP
- **Break things (safely)**: Try modifying configurations, installing software, or tweaking settings
- **Start over**: When you're done playing, run the cleanup steps and deploy again with different parameters

Don't be afraid to experiment! This is a sandbox environment perfect for learning and testing. The beauty of Infrastructure as Code is that you can always tear it down and rebuild it exactly the same way (or with your new modifications).

---

## 🧹 Cleanup

When done, destroy your resources to avoid charges. This will undo everything we created with OpenTofu, but not the manual things we did in the AWS console.

```powershell
tofu destroy
```

---

## 💭 Final Thoughts

- **OpenTofu** is a drop-in, open-source replacement for Terraform. Everything you learn here applies to Terraform!
- **Next steps?** Stay tuned for connecting to RDP using SSM!

---

**Happy automating!** 🚀

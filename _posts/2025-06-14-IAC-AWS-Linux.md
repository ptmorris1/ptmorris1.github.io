---
title: Spinning Up Linux EC2s with IaC
date: 2025-06-14 12:02:40 -0500
categories: [documentation,tutorial]
tags: [linux,aws,iac,ec2,openTofu,ssm]
---

## Spinning Up Linux EC2s with IaC 🚀

Welcome back, cloud wranglers!  
If you followed my last adventure (where we bootstrapped a Windows Server on AWS using OpenTofu), you already know the basics: **infrastructure-as-code** and that satisfying moment when your instance’s public IP pops up in the terminal.  If you don't know the basics, see here to [get started](https://ptmorris1.github.io/posts/IAC-AWS-Windows/).

But Windows isn’t the only flavor in the AWS free tier ice cream shop. **Today, we’re going to double the fun (literally) by launching two Linux EC2 instances—with SSM access, SSH keys, and all the trimmings.** If you’re a Windows admin dabbling in Linux or IaC, this is the perfect way to get started.

* * *

## The Terraform File: Deja Vu, but Make It Linux
  
👉 [**Download the main.tf file here**](/assets/files/openTofu/linuxDEMO/main.tf)

* * *

## What’s New and Why?

### Double the Linux, Double the Fun

The magic is in this line:

```
count = 2
```

Now you get **two** EC2 instances, each with its own public IP and Free Tier-friendly 8GB root volume. You can easily go 3 without hitting a free limit, but be careful leaving them all running for days on end or you risk being charged money! 

* * *

### Amazon Linux 2 (AL2)

We filter for Amazon’s official, up-to-date, x86_64 AL2 AMIs.  
**Free, fast, and friendly** to beginners and pros alike!  
_You could change the filter for Ubuntu if you want to experiment!_

* * *

### SSM Setup

Just like with Windows, SSM lets you connect to your instances **without opening SSH** (but we open SSH for learning/demo purposes).

*   **IAM role** and **instance profile** magic are included so you can use AWS Systems Manager Session Manager.

* * *

### Key Pair Goodness

Your SSH key is generated on the fly and saved wherever you specify.

**Connect via SSH:**

```powershell
ssh -i aws-ec2-linux-key.pem ec2-user@<public_ip>
```

* * *

## SSM: The Secret Passage

With SSM, you don’t need to open port 22 if you don’t want to!  
Here’s how to connect using the AWS CLI:

```powershell
aws ssm start-session --target <instance-id> --region us-east-1
```

>  **Note:**  
> No public IP? No problem! SSM tunnels right through.

* * *

## ⚡ Quickstart

### 1\. Initialize and apply

```powershell
tofu init
tofu plan
tofu apply
```

### 2\. Get your instance info (table output!)

```powershell
terraform output linux_instance_table
```

```
linux_instance_table = [
  {
    "id" = "i-0abcd1234ef567890"
    "public_ip" = "3.82.200.42"
    "name" = "al2-demo-1"
  },
  {
    "id" = "i-0bcde2345fa678901"
    "public_ip" = "44.204.119.108"
    "name" = "al2-demo-2"
  }
]
```

### 3\. SSH in

```powershell
ssh -i aws-ec2-linux-key.pem ec2-user@3.82.200.42
```

#### Troubleshooting: SSH Key Permissions Error

If you see an error like this when connecting via SSH:

```
Bad permissions. Try removing permissions for user: NT AUTHORITY\Authenticated Users (S-1-5-11) on file linuxdemo/aws-ec2-linux-key.pem.
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@         WARNING: UNPROTECTED PRIVATE KEY FILE!          @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Permissions for 'aws-ec2-linux-key.pem' are too open.
It is required that your private key files are NOT accessible by others.
This private key will be ignored.
Load key "aws-ec2-linux-key.pem": bad permissions
```

> **Fix:** Set your key location and run commands.

```powershell
# Set permissions on key to be secure for SSH usage.
# Set Key File Variable:
$Key = "aws-ec2-linux-key.pem"

# Remove Inheritance:
icacls $Key /c /Inheritance:d

# Set Ownership to Owner:
icacls $Key /c /Grant ${env:UserName}:F

takeown /F $Key
icacls $Key /c /Grant:r ${env:UserName}:F

# Remove All Users, except for Owner:
icacls $Key /c /Remove:g Administrator "Authenticated Users" BUILTIN\Administrators BUILTIN Everyone System Users

# Verify:
icacls $Key

# Remove Variable:
Remove-Variable -Name Key
```

### 4\. Try SSM

```powershell
aws ssm start-session --target i-0abcd1234ef567890 --region us-east-1
```

### 5\. Destroy When Done

```powershell
tofu destroy
```

> **Cleanup:** Run this when you're finished to avoid unnecessary AWS charges!

* * *

## **Tips, Notes & Styling**

*   **Tip:** The default user for Amazon Linux is `ec2-user`.
*   **Security Reminder:** For real projects, restrict your SSH security group to your IP!
*   **Pro Tip:** Adjust the tag format in the Terraform for easier instance management.

* * *

## Wrapping Up

With just a few lines of IaC, you’ve spun up Linux in the cloud, with remote management and SSH at your fingertips.  
**Next up:** Stay tuned for form SSM fun using port forwarding 🌩️

* * *
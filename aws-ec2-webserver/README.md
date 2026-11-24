# AWS Secure EC2 Web Server

A beginner-friendly project that serves a responsive website from Apache on an Amazon Linux 2023 EC2 instance. It introduces IAM identities and permissions, key-pair SSH access, and security-group network rules.

> **Cost and security:** EC2, public IPv4 addresses, and related AWS resources can incur charges. Check current pricing and your account's free-tier eligibility before starting. This is a learning setup: HTTP is not encrypted, and a public IP is not a production hosting design. Do not send sensitive information to this site.

## Project files

| File | Purpose |
| --- | --- |
| `index.html` | Website content and responsive navigation |
| `style.css` | Responsive visual design |
| `script.js` | Mobile navigation and current-year footer |
| `deploy.sh` | Installs Apache and deploys the three website files |
| `iam-policy.json` | Example policy for read-only EC2 inventory |
| `security-group-rules.txt` | Inbound/outbound rule reference |
| `README.md` | Setup, deployment, and cleanup instructions |

## Where to run each command

- **AWS Management Console:** Create IAM identities, key pairs, security groups, and EC2 instances.
- **Your Windows PC — PowerShell:** Run the `ssh` and `scp` commands below. Do not run these in the AWS Console or on the instance.
- **The EC2 instance — Amazon Linux shell over SSH:** Run `sudo bash deploy.sh` and the Linux verification commands. Do not run these in Windows PowerShell.
- **Your browser:** Open the instance's public IPv4 address to view the site.

## 1. Prepare AWS access safely

1. Sign in to the AWS Management Console using your organization's access method. For personal learning, protect the root account with MFA and use it only for tasks that require root. Never create root access keys.
2. Prefer IAM Identity Center (successor to AWS SSO) for human access. If this standalone exercise requires IAM users, create a named user for each person, enable MFA, and grant console or CLI access only as needed. Do not share users or credentials.
3. Create an IAM group that matches a job function and attach only the permissions that function requires. A group is a convenient way to assign policies consistently; it is not a login identity.
4. The included `iam-policy.json` is a **read-only EC2 inventory example**. It permits selected `Describe` actions and does not permit launching, stopping, or changing instances. In the console, open **IAM → Policies → Create policy → JSON**, paste the file contents, review, and create it. Attach it to a suitable read-only group or role—not automatically to every user.
5. In that policy, `Resource: "*"` is used because these EC2 `Describe` APIs generally do not support resource-level restrictions. The allowed actions are still limited. Review AWS service authorization documentation before adapting the policy.
6. IAM policies describe permissions, roles are assumed identities with temporary credentials, and groups collect IAM users for shared permissions. Avoid granting broad administrator access for day-to-day work.

### Does this EC2 website need an IAM role?

The static website and Apache do not call AWS APIs, so this project needs no instance role. If you later add an application that calls AWS, create a role trusted by EC2, attach only the specific permissions that application requires, and attach the role through an instance profile. Do not put access keys in the website or on the instance. For Session Manager access, use the appropriate SSM instance role and network setup instead of opening SSH.

## 2. Create a key pair and security group

Do these steps in the **AWS Management Console** in the region where you will deploy:

1. Open **EC2 → Key Pairs → Create key pair**. Choose a descriptive name such as `aws-ec2-webserver`, select **RSA** and **.pem**, and download the private key. Store it in a safe location under your Windows user profile. The private key cannot be downloaded again. Never share it or add it to this project or source control.
2. Find your current public IPv4 address using a trusted method. In the EC2 console's security-group rule editor, choosing **My IP** fills in the current address with `/32`. If your address changes, update this rule.
3. Open **EC2 → Security Groups → Create security group**. Name it `webserver-http-ssh` and select the default VPC (or another VPC with a public subnet and internet route).
4. Add exactly these inbound rules:

   | Type | Port | Source | Reason |
   | --- | ---: | --- | --- |
   | HTTP | 80 | `0.0.0.0/0` | Public IPv4 website access |
   | SSH | 22 | Your current public IPv4 `/32` | Administrative connection from your PC |

5. Keep the default outbound allow-all rule for this learning exercise so the instance can download Apache and updates. More restrictive egress requires planning for the destinations the instance needs.
6. Security groups are **stateful** virtual firewalls: response traffic for an allowed connection is automatically permitted. See `security-group-rules.txt` for the text version. Never expose SSH to `0.0.0.0/0`.

## 3. Launch Amazon Linux 2023

In the **AWS Management Console**, choose **EC2 → Instances → Launch instances**:

1. Set a name such as `aws-secure-webserver`.
2. Under **Application and OS Images**, choose **Amazon Linux 2023 AMI** (64-bit x86).
3. Choose a small general-purpose instance such as `t3.micro` if it is available and appropriate for your account/region. Check current pricing and free-tier eligibility; the instance type and free-tier offers vary.
4. Under **Key pair**, select the key pair you created above.
5. Under **Network settings**, select the VPC and public subnet you prepared, enable assignment of a public IPv4 address, and select the `webserver-http-ssh` security group. Confirm its inbound rules before launch.
6. Leave storage at the small default for this static demo. Do not add an instance IAM role; Apache does not need AWS API access for this project.
7. Review the settings and launch the instance. Wait for **Instance state: Running** and **Status check: 2/2 checks passed**.
8. Copy the instance's **Public IPv4 address** from its details. It may change after a stop/start unless you use an Elastic IP, which can incur charges.

The VPC must have an internet gateway route for the public subnet, and the subnet must assign a public IPv4 address. A security-group rule alone does not provide internet routing.

## 4. Connect from Windows PowerShell

Run these commands in **PowerShell on your Windows PC**, not in the EC2 shell. In the first command, set the path to the key you downloaded. Replace `203.0.113.10` with the instance's actual public IPv4 address from the EC2 console.

```powershell
$Key = "$env:USERPROFILE\Downloads\aws-ec2-webserver.pem"
$PublicIp = "203.0.113.10"
Test-Path $Key
ssh -i $Key "ec2-user@$PublicIp"
```

`Test-Path` should return `True`. `203.0.113.10` is a documentation-only example address and will not connect; replace it. If SSH times out, verify that the instance is running, the public IP and public-subnet route are correct, and the security group allows port 22 from your current public IPv4 `/32`. If SSH reports a key permission error, secure the private-key file so only your Windows user can read it; never make the key broadly readable.

At the first connection, review the host-key fingerprint prompt and continue only if you expect to connect to this instance. After connecting, the prompt is the **Amazon Linux shell**.

## 5. Copy and deploy the website

First, disconnect from the instance shell with `exit`. In **PowerShell on your Windows PC**, change to the directory containing this README and copy the site files and deployment script. Use the same key and IP from the previous section:

```powershell
Set-Location "C:\website\aws\aws-ec2-webserver"
scp -i $Key .\index.html .\style.css .\script.js .\deploy.sh "ec2-user@${PublicIp}:~/"
```

Connect again from PowerShell:

```powershell
ssh -i $Key "ec2-user@$PublicIp"
```

Now, in the **Amazon Linux shell over SSH**, install and start Apache by running the script with `sudo`:

```bash
sudo bash ~/deploy.sh
```

The script checks its required files, installs `httpd` using `dnf`, copies the website into `/var/www/html/`, enables Apache at boot, starts it, and verifies that the service is active. It only replaces `index.html`, `style.css`, and `script.js` in the web root; it does not remove other files there.

Verify from the **Amazon Linux shell**:

```bash
systemctl is-active httpd
curl -I http://localhost/
```

The first command should print `active`; the HTTP response should include `200 OK`. Then, on your PC, open `http://<your-instance-public-ip>/` in a browser, substituting the actual public IP. HTTP is intentionally used for this introductory exercise and is not encrypted.

## 6. IAM role vs. SSH key

These are different access mechanisms:

- The **EC2 key pair** authenticates your SSH connection from your PC to the Linux instance.
- An **IAM role** grants the instance temporary AWS API permissions if software on it needs to access other AWS services.
- An **IAM user or Identity Center identity** is for a person or tool to access AWS APIs/console; it does not replace the SSH key.
- A **security group** filters network traffic. It does not grant AWS API permissions or authenticate a person.

Keep the private key private. Never embed keys or AWS credentials in HTML, JavaScript, shell scripts, or the Git repository.

## 7. Cleanup

When finished, terminate the EC2 instance from **EC2 → Instances → Instance state → Terminate instance**. Termination is permanent. Also delete the security group and key pair if you no longer need them, and remove any IAM policy/group/user created only for this exercise. Check for other billable resources such as Elastic IP addresses, snapshots, or load balancers. Stopping an instance may still leave storage or public IPv4 charges.

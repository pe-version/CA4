# SSH Access Strategy

## Current Approach (Academic Project)

For CA4, we've configured the AWS security group to allow SSH from `0.0.0.0/0` (all IPs) for project convenience.

**Why this decision was made:**
- Academic project with 1-week timeline
- Need rapid access for troubleshooting and configuration
- IP addresses may change frequently (home/campus networks)
- Cluster will be terminated after grading
- Low risk profile (no production data, temporary infrastructure)

**Security trade-offs accepted:**
- SSH port is exposed to internet
- Relies on SSH key authentication only
- Susceptible to brute-force attempts (mitigated by key-only auth)
- Does not comply with enterprise security policies

## Enterprise Production Approach

In a production environment, **never** use `0.0.0.0/0` for SSH access. Use one of these strategies:

### Option 1: AWS Systems Manager Session Manager (Recommended)

**How it works:**
- No SSH port exposed to internet (port 22 closed)
- Access instances through AWS Console or CLI
- All sessions logged to CloudTrail
- No need to manage SSH keys
- Works through private subnets

**Implementation:**
```hcl
# In Terraform - Remove SSH ingress rule entirely
# Add IAM role with SSM permissions to EC2 instances

resource "aws_iam_role" "ec2_ssm_role" {
  name = "ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

resource "aws_instance" "k3s_master" {
  # ... other config
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
}
```

**Access via CLI:**
```bash
aws ssm start-session --target i-1234567890abcdef0
```

**Pros:**
- No public SSH port
- Centralized access management via IAM
- Full audit trail
- No SSH key distribution needed

**Cons:**
- Requires SSM agent on instances (pre-installed on Amazon Linux/Ubuntu)
- Slightly higher latency than direct SSH
- Requires AWS CLI setup for users

---

### Option 2: Bastion Host with Elastic IP

**How it works:**
- Single hardened instance with fixed Elastic IP
- All SSH traffic goes through bastion
- Application instances in private subnets (no public IPs)
- Bastion security group restricted to company IP ranges

**Implementation:**
```hcl
# Bastion in public subnet
resource "aws_instance" "bastion" {
  ami           = var.ami_id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public_subnet.id

  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  tags = {
    Name = "bastion-host"
  }
}

resource "aws_eip" "bastion_eip" {
  instance = aws_instance.bastion.id
}

resource "aws_security_group" "bastion_sg" {
  name = "bastion-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["203.0.113.0/24"]  # Company VPN/office IP range
    description = "SSH from corporate network only"
  }
}

# Application instances in private subnet
resource "aws_security_group" "private_sg" {
  name = "private-instances-sg"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
    description     = "SSH from bastion only"
  }
}
```

**Access pattern:**
```bash
# SSH to bastion first
ssh -i bastion-key.pem ubuntu@bastion-elastic-ip

# Then SSH to private instances
ssh -i app-key.pem ubuntu@10.0.1.x
```

**Pros:**
- Single point of control
- Fixed IP (easy firewall rules)
- Can add MFA/2FA at bastion level
- Works with existing SSH workflows

**Cons:**
- Single point of failure (mitigate with auto-scaling group)
- Additional cost for bastion instance
- Need to manage bastion security patching

---

### Option 3: Corporate VPN with Known CIDR Ranges

**How it works:**
- All engineers connect through corporate VPN
- VPN has static NAT gateway IPs
- Security groups allow only VPN CIDR ranges

**Implementation:**
```hcl
resource "aws_security_group" "k3s_sg" {
  name = "k3s-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [
      "198.51.100.0/24",  # Office VPN range
      "203.0.113.0/24"    # Remote VPN range
    ]
    description = "SSH from corporate VPN only"
  }
}
```

**Pros:**
- Leverages existing corporate network infrastructure
- Transparent to users (auto-connects)
- Can enforce client security posture checks

**Cons:**
- Requires corporate VPN infrastructure
- VPN must have stable IP ranges
- Adds VPN as dependency for access

---

### Option 4: CI/CD Pipeline Access Only

**How it works:**
- No human SSH access at all
- All changes deployed via CI/CD pipeline
- Pipeline runs from known NAT gateway IPs
- Emergency access via AWS Console/SSM

**Implementation:**
```hcl
resource "aws_security_group" "k3s_sg" {
  name = "k3s-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [
      "54.239.28.176/32"  # GitHub Actions NAT IP
    ]
    description = "SSH from CI/CD pipeline only"
  }
}
```

**Pros:**
- GitOps workflow (all changes in version control)
- No ad-hoc human access reduces risk
- Immutable infrastructure mindset

**Cons:**
- Requires mature CI/CD practices
- Difficult initial troubleshooting
- Need backup access method for emergencies

---

## Automated Dynamic IP Management

For environments with dynamic IPs, automate security group updates:

### Lambda Function Approach

```python
# Lambda function triggered by CloudWatch Events (cron)
import boto3
import requests

def lambda_handler(event, context):
    # Get current office IP from DNS or external service
    current_ip = requests.get('https://api.ipify.org').text

    ec2 = boto3.client('ec2')
    sg_id = 'sg-xxxxxxxxx'

    # Remove old rules
    ec2.revoke_security_group_ingress(
        GroupId=sg_id,
        IpPermissions=[{
            'IpProtocol': 'tcp',
            'FromPort': 22,
            'ToPort': 22,
            'IpRanges': [{'CidrIp': '0.0.0.0/0'}]
        }]
    )

    # Add new rule with current IP
    ec2.authorize_security_group_ingress(
        GroupId=sg_id,
        IpPermissions=[{
            'IpProtocol': 'tcp',
            'FromPort': 22,
            'ToPort': 22,
            'IpRanges': [{'CidrIp': f'{current_ip}/32'}]
        }]
    )
```

**Schedule with CloudWatch Events:**
- Run every hour
- Send SNS alert on failures
- Log all changes to CloudWatch Logs

---

## Recommendation by Use Case

| Use Case | Best Option | Why |
|----------|-------------|-----|
| AWS-native production | SSM Session Manager | No SSH port, IAM-based, audit trail |
| Multi-cloud production | Bastion + VPN | Works across clouds, centralized |
| Highly regulated (finance, healthcare) | SSM + MFA + VPC Flow Logs | Compliance requirements |
| Startup/small team | Bastion with Elastic IP | Simple, cost-effective |
| Large enterprise | Corporate VPN + Bastion | Leverages existing infrastructure |
| Immutable infrastructure | No SSH + CI/CD only | Modern, GitOps approach |

---

## Apply Current Changes

To apply the updated Terraform configuration:

```bash
cd terraform
terraform plan -var="my_ip=0.0.0.0/0"
terraform apply -var="my_ip=0.0.0.0/0"
```

Or update directly via AWS CLI (faster):

```bash
# Get security group ID
SG_ID=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=CA3-K3s-3Node-sg" \
  --query 'SecurityGroups[0].GroupId' \
  --output text \
  --region us-east-2)

# Update SSH rule to allow all IPs
aws ec2 authorize-security-group-ingress \
  --group-id "$SG_ID" \
  --ip-permissions '[{"IpProtocol":"tcp","FromPort":22,"ToPort":22,"IpRanges":[{"CidrIp":"0.0.0.0/0","Description":"SSH open for project"}]}]' \
  --region us-east-2
```

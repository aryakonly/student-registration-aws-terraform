# terraform-vpc

> AWS VPC Infrastructure with a Student Web Application using Terraform

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.3.0-7B42BC?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-ap--south--1-FF9900?logo=amazonaws)](https://aws.amazon.com/)
[![MariaDB](https://img.shields.io/badge/Database-MariaDB%2010.6-003545?logo=mariadb)](https://mariadb.org/)
[![Tomcat](https://img.shields.io/badge/Server-Apache%20Tomcat%209-F8DC75?logo=apachetomcat)](https://tomcat.apache.org/)

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Resources Created](#resources-created)
- [Prerequisites](#prerequisites)
- [Input Variables](#input-variables)
- [Output Values](#output-values)
- [Usage](#usage)
- [Application Details](#application-details)
- [Security Groups](#security-groups)
- [Security Considerations](#security-considerations)
- [Troubleshooting](#troubleshooting)

---

## Overview

This Terraform project provisions a complete AWS infrastructure to host a **Student Registration Web Application**. It creates a custom VPC in the `ap-south-1` (Mumbai) region with public and private subnets, deploys a Tomcat-based Java web app on a public EC2 instance, and connects it to a MariaDB RDS database in the private subnet.

**What gets deployed:**
- A custom VPC with public and private subnets across two AZs
- An Internet Gateway for public subnet internet access
- A NAT Gateway for private subnet outbound access
- Two EC2 instances — a Tomcat app server (public) and a DB initializer (private)
- A MariaDB RDS instance (`studentapp` database)
- Two Security Groups — one for EC2, one for RDS
- An RDS Subnet Group spanning both subnets
- Automated bootstrapping via `user_data` scripts

---

## Architecture

```
                        Internet
                           │
                    ┌──────▼──────┐
                    │   Internet  │
                    │   Gateway   │
                    └──────┬──────┘
                           │
          ┌────────────────▼────────────────────────┐
          │           VPC: 192.34.0.0/16             │
          │                                          │
          │  ┌──────────────────────────────────┐   │
          │  │  Public Subnet: 192.34.0.0/20    │   │
          │  │  AZ: ap-south-1a                 │   │
          │  │                                  │   │
          │  │  ┌─────────────────┐  ┌───────┐  │   │
          │  │  │  EC2: Tomcat    │  │  NAT  │  │   │
          │  │  │  (jump-server)  │  │  GW   │  │   │
          │  │  │  Java 17 + War  │  └───┬───┘  │   │
          │  │  └─────────────────┘      │      │   │
          │  └───────────────────────────┼──────┘   │
          │                              │           │
          │  ┌───────────────────────────▼──────┐   │
          │  │  Private Subnet: 192.34.16.0/20  │   │
          │  │  AZ: ap-south-1b                 │   │
          │  │                                  │   │
          │  │  ┌──────────────┐  ┌──────────┐  │   │
          │  │  │  EC2: DB     │  │  RDS     │  │   │
          │  │  │  Initializer │  │  MariaDB │  │   │
          │  │  │ (app-server) │  │  10.6    │  │   │
          │  │  └──────────────┘  └──────────┘  │   │
          │  └──────────────────────────────────┘   │
          └──────────────────────────────────────────┘
```

**Traffic flow:**
- Public subnet (`192.34.0.0/20`) → internet via **Internet Gateway**
- Private subnet (`192.34.16.0/20`) → outbound-only via **NAT Gateway**
- EC2 app server (public) connects to RDS (private) over port `3306`
- Users access the Student app at `http://<public-ip>:8080/student`

---

## Project Structure

```
terraform-vpc-main/
├── vpc.tf            # All AWS resources (VPC, subnets, IGW, NAT, SGs, RDS, EC2)
├── variable.tf       # Input variable declarations with defaults
├── output.tf         # Outputs: public IP and application URL
└── terraform.tfvars  # Variable values (contains db_password — see security note)
```

---

## Resources Created

| Resource | Terraform ID | Details |
|---|---|---|
| VPC | `aws_vpc.my-vpc` | CIDR `192.34.0.0/16`, DNS enabled |
| Public Subnet | `aws_subnet.mysubnet-1` | `192.34.0.0/20`, AZ `ap-south-1a`, auto-assign public IP |
| Private Subnet | `aws_subnet.mysubnet-2` | `192.34.16.0/20`, AZ `ap-south-1b`, no public IP |
| Internet Gateway | `aws_internet_gateway.igw` | Attached to VPC |
| Elastic IP | `aws_eip.nat_eip` | Allocated for NAT Gateway |
| NAT Gateway | `aws_nat_gateway.my-ngw` | Placed in public subnet |
| Default Route Table | `aws_default_route_table.default-tb` | Routes `0.0.0.0/0` → IGW |
| NAT Route Table | `aws_route_table.NAT-tb` | Routes `0.0.0.0/0` → NAT GW |
| RT Association (public) | `aws_route_table_association.public-assoc` | Links public subnet to default RT |
| RT Association (private) | `aws_route_table_association.private-assoc` | Links private subnet to NAT RT |
| Security Group (EC2) | `aws_security_group.my-sg-1` | SSH / HTTP / 8080 / MySQL inbound |
| Security Group (RDS) | `aws_security_group.my-sg-2` | MySQL only from `my-sg-1` |
| RDS Subnet Group | `aws_db_subnet_group.my_db_subnet` | Spans both subnets |
| RDS Instance | `aws_db_instance.my_db` | MariaDB 10.6, `db.t4g.micro`, `studentapp` DB |
| EC2 (App Server) | `aws_instance.Ec2Instance` | Public subnet, Tomcat 9 + student.war |
| EC2 (DB Initializer) | `aws_instance.db-instance` | Private subnet, creates `students` table |

---

## Prerequisites

| Requirement | Version | Notes |
|---|---|---|
| [Terraform](https://www.terraform.io/downloads) | `>= 1.3.0` | |
| [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) | `>= 2.x` | Run `aws configure` before deploying |
| AWS Account | — | Permissions for EC2, VPC, RDS, EIP, NAT GW |
| Key Pair | — | Must exist in `ap-south-1` named `mumbai-key` (or override via variable) |

---

## Input Variables

All variables are in `variable.tf`. Defaults target the Mumbai (`ap-south-1`) region.

| Variable | Type | Default | Description |
|---|---|---|---|
| `region` | `string` | `"ap-south-1"` | AWS deployment region |
| `mumbai_vpc_cidr` | `string` | `"192.34.0.0/16"` | VPC CIDR block |
| `vpc_name` | `string` | `"My-vpc"` | Name tag for the VPC |
| `public_cidr_block` | `string` | `"192.34.0.0/20"` | Public subnet CIDR |
| `public_available_zone` | `string` | `"ap-south-1a"` | Public subnet AZ |
| `public_subnet_name` | `string` | `"public-subnet"` | Public subnet name tag |
| `private_cidr_block` | `string` | `"192.34.16.0/20"` | Private subnet CIDR |
| `private_available_zone` | `string` | `"ap-south-1b"` | Private subnet AZ |
| `private_subnet_name` | `string` | `"private-subnet"` | Private subnet name tag |
| `igw_name` | `string` | `"my-igw"` | Internet Gateway name tag |
| `nat_name` | `string` | `"my-ngw"` | NAT Gateway name tag |
| `nat_route_table_name` | `string` | `"NAT-tb"` | NAT route table name tag |
| `security_group_name_1` | `string` | `"My-sg-1"` | EC2 security group name |
| `description_sg_1` | `string` | `"Allow SSH, HTTP and HTTPS traffic"` | EC2 SG description |
| `security_group_name` | `string` | `"my-sg-2"` | RDS security group name |
| `description_sg` | `string` | `"Allow MySQL only from EC2 security group"` | RDS SG description |
| `image_instance` | `string` | `"ami-051a31ab2f4d498f5"` | AMI ID (Amazon Linux 2023, Mumbai) |
| `instance_type` | `string` | `"t3.micro"` | EC2 instance type |
| `instance_key` | `string` | `"mumbai-key"` | EC2 key pair name |
| `public_instance_name` | `string` | `"jump-server"` | Name tag for the app server |
| `private_instance_name` | `string` | `"application-server"` | Name tag for the DB initializer |
| `db_password` | `string` | *(required, sensitive)* | RDS MariaDB password — **never hardcode** |

---

## Output Values

| Output | Description | Example |
|---|---|---|
| `public-ip` | Public IP of the Tomcat EC2 instance | `13.235.x.x` |
| `app_url` | Direct URL to the Student web app | `http://13.235.x.x:8080/student` |

---

## Usage

### 1. Configure AWS credentials

```bash
aws configure
# Enter: Access Key ID, Secret Access Key, Region: ap-south-1, Output: json
```

### 2. Clone the repository

```bash
git clone https://github.com/aryakonly/terraform-vpc.git
cd terraform-vpc
```

### 3. Set the database password securely

```bash
# Recommended — environment variable
export TF_VAR_db_password="YourSecurePassword123"

# Alternative — CLI flag
terraform apply -var="db_password=YourSecurePassword123"
```

### 4. Ensure your key pair exists in AWS

```bash
aws ec2 describe-key-pairs --key-names mumbai-key --region ap-south-1
```

If it doesn't exist, create one:

```bash
aws ec2 create-key-pair --key-name mumbai-key --region ap-south-1 \
  --query 'KeyMaterial' --output text > mumbai-key.pem
chmod 400 mumbai-key.pem
```

### 5. Initialize, plan, and apply

```bash
terraform init
terraform plan
terraform apply
```

### 6. Access the application

After apply completes, Terraform outputs the URL:

```
Outputs:
public-ip = "13.235.x.x"
app_url   = "http://13.235.x.x:8080/student"
```

> **Note:** The EC2 `user_data` bootstrap takes **3–5 minutes** after the instance starts. Wait before opening the URL.

### 7. Destroy all resources

```bash
terraform destroy
```

---

## Application Details

### Public EC2 — Tomcat App Server (`jump-server`)

The `user_data` script automatically performs:

1. Installs **Java 17 (Amazon Corretto)**, **Python 3**, and **MariaDB client**
2. Downloads and extracts **Apache Tomcat 9.0.115** to `/opt/`
3. Starts Tomcat
4. Downloads **`student.war`** from S3 into `webapps/`
5. Downloads **`mysql-connector.jar`** into Tomcat's `lib/`
6. Waits for RDS to become reachable (polls with `mysqladmin ping`)
7. Injects JDBC `<Resource>` connection config into `context.xml` using Python
8. Restarts Tomcat to apply the DB connection

**App URL:** `http://<public-ip>:8080/student`

### Private EC2 — DB Initializer (`application-server`)

The `user_data` script automatically:

1. Installs **MariaDB 105 client**
2. Waits for the RDS endpoint to respond
3. Creates the `studentapp` database and `students` table:

```sql
CREATE TABLE students (
  student_id          INT NOT NULL AUTO_INCREMENT,
  student_name        VARCHAR(100) NOT NULL,
  student_addr        VARCHAR(100) NOT NULL,
  student_age         VARCHAR(3)   NOT NULL,
  student_qual        VARCHAR(20)  NOT NULL,
  student_percent     VARCHAR(10)  NOT NULL,
  student_year_passed VARCHAR(10)  NOT NULL,
  PRIMARY KEY (student_id)
);
```

### RDS — MariaDB Instance

| Setting | Value |
|---|---|
| Engine | MariaDB 10.6 |
| Instance class | `db.t4g.micro` |
| Storage | 10 GB gp2 |
| Database name | `studentapp` |
| Username | `arya` |
| Publicly accessible | No |
| Multi-AZ | No |
| Final snapshot | Skipped |

---

## Security Groups

### `my-sg-1` — EC2 Security Group

| Direction | Protocol | Port | Source |
|---|---|---|---|
| Inbound | TCP | 22 (SSH) | `0.0.0.0/0` |
| Inbound | TCP | 80 (HTTP) | `0.0.0.0/0` |
| Inbound | TCP | 8080 (Tomcat) | `0.0.0.0/0` |
| Inbound | TCP | 3306 (MySQL) | `0.0.0.0/0` |
| Outbound | All | All | `0.0.0.0/0` |

### `my-sg-2` — RDS Security Group

| Direction | Protocol | Port | Source |
|---|---|---|---|
| Inbound | TCP | 3306 (MySQL) | `my-sg-1` only |
| Outbound | All | All | `0.0.0.0/0` |

---

## Security Considerations

> ⚠️ This project is built for **learning and development**. Address the following before any production use.

- **`terraform.tfvars` contains a plaintext password** — remove it and use `TF_VAR_db_password` or AWS Secrets Manager
- SSH (port 22) and MySQL (port 3306) are open to `0.0.0.0/0` in `my-sg-1` — restrict to your IP in production
- The RDS username and DB name are hardcoded in `vpc.tf` — move them to variables
- Add the following to `.gitignore`:

```
.terraform/
*.tfstate
*.tfstate.backup
terraform.tfvars
*.pem
```

---

## Troubleshooting

| Issue | Cause | Fix |
|---|---|---|
| App URL not reachable right after apply | `user_data` still running | Wait 3–5 minutes and retry |
| RDS creation timeout | RDS takes ~10 min to provision | Wait or increase default timeout |
| `InvalidKeyPair.NotFound` | Key pair missing in region | Create `mumbai-key` in `ap-south-1` |
| `Error: db_password required` | Variable not set | Export `TF_VAR_db_password` |
| `student` page shows DB connection error | RDS not ready or wrong JDBC config | Check `context.xml` and RDS endpoint |

**Useful commands after deployment:**

```bash
# SSH into the app server
ssh -i mumbai-key.pem ec2-user@<public-ip>

# Check Tomcat logs
tail -f /opt/apache-tomcat-9.0.115/logs/catalina.out

# Check user_data boot log
cat /var/log/cloud-init-output.log

# View Terraform outputs
terraform output
```

---

## Author

**aryakonly** — [github.com/aryakonly](https://github.com/aryakonly)

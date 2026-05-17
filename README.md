# Terratest Infrastructure

Automated testing of Terraform infrastructure code using Terratest — a Go-based testing framework that provisions real AWS resources, validates they work correctly, then destroys them. Proves that infrastructure code is correct before it ever touches production.

---

## Project at a Glance

| | |
|---|---|
| **Tools Used** | Terraform · Terratest · Go · AWS EC2 · VPC |
| **Platform** | AWS (configurable region) |
| **Languages** | HCL (Terraform) · Go (Terratest) |
| **What It Does** | Spins up a real Apache web server on AWS, hits the live URL to confirm it returns HTTP 200 with correct content, then destroys everything — all automated |

## The Problem This Project Solves

Writing Terraform code is easy. Knowing whether that Terraform code actually works is harder. Unit tests for application code are standard practice — every developer knows to test their functions. But infrastructure code often goes untested until it fails in a staging or production environment, at which point debugging is expensive and stressful.

Terratest applies the same principle to infrastructure: write automated tests that provision real resources in a real cloud environment, make assertions about their behaviour, and clean up when done. A failing Terratest means your infrastructure is broken — before anyone deploys it.

This project tests a modular Terraform architecture that provisions a VPC, subnets, security group, and EC2 instance running Apache httpd. The test confirms the web server is reachable and serving the expected content. If `terraform apply` produces a broken server, the test fails and alerts the engineer before the code merges.

## Architecture

```
TEST EXECUTION (Go)
       |
       | go test -v -timeout 30m
       v
TERRATEST (apache_httpd_test.go)
  ├── terraform.InitAndApply()  → runs terraform init + apply
  │          |
  │          v
  │   AWS INFRASTRUCTURE (main/)
  │     ├── module: vpc        → VPC, subnets, security group
  │     └── module: compute    → EC2 instance with Apache httpd
  │                |
  │                v
  │         LIVE WEB SERVER
  │         http://<EC2-PUBLIC-IP>/
  │
  ├── validateApacheHttpdServer()
  │     └── HTTP GET to public URL
  │           asserts: status=200
  │           asserts: body="<h1>Automated Terraform Testing</h1>"
  │           retries: up to 100 times × 3 seconds
  │
  └── defer terraform.Destroy()  → cleans up all resources after test
```

## Repository Structure

```
terratest-infrastructure/
├── main/
│   ├── main.tf          # Root module: calls vpc and compute modules
│   ├── variables.tf     # Input variables (region, etc.)
│   └── outputs.tf       # Outputs public URL for test validation
├── modules/
│   ├── vpc/             # VPC, subnets, security group
│   └── compute/         # EC2 instance with httpd bootstrap
└── test/
    ├── apache_httpd_test.go   # Terratest test file
    ├── go.mod                 # Go module definition
    └── go.sum                 # Dependency checksums
```

## The Test Explained

```go
func TestApacheHttpdServer(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../main",
    }

    // Destroy everything when test ends (pass or fail)
    defer terraform.Destroy(t, terraformOptions)

    // Run terraform init + apply — fails test if any error
    terraform.InitAndApply(t, terraformOptions)

    // Hit the live URL and assert HTTP 200 + correct HTML
    validateApacheHttpdServer(t, terraformOptions)
}
```

The test retries the HTTP check up to 100 times with 3-second intervals — allowing time for EC2 to boot and httpd to start before declaring failure. This is the correct pattern for testing infrastructure that takes time to become healthy.

## How to Reproduce

**Prerequisites:** Go installed, AWS credentials configured, Terraform installed

```bash
# 1. Clone the repository
git clone https://github.com/seyifalode-cmd/terratest-infrastructure.git
cd terratest-infrastructure

# 2. Install Go dependencies
cd test
go mod download

# 3. Run the test (provisions real AWS resources — will incur cost)
go test -v -timeout 30m

# Resources are automatically destroyed after the test completes.
```

## What This Demonstrates

- Infrastructure testing as a first-class engineering practice
- Terratest framework: InitAndApply, Output, HttpGetWithRetry, Destroy
- Modular Terraform architecture (vpc + compute modules)
- Automated resource cleanup via Go's `defer` mechanism
- The difference between "terraform apply succeeds" and "the infrastructure actually works"

---

*Oluwaseyi Michael Falode · Cybersecurity & Cloud Security Engineer · Toronto, ON*

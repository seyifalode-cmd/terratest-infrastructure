package test

import (
	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"testing"
	"time"
)

// An example of a unit test for the Terraform to create an EC2 with 
// an Apache httpd server
func TestApacheHttpdServer(t *testing.T) {

	t.Parallel()

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../main",
	}

	// At the end of the test, run `terraform destroy` to clean up any resources 
	// that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test 
	// if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Check that the app is working as expected
	validateApacheHttpdServer(t, terraformOptions)
}

// Validate the Apache httpd server is working as expected
func validateApacheHttpdServer(t *testing.T, terraformOptions *terraform.Options) {

	// Run `terraform output` to get the url for the webserver
	url := terraform.Output(t, terraformOptions, "Apache-Webserver-Public-URL")

	// Verify the app returns a 200 OK with the text "Automated Terraform Testing"
	expectedStatus := 200
	expectedBody := "<html><body><h1>Automated Terraform Testing</h1></body></html>"
	maxRetries := 10
	timeBetweenRetries := 3 * time.Second
	http_helper.HttpGetWithRetry(t, url, nil, expectedStatus, expectedBody, maxRetries, timeBetweenRetries)

	
}

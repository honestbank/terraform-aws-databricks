package test

import (
	"context"
	"fmt"
	"io/fs"
	"log"
	"os"
	"regexp"
	"strings"
	"testing"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/ec2"
	ec2Types "github.com/aws/aws-sdk-go-v2/service/ec2/types"
	test_structure "github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

const localBackend = `
terraform {
	backend "local" {}
}
`

func setupTest() (string, error) {
	terraformTempDir, errCopying := test_structure.CopyTerragruntFolderToTemp("../", "terratest-")
	if errCopying != nil {
		return "", errCopying
	}

	backendFilePath := fmt.Sprintf("%s/%s", terraformTempDir, "backend.tf")
	errRemoving := os.Remove(backendFilePath)
	if errRemoving != nil {
		return "", errRemoving
	}

	errWritingFile := os.WriteFile(backendFilePath, []byte(localBackend), os.ModeAppend)
	if errWritingFile != nil {
		return "", errWritingFile
	}
	os.Chmod(backendFilePath, fs.FileMode(0777))
	return terraformTempDir, nil
}

const tfWorkspaceEnvVarName = "TF_WORKSPACE"
const targetWorkspace = "test"

func setupVPC() (string, error) {
	initterraformTempDir, errCopying := test_structure.CopyTerragruntFolderToTemp("../", "terratestVPC-")
	if errCopying != nil {
		return "", errCopying
	}
	path, err := os.Getwd()
	if err != nil {
		log.Println(err)
	}
	fmt.Println(path) // for example /home/user
	terraformTempDir := initterraformTempDir + "/vpc-subnet-test-prerequisites"
	backendFilePath := fmt.Sprintf("%s/%s", terraformTempDir, "backend.tf")

	errWritingFile := os.WriteFile(backendFilePath, []byte(localBackend), os.ModeAppend)
	if errWritingFile != nil {
		return "", errWritingFile
	}
	os.Chmod(backendFilePath, fs.FileMode(0777))
	return terraformTempDir, nil
}

func ApplyVPC(t *testing.T) (string, []string, string, string) {
	terraformTempDir, err := setupVPC()
	if err != nil {
		t.Fatalf("Error setting up test :%v", err)
	}
	// defer os.RemoveAll(terraformTempDir)
	log.Printf("Temp folder: %s", terraformTempDir)
	path, err := os.Getwd()
	if err != nil {
		log.Println(err)
	}
	fmt.Println(path) // for example /home/user
	terraformInitOptions := &terraform.Options{
		TerraformDir: terraformTempDir,
		//VarFiles:     []string{"test/terratest.tfvars"},
		VarFiles: []string{path + "/terratest.tfvars"},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": "ap-southeast-1",
			//"TF_LOG":             "TRACE",
		},
		Reconfigure: true,
	}
	terraform.Init(t, terraformInitOptions)
	terraform.WorkspaceSelectOrNew(t, terraformInitOptions, targetWorkspace)
	_, _ = terraform.ApplyAndIdempotentE(t, terraformInitOptions)
	private_subnets := terraform.Output(t, terraformInitOptions, "private_subnet_ids")
	public_subnet := terraform.Output(t, terraformInitOptions, "public_subnet_id")
	vpc_id := terraform.Output(t, terraformInitOptions, "vpc_id")
	fmt.Println(private_subnets)
	var re = regexp.MustCompile(`(?m)^\[(?P<inside_brackets>.+)\]$`)
	var substitution = "${inside_brackets}"
	s := re.ReplaceAllString(private_subnets, substitution)
	subnets_array := strings.Fields(s)
	fmt.Println("[" + strings.Join(subnets_array, ",") + "]")
	return terraformTempDir, subnets_array, public_subnet, vpc_id
}

func TestTerraformCodeInfrastructureInitialCredentials(t *testing.T) {
	VPCTempDir, private_subnets, public_subnet, vpc_id := ApplyVPC(t)
	//Region := "ap-southeast-1"
	terraformTempDir, errSettingUpTest := setupTest()
	if errSettingUpTest != nil {
		t.Fatalf("Error setting up test :%v", errSettingUpTest)
	}
	defer os.RemoveAll(terraformTempDir)
	log.Printf("Temp folder: %s", terraformTempDir)
	path, err := os.Getwd()
	if err != nil {
		log.Println(err)
	}

	tfvars := map[string]interface{}{
		"private_subnet_ids": private_subnets,
		"public_subnet_id":   public_subnet,
		"vpc_id":             vpc_id,
	}
	terraformInitOptions := &terraform.Options{
		TerraformDir: terraformTempDir,
		//VarFiles:     []string{"test/terratest.tfvars"},
		Vars:     tfvars,
		VarFiles: []string{path + "/terratest.tfvars"},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": "ap-southeast-1",
			//"TF_LOG":             "TRACE",
		},
		Reconfigure: true,
	}

	defer destroy(t, VPCTempDir, nil)
	defer destroy(t, terraformTempDir, &tfvars)
	terraform.Init(t, terraformInitOptions)
	terraform.WorkspaceSelectOrNew(t, terraformInitOptions, targetWorkspace)
	terraformValidateOptions := &terraform.Options{
		TerraformDir: terraformTempDir,
		EnvVars: map[string]string{
			tfWorkspaceEnvVarName: targetWorkspace,
		},
	}
	terraform.Validate(t, terraformValidateOptions)
	plan, errApplyingIdempotent := terraform.ApplyAndIdempotentE(t, terraformInitOptions)
	if errApplyingIdempotent != nil {
		t.Logf("Error applying plan: %v", errApplyingIdempotent)
		t.Fail()
	} else {
		t.Log(fmt.Sprintf("Plan worked: %s", plan))
	}

	cfg, err := config.LoadDefaultConfig(context.TODO())
	if err != nil {
		log.Fatal(err)
	}
	client := ec2.NewFromConfig(cfg)
	t.Run("Has Infra", func(t *testing.T) {
		a := assert.New(t)
		filterName := "attachment.vpc-id"
		igwGatewaysOutput, _ := client.DescribeInternetGateways(context.TODO(), &ec2.DescribeInternetGatewaysInput{
			Filters: []ec2Types.Filter{
				{
					Name:   &filterName,
					Values: []string{vpc_id},
				},
			},
		})
		igwGateways := igwGatewaysOutput.InternetGateways
		exists := false
		for _, igw := range igwGateways {
			if *igw.Tags[0].Value == "honest-databricks-igw" {
				exists = true
			}
		}
		a.Equal(true, exists, "IGW not found")

		eipsOutput, err := client.DescribeAddresses(context.TODO(), &ec2.DescribeAddressesInput{
			Filters: []ec2Types.Filter{
				{
					Name:   aws.String("domain"),
					Values: []string{"vpc"},
				},
			},
		})
		if err != nil || eipsOutput == nil {
			t.Fail()
		}
		eips := eipsOutput.Addresses
		exists = false
		for _, eip := range eips {
			if *eip.Tags[0].Value == "honest-databricks-nat" {
				exists = true
			}
		}
		a.Equal(true, exists)

		routetablesOuput, err := client.DescribeRouteTables(context.TODO(), &ec2.DescribeRouteTablesInput{})

		routetables := routetablesOuput.RouteTables
		var privateRouteTable ec2Types.RouteTable
		var publicRouteTable ec2Types.RouteTable
		privateRouteTableExists := false
		publicRouteTableExists := false
		for _, routetable := range routetables {
			if len(routetable.Tags) != 0 {
				if *routetable.Tags[0].Value == "honest-databricks-private" {
					privateRouteTable = routetable
					privateRouteTableExists = true
				}
				if *routetable.Tags[0].Value == "honest-databricks-public" {
					publicRouteTable = routetable
					publicRouteTableExists = true
				}
			}
		}

		a.Equal(true, publicRouteTableExists)
		a.Equal(true, privateRouteTableExists)

		privateRouteTableAssociations := privateRouteTable.Associations
		publicRouteTableAssociations := publicRouteTable.Associations
		privateRouteTableAssociationExists0 := false
		privateRouteTableAssociationExists1 := false
		publicRouteTableAssociationExists := false
		for _, association := range privateRouteTableAssociations {
			if *association.SubnetId == private_subnets[0] {
				privateRouteTableAssociationExists0 = true
			}
			if *association.SubnetId == private_subnets[1] {
				privateRouteTableAssociationExists1 = true
			}
		}
		for _, association := range publicRouteTableAssociations {
			if *association.SubnetId == public_subnet {
				publicRouteTableAssociationExists = true
			}
		}
		a.Equal(true, privateRouteTableAssociationExists0)
		a.Equal(true, privateRouteTableAssociationExists1)
		a.Equal(true, publicRouteTableAssociationExists)

	})

}

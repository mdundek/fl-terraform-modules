package main

import (
    "context"
    "fmt"
    "os"
    "strings"

    "github.com/aws/aws-sdk-go-v2/aws"
    "github.com/aws/aws-sdk-go-v2/config"
    "github.com/aws/aws-sdk-go-v2/service/ec2"
    "github.com/aws/aws-sdk-go-v2/service/ec2/types"
    "github.com/aws/aws-sdk-go-v2/credentials"
    "path/filepath"

    "k8s.io/client-go/kubernetes"
    "k8s.io/client-go/tools/clientcmd"
    // "k8s.io/client-go/rest"
    metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

func main() {
    if len(os.Args) < 2 {
        fmt.Printf("Usage: %s <vpc-id>", os.Args[0])
        os.Exit(1)
    }
    vpcID := os.Args[1]

    // Read credentials from the Kubernetes secret
    // accessKeyID, secretAccessKey, err := getAWSCredsFromK8sSecret("upbound-system", "aws-creds")
    // if err != nil {
    //     fmt.Printf("Unable to load AWS credentials from secret: %v", err)
    //     os.Exit(1)
    // }

    ctx := context.TODO()
    cfg, err := config.LoadDefaultConfig(
        ctx,
        config.WithRegion("us-east-1"),
        config.WithCredentialsProvider(
            credentials.NewStaticCredentialsProvider("", "", ""),
        ),
    )
    if err != nil {
        fmt.Printf("Unable to load AWS SDK config, %v", err)
        os.Exit(1)
    }

    svc := ec2.NewFromConfig(cfg)

    input := &ec2.DescribeSecurityGroupsInput{
        Filters: []types.Filter{
            {
                Name:   aws.String("vpc-id"),
                Values: []string{vpcID},
            },
        },
    }

    result, err := svc.DescribeSecurityGroups(ctx, input)
    if err != nil {
        fmt.Printf("Unable to describe security groups: %v", err)
        os.Exit(1)
    }

    var sgIDs []string
    for _, sg := range result.SecurityGroups {
        // Skip the default security group, cannot delete it
        if sg.GroupName != nil && *sg.GroupName == "default" {
            fmt.Printf("Skipping default security group: %s\n", *sg.GroupId)
            continue
        }
        fmt.Printf("Found Security Group: %s (%s)\n", *sg.GroupName, *sg.GroupId)
        sgIDs = append(sgIDs, *sg.GroupId)
    }

    // Now delete each security group, except the default
    for _, sgID := range sgIDs {
        fmt.Printf("Deleting Security Group: %s\n", sgID)
        _, err := svc.DeleteSecurityGroup(ctx, &ec2.DeleteSecurityGroupInput{
            GroupId: aws.String(sgID),
        })
        if err != nil {
            fmt.Printf("Could not delete security group %s: %v\n", sgID, err)
        } else {
            fmt.Printf("Deleted security group %s\n", sgID)
        }
    }
}

// Parse credentials in AWS INI format
func parseAWSCreds(ini string) (accessKeyID, secretAccessKey string, err error) {
    for _, line := range strings.Split(ini, "\n") {
        if strings.HasPrefix(line, "aws_access_key_id") {
            parts := strings.SplitN(line, "=", 2)
            if len(parts) == 2 {
                accessKeyID = strings.TrimSpace(parts[1])
            }
        }
        if strings.HasPrefix(line, "aws_secret_access_key") {
            parts := strings.SplitN(line, "=", 2)
            if len(parts) == 2 {
                secretAccessKey = strings.TrimSpace(parts[1])
            }
        }
    }
    if accessKeyID == "" || secretAccessKey == "" {
        return "", "", fmt.Errorf("missing keys in credential data")
    }
    return accessKeyID, secretAccessKey, nil
}

func getAWSCredsFromK8sSecret(namespace, secretName string) (string, string, error) {
    // config, err := rest.InClusterConfig()
    home := os.Getenv("HOME")
    kubeconfig := filepath.Join(home, ".kube", "config")

    config, err := clientcmd.BuildConfigFromFlags("", kubeconfig)
    if err != nil {
        return "", "", fmt.Errorf("failed to get in-cluster config: %w", err)
    }
    clientset, err := kubernetes.NewForConfig(config)
    if err != nil {
        return "", "", fmt.Errorf("failed to create kubernetes client: %w", err)
    }
    secret, err := clientset.CoreV1().Secrets(namespace).Get(context.TODO(), secretName, metav1.GetOptions{})
    if err != nil {
        return "", "", fmt.Errorf("failed to get secret: %w", err)
    }
    credentialsB64, ok := secret.Data["credentials"]
    if !ok {
        return "", "", fmt.Errorf("secret missing 'credentials' key")
    }
    // The Kubernetes Go client decodes base64 for you; you can use credentialsB64 as []byte directly.
    credsStr := string(credentialsB64)

    accessKeyID, secretAccessKey, err := parseAWSCreds(credsStr)
    if err != nil {
        return "", "", fmt.Errorf("error parsing credentials: %w", err)
    }
    return accessKeyID, secretAccessKey, nil
}

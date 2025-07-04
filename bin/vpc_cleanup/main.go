package main

import (
    "context"
    "fmt"
    "os"

    "github.com/aws/aws-sdk-go-v2/aws"
    "github.com/aws/aws-sdk-go-v2/config"
    "github.com/aws/aws-sdk-go-v2/service/ec2"
    "github.com/aws/aws-sdk-go-v2/service/ec2/types"
)

func main() {
    if len(os.Args) < 2 {
        fmt.Printf("Usage: %s <vpc-id>", os.Args[0])
        os.Exit(1)
    }
    vpcID := os.Args[1]

    ctx := context.TODO()
    cfg, err := config.LoadDefaultConfig(ctx)
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

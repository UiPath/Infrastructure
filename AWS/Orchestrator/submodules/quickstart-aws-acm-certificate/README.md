# quickstart-aws-acm-certificate
This Quick Start module provides a simple way to create validated public ACM certificates using
either DNS or email validation. The DNS validation for the certificate is automated through custom
lambda 

## Input parameters:
```yaml
    DomainName: my.super.cool.dnsname  # FQDN For the ACM Certificate
    HostedZoneID: XZXZXXXZZZZZZZ  # AWS R53 HostedZone for DNS verification of domain ownership 
    QSS3BucketName: aws-quickstart  # The consuming QuickStart
    QSS3BucketRegion: us-east-1  # The consuming QuickStart 
    QSS3KeyPrefix: !Sub ${QSS3KeyPrefix}submodules/quickstart-aws-acm-certificate/
```

To use e-mail verification of the Domain please leave Hosted Zone ID blank.

# Scenario #1

1) I can identify a few challenges in applying key rotation in the given setup:

- Keys are generated on-prem (BYOK), so rotation requires coordination between the on-prem HSM and AWS KMS.
- Each environment (dev, int, prod) and service (S3, RDS, DDB) has its own key, which increases complexity and maintenance overhead.
- There's a risk of service disruption during alias updates or key transitions.
- Potential compliance issues if some keys or resources are missed during the rotation process.

2) To rotate the keys, I would follow these steps:

1. Generate a new key on the on-prem HSM.
2. Export it securely using the RSA wrapping key provided by AWS.
3. Import it into AWS KMS as a new CMK.
4. Re-point the existing alias to the new CMK.
5. Re-encrypt existing data to use the new key (if required).
6. Deactivate and retire the old key once validated.

3) To monitor resources and ensure compliance, I would use the following AWS services:

- **AWS Config**: Create custom rules to check that each service (S3, RDS, DDB) is using the expected CMK ARN.
- **AWS Security Hub**: Aggregate compliance findings from Config and provide a centralized dashboard.
- **AWS Lambda**: Run a scheduled function that lists resources, fetches their CMK, and compares it to the expected key; notify or log any mismatches.
- **Amazon CloudWatch / EventBridge**: Trigger alerts when sensitive events occur (e.g., key imports, resource creation without CMK, etc.).

4) To securely import external key material, I would follow the AWS Import Key process:

- Create a new CMK in AWS KMS and choose the "External Key Material" option.
- Download the RSA public wrapping key and import token from AWS.
- Encrypt the key material using the on-prem HSM and the wrapping key.
- Upload the encrypted key material and the import token to AWS KMS.

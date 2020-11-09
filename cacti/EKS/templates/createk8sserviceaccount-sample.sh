#!/bin/bash -xe

set -o xtrace

# Install SSM Agent
if ! rpm -qa | grep -qw amazon-ssm-agent; then
    yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
fi

# Install kubectl
curl -o kubectl https://amazon-eks.s3-us-west-2.amazonaws.com/1.13.8/2019-08-14/bin/linux/amd64/kubectl
chmod +x ./kubectl

# Upgrade AWS CLI
curl -O https://bootstrap.pypa.io/get-pip.py
python get-pip.py --user
export PATH=~/.local/bin:$PATH
pip install --upgrade awscli

# Create an OIDC provider for the cluster
ISSUER_URL=$(aws eks describe-cluster \
                    --name ${EKSCluster} \
                    --region ${AWS::Region} \
                    --query cluster.identity.oidc.issuer \
                    --output text )
ISSUER_URL_WITHOUT_PROTOCOL=$(echo $ISSUER_URL | sed 's/https:\/\///g' )
ISSUER_HOSTPATH=$(echo $ISSUER_URL_WITHOUT_PROTOCOL | sed "s/\/id.*//" )
# Grab all certificates associated with the issuer hostpath and save them to files. The root certificate is last
rm *.crt || echo "No files that match *.crt exist"
ROOT_CA_FILENAME=$(openssl s_client -showcerts -connect $ISSUER_HOSTPATH:443 < /dev/null \
                    | awk '/BEGIN/,/END/{ if(/BEGIN/){a++}; out="cert"a".crt"; print > out } END {print "cert"a".crt"}')
ROOT_CA_FINGERPRINT=$(openssl x509 -fingerprint -noout -in $ROOT_CA_FILENAME \
                    | sed 's/://g' | sed 's/SHA1 Fingerprint=//')
aws iam create-open-id-connect-provider \
                    --url $ISSUER_URL \
                    --thumbprint-list $ROOT_CA_FINGERPRINT \
                    --client-id-list sts.amazonaws.com \
                    --region ${AWS::Region} || echo "A provider for $ISSUER_URL already exists"

PROVIDER_ARN="arn:${AWS::Partition}:iam::${AWS::AccountId}:oidc-provider/$ISSUER_URL_WITHOUT_PROTOCOL"

# Update trust relationships of pod execution roles so pods on our cluster can assume them
cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "$PROVIDER_ARN"
      },
      "Action": "sts:AssumeRoleWithWebIdentity"
    }
  ]
}
EOF

aws iam update-assume-role-policy \
          --role-name ${PodExecutionRoleArn} \
          --policy-document file://trust-policy.json \
          --region ${AWS::Region}

cat <<EoF > deployment.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
   name: my-serviceaccount
   namespace: default
   annotations:
     eks.amazonaws.com/role-arn: ${PodExecutionRoleArn}
---
apiVersion: apps/v1
kind: Deployment
spec:
   template:
     spec:
       serviceAccountName: my-serviceaccount
       containers:
       - name: my-pod
         image: ${MyEcrImage}
EoF


aws eks --region ${AWS::Region} update-kubeconfig --name ${EKSCluster}
./kubectl apply -f deployment.yaml
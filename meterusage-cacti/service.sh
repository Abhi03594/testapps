#!/bin/bash
args=("$@")

export EKSName="aws"
export REGION="eu-central-1"
export NAMESPACE="cacti"

initServiceAccount(){
    ISSUER_URL=$(aws eks describe-cluster --name ${EKSName} --region ${REGION} --query cluster.identity.oidc.issuer --output text )
    echo $ISSUER_URL
    ISSUER_URL_WITHOUT_PROTOCOL=$(echo $ISSUER_URL | sed 's/https:\/\///g' )
    ISSUER_HOSTPATH=$(echo $ISSUER_URL_WITHOUT_PROTOCOL | sed "s/\/id.*//" )
    rm *.crt || echo "No files that match *.crt exist"
    ROOT_CA_FILENAME=$(openssl s_client -showcerts -connect $ISSUER_HOSTPATH:443 < /dev/null \
                        | awk '/BEGIN/,/END/{ if(/BEGIN/){a++}; out="cert"a".crt"; print > out } END {print "cert"a".crt"}')
    ROOT_CA_FINGERPRINT=$(openssl x509 -fingerprint -noout -in $ROOT_CA_FILENAME \
                        | sed 's/://g' | sed 's/SHA1 Fingerprint=//')
    aws iam create-open-id-connect-provider \
                        --url $ISSUER_URL \
                        --thumbprint-list $ROOT_CA_FINGERPRINT \
                        --client-id-list sts.amazonaws.com \
                        --region ${REGION} || echo "A provider for $ISSUER_URL already exists"
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    PROVIDER_ARN="arn:aws:iam::$ACCOUNT_ID:oidc-provider/$ISSUER_URL_WITHOUT_PROTOCOL"
    cat > trust-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [{
        "Effect": "Allow",
        "Principal": {
            "Federated": "${PROVIDER_ARN}"
        },
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Condition": {
            "StringEquals": {
                "${ISSUER_URL_WITHOUT_PROTOCOL}:sub": "system:serviceaccount:${NAMESPACE}:cacti"
            }
        }
    }]
}
EOF

    ROLE_NAME=cacti-${EKSName}
    aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document file://trust-policy.json
    cat > iam-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "aws-marketplace:MeterUsage"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
     
EOF
  

    POLICY_ARN=$(aws iam create-policy --policy-name AWSMarketplacePolicy-${EKSName} --policy-document file://iam-policy.json --query Policy.Arn | sed 's/"//g')
    echo ${POLICY_ARN}
    aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn $POLICY_ARN
    echo $ROLE_NAME
    applyServiceAccount $ROLE_NAME
 
}

applyServiceAccount(){
    if [ "$1" == "" ]; then
        ROLE_NAME="${args[1]}"
    else
        ROLE_NAME=$1
    fi
    echo "Role="$ROLE_NAME
    ROLE_ARN=$(aws iam get-role --role-name ${ROLE_NAME} --query Role.Arn --output text)
    kubectl create sa cacti --namespace ${NAMESPACE}
    kubectl annotate sa cacti eks.amazonaws.com/role-arn=$ROLE_ARN --namespace ${NAMESPACE}
    echo "Service Account Created: cacti"
}

$*

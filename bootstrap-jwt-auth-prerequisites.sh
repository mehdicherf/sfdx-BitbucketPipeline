#!/bin/sh
####################################################################################################
#
# FILENAME:     bootstrap-jwt-auth-prerequisites
#
# PURPOSE:      Creates a self-signed SSL certificate in the temp directory of this project.
#               And an encrypted private key in the folder in parameter
#
# DESCRIPTION:  Self-signed SSL certificates (AKA "Server keys") are needed for JWT auth stuff.
#
# INSTRUCTIONS: Execute the following command relative to your project's root directory:  
#               ./dev-tools/make-server-key myAwesomePassword myEnv
#
#
#### FETCH INPUT ###################################################################################
#
if [ -z "$1" ] ; then
    echo "Usage: $0 [PASSWORD] [<ENV_NAME>]" 1>&2
    exit 1
fi
PASSWORD="$1"

ENV="$2"
if [ -z "$2" ] ; then
    ENV="env"
fi

#### CREATE LOCAL VARIABLES ########################################################################
#


COUNTRY_NAME="FR"
STATE="France"
LOCALITY="Paris"
ORGANIZATION_NAME="sfdx"
ORGANIZATIONAL_UNIT="jwt:auth"
COMMON_NAME="jwt.auth.com"
EMAIL="sfdx@jwt.auth"
CERTIFICATE_EXPIRE_DAYS=365

#### CREATE CERTIFICATE AND PRIVATE KEY ############################################################
#
mkdir ./tmp 2>/dev/null
cd tmp
openssl genrsa -des3 -passout pass:x -out server.pass.key 2048 2>/dev/null
openssl rsa -passin pass:x -in server.pass.key -out server.key 2>/dev/null
openssl req -new -key server.key -out server.csr \
            -subj "/C=$COUNTRY_NAME/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION_NAME/OU=$ORGANIZATIONAL_UNIT/CN=$COMMON_NAME/emailAddress=$EMAIL" 2>/dev/null

openssl x509 -req -sha256 -days $CERTIFICATE_EXPIRE_DAYS -in server.csr -signkey server.key -out "$ENV.crt" 2>/dev/null


mkdir ../build 2>/dev/null
mkdir ../certificate 2>/dev/null

openssl aes-256-cbc -salt -e -in server.key -out "${ENV}_server.key.enc" -k $PASSWORD 2>/dev/null
mv "${ENV}_server.key.enc" ../build
mv "$ENV.crt" ../certificate
cd ..
rm -rf tmp
echo "$ENV.crt in the build folder"
echo "${ENV}_server.key.enc created in the certificate folder"
# sfdx-BitbucketPipeline

Sample Bitbucket Pipeline for SFDX, adapted from https://github.com/forcedotcom/sfdx-bitbucket-package


The following steps describe how to set up a pipeline for the following developement and release management process:

![overview](https://github.com/mehdisfdc/sfdx-BitbucketPipeline/blob/master/img/overview.png "Overview")


* On your local machine, make sure you have the Salesforce CLI installed. Check by running `sfdx force --help` and confirm you see the command output. If you don't have it installed you can download and install it from https://developer.salesforce.com/tools/sfdxcli

* Create a Private Key and Self-Signed Digital Certificate for *each* org to authorize: https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_auth_key_and_cert.htm
    * PROD (which is also the Dev Hub)
    * INTEG
    * CI
    * UAT
    
* Authorise each org. using JWT-based flow: Authorize an Org Using the JWT-Based Flow (https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_auth_jwt_flow.htm) For more info on setting up JWT-based auth, see also the Salesforce DX Developer Guide (https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev)

* (Optionnal) Confirm you can perform a JWT-based auth: `sfdx force:auth:jwt:grant --clientid <your_consumer_key> --jwtkeyfile server.key --username <your_username> --setdefaultdevhubusername`

* Then we will encrypt and store the generated server.key in encrypted form. First, generate a key and initialization vector (iv) to encrypt your server.key file locally. The key and iv are used by Bitbucket Pipeplines to decrypt your server key in the build environment. Use a random and long passphrase generated with your password manager:
`openssl enc -aes-256-cbc -k <passphrase here> -P -md sha256 -nosalt`
* Make note of the 'key' and 'iv' values output to the screen. You'll use the values following `key=` and `iv =` to encrypt your 'server.key'.

* Encrypt the 'server.key' using the newly generated key and iv values: Use the key and iv values only once (once per certificate and environment). While you can re-use this pair to encrypt other things, it's considered a security violation to do so. Every time you run the command above, it generates a new key and iv value. You can't regenerate the same pair. If you lose these values, generate new ones and encrypt again.
`mkdir build`
    `openssl enc -nosalt -md sha256 -aes-256-cbc -in JWT/server.key -out build/PROD_server.key.enc -base64 -K <key from above> -iv <iv from above>`
* This step replaces the existing 'server.key' with your encrypted version.
  
* Store the 'key' and 'iv' values in your password manager (in the entry of this environment). You'll use these values in a subsequent step in the Bitbucket Pipeplines UI. These values are considered secret so please treat them as such.

* Clear the terminal history: `history -c`

* From your JWT-based connected app on Salesforce, retrieve the generated 'Consumer Key' from your org.

* Set your Consumer Key in a Bitbucket Pipelines environment variable named `PROD_CONSUMERKEY` using the Bitbucket Pipelines UI (under `Settings > Repository variables`). Set your Username in a Bitbucket Pipelines environment variable named `PROD_USERNAME` using the Bitbucket Pipelines UI. 

* Store the 'key' and 'iv' values used above in Bitbucket Pipelines environment variables named `PROD_AESKEY` and `PROD_IVKEY`, respectively. When finished setting environment variables, the environment variables setup screen should look like the one below.

* IMPORTANT! Delete the 'server.key' file. Don't store the server.key within the project. NEVER commit it!

* Commit the updated 'PROD_server.key.enc' file

* Repeat those step for each environment you need to connect to!
    * PROD (HUB)
    * UAT
    * INTEG
    * CI
    
* Create or re-use a docker image with Salesforce CLI installed, such as:  https://hub.docker.com/r/mehdisfdc/sfdx-cli/dockerfile

* Create and commit the bitbucket-pipelines.yml (https://github.com/mehdisfdc/sfdx-BitbucketPipeline/blob/master/bitbucket-pipelines.yml) file


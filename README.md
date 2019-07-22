# sfdx-BitbucketPipeline


Sample Bitbucket Pipeline for SFDX, adapted from https://github.com/forcedotcom/sfdx-bitbucket-org and https://github.com/forcedotcom/sfdx-bitbucket-package, so that it can be used for CI tasks when using the [Git FLow](https://nvie.com/posts/a-successful-git-branching-model/) branching model on a Salesforce implementation project with DX sources:
* By default on each commit:
   * Control the code quality with Apex PMD
   * Deploy and run tests in a new scratch org
   * Check-only deploy and run tests in the CI sandbox
* When merging into the `develop` branch, deploy to the INTEG sandbox
* When merging into a `release/` branch, deploy to the UAT sandbox
* When merging into the `master` branch, deploy to PROD



The steps bellow describe how to set up a pipeline for this developement and release management process:

![overview](https://github.com/mehdisfdc/sfdx-BitbucketPipeline/blob/master/img/overview.png "Overview")

## Step 0 - Prerequisites

* On your local machine, make sure you have the Salesforce CLI installed. Check by running `sfdx force --help` and confirm you see the command output. If you don't have it installed you can download and install it from https://developer.salesforce.com/tools/sfdxcli

* If you want to test on your local machine, make sure you have the ability to execute shell script.

* Give the right to execute the bootstrap script
```
$ chmod u+x bootstrap-jwt-auth-prerequisites.sh
```

## Step 1 - Create connected app to authenticate with JWT-Based Flow:

* Create a connected app to use the JWT-Based Flow to login (https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_auth_connected_app.htm) (except step 7 and 8, we'll do that later). For more info on setting up JWT-based auth, see also the Salesforce DX Developer Guide (https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev)

* From this JWT-based connected app on Salesforce, retrieve the generated `Consumer Key` from your org.

* Set your Consumer Key in a Bitbucket Pipelines protected environment variable named `PROD_CONSUMERKEY` using the Bitbucket Pipelines UI (under `Settings > Repository variables`). Set your Username in a Bitbucket Pipelines environment variable named `PROD_USERNAME` using the Bitbucket Pipelines UI. 

## Step 2 - Create the certificate and the encrypted private key:
* To generate the certificate and the encrypted private key, execute the script :
```
$ ./bootstrap-jwt-auth-prerequisites.sh <password> <env>
```

* Set your PROD password in a protected Bitbucket Pipelines environment variable named `PROD_KEY_PASSWORD` using the Bitbucket Pipelines UI (under `Settings > Repository variables`).

* Upload the certificate from `./certificate/<env>.crt`. Follow step 7 and 8 from the documentatiion (https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_auth_connected_app.htm)

* Clear the terminal history: `history -c`

* Set your Consumer Key in a Bitbucket Pipelines environment variable named `PROD_CONSUMERKEY` using the Bitbucket Pipelines UI (under `Settings > Repository variables`). Set your Username in a Bitbucket Pipelines environment variable named `PROD_USERNAME` using the Bitbucket Pipelines UI (use an API only user).

* Commit the updated `PROD_server.key.enc` file (you can remove the certificate) from the repo and store it into a shared document library
```
$ git add build/PROD_server.key.enc
$ git commit -m 'add PROD env encrypted server key'
$ git push
```

* (Optionnal) Confirm you can perform a JWT-based auth: `sfdx force:auth:jwt:grant --clientid <your_consumer_key> --jwtkeyfile <your_server_key> --username <your_username> --setdefaultdevhubusername`

## Step 3 - Repeat in each org to connect to from step 1:
* Repeat from step 1 for each environment you need to connect to!
    * PROD (HUB)
    * UAT
    * INTEG
    * CI
    
## Step 4 - Configure Apex PMD:
* Add to your repo a custom-apex-rules.xml ruleset file for Apex PMD, such as https://github.com/mehdisfdc/sfdx-PMDruleset/blob/master/custom-apex-rules.xml

*  Bitbucket Pipelines environment variables named `PMD_MINIMUM_PRIORITY` to trigger a build failure when a high priority issue is found (recommended error threshold: 1)
    
## Step 5 - Create and commit the yml file:
* Create or re-use a docker image with Salesforce CLI installed, such as:  https://hub.docker.com/r/mehdisfdc/sfdx-cli/dockerfile

* Create and commit the bitbucket-pipelines.yml (https://github.com/mehdisfdc/sfdx-BitbucketPipeline/blob/master/bitbucket-pipelines.yml) file


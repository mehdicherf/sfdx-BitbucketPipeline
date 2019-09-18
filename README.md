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

## Step 0 - Prerequisites:

* On your local machine, make sure you have the Salesforce CLI installed. Check by running `sfdx force --help` and confirm you see the command output. If you don't have it installed you can download and install it from https://developer.salesforce.com/tools/sfdxcli

* We will use a script to generate the certificates to use with JWT-based auth, so make sure you have the ability to execute shell script.

* Give the right to execute the bootstrap-jwt-auth script
```
$ chmod u+x bootstrap-jwt-auth-prerequisites.sh
```

## Step 1 - Create connected app to authenticate with JWT-Based Flow:

* Create a connected app to use the JWT-Based Flow to login (https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_auth_connected_app.htm) (except step 7 and 8, we'll do that later). For more info on setting up JWT-based auth, see also the Salesforce DX Developer Guide (https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev)

* From this JWT-based connected app on Salesforce, retrieve the generated `Consumer Key` from your org.

* Set your Consumer Key in a Bitbucket Pipelines **protected** environment variable named `PROD_CONSUMERKEY` using the Bitbucket Pipelines UI (under `Settings > Repository variables`). Set your Username in a Bitbucket Pipelines environment variable named `PROD_USERNAME` using the Bitbucket Pipelines UI. 

## Step 2 - Create the certificate and the encrypted private key:
* To generate the certificate and the encrypted private key, execute the script. Make sure to use a strong password (i.e. long, unique, and randomly-generated).
```
$ ./bootstrap-jwt-auth-prerequisites.sh <password> <env>
```
Exemple: `./bootstrap-jwt-auth-prerequisites.sh put_here_your_strong_password PROD`

* Set your PROD password in a **protected** Bitbucket Pipelines environment variable named `PROD_KEY_PASSWORD` using the Bitbucket Pipelines UI (under `Settings > Repository variables`).

* Upload the certificate from `./certificate/<env>.crt`. Follow step 7 and 8 from the documentation (https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_auth_connected_app.htm)

* Clear the terminal history: `history -c && clear`

* Set your Consumer Key in a Bitbucket Pipelines environment variable named `PROD_CONSUMERKEY` using the Bitbucket Pipelines UI (under `Settings > Repository variables`). Set your Username in a Bitbucket Pipelines environment variable named `PROD_USERNAME` using the Bitbucket Pipelines UI (use an API only user).

* Commit the `PROD_server.key.enc` file from the `build` folder and store it into a shared document library of your repo. The `certificate` folder (containing the .crt file you uploaded in Salesforce) can be deleted.
```
$ git add build/PROD_server.key.enc
$ git commit -m 'add PROD env encrypted server key'
$ git push
```

## Step 3 - Repeat in each org to connect to from step 1:
* Repeat from step 1 for each environment you need to connect to!
    * PROD
    * UAT
    * INTEG
    * CI
    
## Step 4 - Configure Apex PMD:
* Add to your repo a custom-apex-rules.xml ruleset file for Apex PMD. Here is a sample ruleset you could use: https://github.com/mehdisfdc/sfdx-PMDruleset/blob/master/custom-apex-rules.xml

* Create a Bitbucket Pipelines environment variable named `PMD_VERSION` to specify the PMD version to use (such as `6.17.0` for instance). PMD releases are listed here: https://github.com/pmd/pmd/releases

* Create a Bitbucket Pipelines environment variable named `PMD_MINIMUM_PRIORITY` to trigger a build failure when a high priority issue is found (recommended error threshold: 2)
    
## Step 5 - Create and commit the yml file:
* Create or re-use a docker image with Salesforce CLI installed, such as:  https://hub.docker.com/r/mehdisfdc/sfdx-cli/dockerfile

* Create and commit the bitbucket-pipelines.yml (https://github.com/mehdisfdc/sfdx-BitbucketPipeline/blob/master/bitbucket-pipelines.yml) file


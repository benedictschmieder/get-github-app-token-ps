# Create GitHub App Token

GitHub Action for creating a GitHub App installation access token using PowerShell.

## Usage

In order to use this action, you need to:

1. [Register new GitHub App](https://docs.github.com/apps/creating-github-apps/setting-up-a-github-app/creating-a-github-app)
2. [Store the App's ID in your repository environment variables](https://docs.github.com/actions/learn-github-actions/variables#defining-configuration-variables-for-multiple-workflows) (example: `APP_ID`)
3. [Store the App's private key in your repository secrets](https://docs.github.com/actions/security-guides/encrypted-secrets?tool=webui#creating-encrypted-secrets-for-a-repository) (example: `PRIVATE_KEY`)

> [!IMPORTANT]
> An installation access token expires after 1 hour.

### Trigger workflow in another repository

> [!NOTE]
> The GitHub App needs the permission "Actions: Read and Write" in order for the below example to work

```yaml
name: Trigger workflow in another repository
on:
  push:
    branches:
      - main

jobs:
  trigger-deployment:
    runs-on: ubuntu-latest
    steps:
      - name: Generate access token
        uses: benedictschmieder/get-github-app-token-ps@v1
        id: app-token
        with:
          app-id: ${{ vars.APP_ID }}
          private-key: ${{ secrets.PRIVATE_KEY }}

      - name: Trigger action in another repository
        run: gh workflow run --repo organization/another_repository deploy.yml
        env:
          GH_TOKEN: ${{ steps.app-token.outputs.token }}
```

## Inputs

### `app-id`

**Required:** GitHub App ID.

### `private-key`

**Required:** GitHub App private key. 

## Outputs

### `token`

GitHub App installation access token.

## How it works

The action uses a PowerShell backend to create an installation access token for a given GitHub app. A PowerShell backend has the advantage, that the access token can also be retrieved and then used manually by executing the PowerShell code directly on a client. This is useful in development- or debugging scenarios.  
The code works by:

1. Using the PowerShell Module [jwtPS by DigitalAXPP](https://github.com/DigitalAXPP/jwtPS) to generate a short-lived JWT token.
2. The JWT token is then used to authenticate against GitHubs [/app/installations API](https://docs.github.com/en/rest/apps/apps?apiVersion=2022-11-28#create-an-installation-access-token-for-an-app) to get the access token.

> [!NOTE]
> Installation permissions can differ from the app's permissions they belong to. Installation permissions are set when an app is installed on an account. When the app adds more permissions after the installation, an account administrator will have to approve the new permissions before they are set on the installation.

## License

[MIT](LICENSE)

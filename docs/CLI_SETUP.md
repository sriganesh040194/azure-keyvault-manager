# Azure CLI Authentication Setup

This guide explains how to set up Azure CLI authentication for the Azure Key Vault Manager application.

## Why CLI Authentication?

The application uses Azure CLI authentication instead of Azure AD app registration because:

- **No App Registration Required**: You don't need permissions to create Azure AD applications
- **Simplified Setup**: Uses your existing Azure credentials
- **Direct Access**: Leverages Azure CLI's secure authentication flow
- **No Token Management**: Azure CLI handles all authentication tokens

## Prerequisites

1. **Azure CLI**: Version 2.0 or later must be installed
2. **Azure Account**: Active Azure subscription with Key Vault permissions
3. **Permissions**: Key Vault Contributor role or appropriate access policies

## Step 1: Install Azure CLI

### Windows
```powershell
# Using winget
winget install Microsoft.AzureCLI

# Or download from: https://aka.ms/installazurecliwindows
```

### macOS
```bash
# Using Homebrew
brew install azure-cli

# Or using installer from: https://aka.ms/installazureclimacos
```

### Linux (Ubuntu/Debian)
```bash
# Get Microsoft signing key
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

### Verification
```bash
# Verify installation
az --version
```

## Step 2: Login to Azure

### Interactive Login
```bash
# Launch browser-based authentication
az login

# If you have multiple tenants, specify the tenant
az login --tenant YOUR_TENANT_ID
```

### Device Code Login (for restricted environments)
```bash
# Use device code flow
az login --use-device-code
```

### Service Principal Login (for automation)
```bash
# Using service principal
az login --service-principal -u APP_ID -p PASSWORD --tenant TENANT_ID
```

## Step 3: Verify Authentication

### Check Current Account
```bash
# Show current account details
az account show

# Expected output includes:
# - User email/name
# - Subscription name and ID
# - Tenant ID
# - Environment (AzureCloud)
```

### List Subscriptions
```bash
# See all available subscriptions
az account list --output table
```

### Set Default Subscription (if needed)
```bash
# Set specific subscription as default
az account set --subscription "Your Subscription Name"

# Or use subscription ID
az account set --subscription "12345678-1234-1234-1234-123456789012"
```

## Step 4: Verify Key Vault Access

### Test Key Vault Permissions
```bash
# List Key Vaults (this verifies you have access)
az keyvault list --output table

# If this fails, you need Key Vault permissions
```

### Check Required Permissions
You need at least one of the following:
- **Key Vault Contributor** role on subscription/resource group
- **Key Vault Administrator** role (newer RBAC model)
- Custom access policies on specific Key Vaults

### Grant Permissions (if needed)
```bash
# Add Key Vault Contributor role (requires Owner/User Access Administrator role)
az role assignment create \
  --assignee your-email@domain.com \
  --role "Key Vault Contributor" \
  --scope "/subscriptions/YOUR_SUBSCRIPTION_ID"
```

## Step 5: Test CLI Operations

### Basic Key Vault Operations
```bash
# List Key Vaults
az keyvault list --query "[].{Name:name, Location:location, ResourceGroup:resourceGroup}" --output table

# Show Key Vault details
az keyvault show --name YOUR_KEYVAULT_NAME

# List secrets (if you have access)
az keyvault secret list --vault-name YOUR_KEYVAULT_NAME --output table
```

## Troubleshooting

### Common Issues

#### "az: command not found"
- Azure CLI is not installed or not in PATH
- **Solution**: Reinstall Azure CLI and restart terminal

#### "Please run 'az login' to setup account"
- Not authenticated with Azure CLI
- **Solution**: Run `az login` and follow prompts

#### "Insufficient privileges to complete the operation"
- Missing Key Vault permissions
- **Solution**: Contact Azure administrator for Key Vault access

#### "The subscription ... doesn't exist"
- Wrong subscription selected
- **Solution**: Use `az account list` and `az account set`

#### "AADSTS50020: User account ... from identity provider ... does not exist in tenant"
- Signing in to wrong tenant
- **Solution**: Use `az login --tenant YOUR_TENANT_ID`

### Advanced Troubleshooting

#### Clear Azure CLI Cache
```bash
# Clear cached credentials
az account clear

# Login again
az login
```

#### Debug Mode
```bash
# Run commands with debug output
az keyvault list --debug
```

#### Check Token Expiration
```bash
# Get access token (for debugging)
az account get-access-token --scope https://vault.azure.net/.default
```

## Security Best Practices

### Account Security
- Use multi-factor authentication (MFA)
- Regularly rotate passwords/keys
- Use conditional access policies when possible

### CLI Security
- Keep Azure CLI updated
- Don't share CLI sessions
- Use `az logout` when finished
- Secure your development environment

### Key Vault Security
- Use RBAC instead of access policies when possible
- Follow principle of least privilege
- Enable Key Vault logging and monitoring
- Use network restrictions when appropriate

## Application Integration

Once Azure CLI is set up and authenticated:

1. **Start the Application**: The app will automatically detect Azure CLI authentication
2. **Check Status**: The login screen shows your authentication status
3. **Verify Permissions**: The app validates Key Vault access
4. **Begin Managing**: Start managing Key Vaults once validated

### Status Indicators

The application displays:
- ✅ **Authentication**: Signed in status
- ✅ **CLI Version**: Installed Azure CLI version
- ✅ **Subscription**: Current subscription name
- ✅ **Permissions**: Key Vault access validation

### Session Management

- **Automatic Validation**: App checks CLI authentication every 5 minutes
- **Session Timeout**: Follows Azure CLI token expiration
- **Re-authentication**: Automatically prompts for login when needed

## Multiple Environments

### Development vs Production
```bash
# Development environment
az login --tenant DEV_TENANT_ID
az account set --subscription "Development Subscription"

# Production environment (use separate CLI session)
az login --tenant PROD_TENANT_ID
az account set --subscription "Production Subscription"
```

### Multiple Accounts
```bash
# Login with different account
az logout
az login --username different-user@domain.com
```

## Automation Scenarios

### CI/CD Integration
```bash
# Service principal for automation
az login --service-principal \
  --username $SERVICE_PRINCIPAL_ID \
  --password $SERVICE_PRINCIPAL_SECRET \
  --tenant $TENANT_ID
```

### Script Authentication
```bash
#!/bin/bash
# Check if already logged in
if ! az account show >/dev/null 2>&1; then
    echo "Please login to Azure CLI"
    az login
fi

# Verify Key Vault access
if ! az keyvault list >/dev/null 2>&1; then
    echo "No Key Vault access found"
    exit 1
fi

echo "Azure CLI setup complete"
```

## Additional Resources

- [Azure CLI Documentation](https://docs.microsoft.com/en-us/cli/azure/)
- [Azure Key Vault Documentation](https://docs.microsoft.com/en-us/azure/key-vault/)
- [Azure RBAC Documentation](https://docs.microsoft.com/en-us/azure/role-based-access-control/)
- [Troubleshooting Azure CLI](https://docs.microsoft.com/en-us/cli/azure/troubleshooting)
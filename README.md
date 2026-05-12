# Dependencies

Choose either method to install terraform

## Install tofuenv
```bash
git clone https://github.com/tofuutils/tofuenv.git ~/.tofuenv
export PATH="$HOME/.tofuenv/bin:$PATH"
tofuenv --version
```

Install opentofu

```bash
tofuenv install latest
# or specific version
tofuenv install 1.10.2
# list/use installed versions
tofuenv list
tofuenv use 1.10.2
tofu version
```

## Mise
```bash
brew install mise # mac
curl https://mise.run | sh # linux
```

Add to your `~/.*rc` file
```bash
eval "$(mise activate bash)" # bash
eval "$(mise activate zsh)" # zsh
```

Install OpenTofu
```bash
mise use -g opentofu@latest
mise use -g opentofu@1.10.2
```

Common Commands
```bash
# list installed tools
mise ls

# install everything from `mise.toml`
mise install

# upgrade tools
mise upgrade

# show active versions
mise current

# show installation locations
mise which <tool>

# check config
mise config

# check mise health
mise doctor
```

### Install Common Packages
```bash
# To use pipx packages with mise, you need to install pipx first:
mise use pipx@latest
mise use opentofu
mise use kubectl
mise use helm
mise use azure-cli
mise use terraform-docs
```

# Create Azure Serivce Principal

```bash
export ARM_CLIENT_ID=...
export ARM_CLIENT_SECRET=...
export ARM_SUBSCRIPTION_ID=...
export ARM_TENANT_ID=...

tofu plan
```

# Private AKS Cluster Example

https://registry.terraform.io/modules/Azure/avm-res-containerservice-managedcluster/azurerm/latest/examples/private# aks-terraform

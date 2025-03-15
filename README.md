## Prerequisites
### (Optionnal) Terraform
- `terraform`
```shell
# Enter root session
sudo -i

# Enter your sudo password
cat > /etc/apt/apt.conf.d/99proxy <<ENDMSG
Acquire::http::proxy::apt.releases.hashicorp.com "$HTTP_PROXY";
Acquire::https::proxy::apt.releases.hashicorp.com "$HTTPS_PROXY";
ENDMSG

# Exit the root session
exit

# Add keyring
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add repo
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Install terraform
sudo apt update && sudo apt install terraform
```

### Ansible Manager

Add it to your PATH
```shell
# No root privilege necessary

mkdir -p "$HOME/.local/bin"
if [ -d "$HOME/.local/bin" ] && ! $(echo "$PATH" | grep -oEq "$HOME/.local/bin") ; then
    echo "export PATH='\$HOME/.local/bin:\$PATH';" >> ~/.bashrc
    source ~/.bashrc
fi
install ansible-manager "$HOME/.local/bin/"

# or

# With root privilege

# export PATH=$PATH:$PWD:/usr/local/bin
# sudo install ansible-manager /usr/local/bin/
```

### Github Credentials

Add your creds in env vars to ease management
```shell
cat >> ~/.bashrc <<ENDMSG
export GITHUB_USER=me
export GITHUB_TOKEN=ghp_XXXXXXXXXXXXXXXXXXX
ENDMSG
source ~/.bashrc
```



### Creating repository

Just make sure to put all secrets inside a `vault` directory and then execute the following commands

```shell
# You must be at the root of the git repo

rootpath=$(pwd)

cd ansible
# Encrypt the secrets
ansible-manager -e
```

#### Using terraform to create the remote Github Project repository

```shell
# You must go to github/terraform/ in the git repo

cd github/terraform
terraform init
terraform apply
```

 #### Creating local git and push to remote

```shell
# You must be at the root of the git repo

cd ${rootpath:-$(pwd)}
rm -rf .git
git init -b dev
git remote add origin https://$GITHUB_USER:$GITHUB_TOKEN@github.com/wasoeki/deploy-weples-server.git
cd ansible
ansible-manager -e
cd ..
git add .
git add **\.enc -f
git commit -m "init"
git branch --set-upstream-to=origin/dev dev
git pull --rebase
git push --set-upstream origin dev
```

### Decrypting repository

```shell
# You must be at the root of the git repo
cd ansible
# Ask a collegue to get the correct passfile inside your /tmp directory
cp /tmp/.*.pass .

# Decrypt the secrets
ansible-manager -d
```
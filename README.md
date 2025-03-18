## Prerequisites
- `expect`
- `vagrant`
- `pwgen`

### Custom functions

Copy the content of a file to the clipboard
```shell
echo "copy(){ cat \$1 | xclip -selection c; };" >> ~/.bashrc
source ~/.bashrc
```

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

### Secrets Manager

Add it to your PATH
```shell
# No root privilege necessary
# You must be at the root of the git repo

mkdir -p "$HOME/.local/bin"
if [ -d "$HOME/.local/bin" ] && ! $(echo "$PATH" | grep -oEq "$HOME/.local/bin") ; then
    echo "export PATH='\$HOME/.local/bin:\$PATH';" >> ~/.bashrc
    source ~/.bashrc
fi
install secrets-manager "$HOME/.local/bin/"

# or

# With root privilege
# You must be at the root of the git repo

# export PATH=$PATH:$PWD:/usr/local/bin
# sudo install secrets-manager /usr/local/bin/
```

### Ansible Manager

Add it to your PATH
```shell
# No root privilege necessary
# You must be at the root of the git repo

mkdir -p "$HOME/.local/bin"
if [ -d "$HOME/.local/bin" ] && ! $(echo "$PATH" | grep -oEq "$HOME/.local/bin") ; then
    echo "export PATH='\$HOME/.local/bin:\$PATH';" >> ~/.bashrc
    source ~/.bashrc
fi
cd ansible
install ansible-manager "$HOME/.local/bin/"

# or

# With root privilege
# You still must be at the root of the git repo

# export PATH=$PATH:$PWD:/usr/local/bin
# cd ansible
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

Just make sure to put all secrets inside a `vault` (for ansible) or a `secrets` directory and then execute the following commands

```shell
# You must be at the root of the git repo
rootpath=$(pwd)

# To encrypt github specific secrets
secrets-manager -e -t github

# Then ansible specific secrets
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
# Ask a collegue to get the correct pass file inside your /tmp directory
cp /tmp/.deploy-weples-server.secrets.pass .
secrets-manager -d -t github

cd ansible
# Ask a collegue to get the correct passfiles inside your /tmp directory
cp /tmp/.*.pass .

# Decrypt the secrets
ansible-manager -d
```

### Common manual command lines

#### First SSH connection
Get necessary vars
```shell
# You must be at the root of the git repo
cd ansible
# Establish first ssh connection
REMOTE_USER="$(yq '.remote_user' environments/all/group_vars/all/main.yml | tr -d '"')"
user=${REMOTE_USER:-user}
PASS="$(pwgen 128 1 | base64 | tr -d '[:blank:]\n')"
echo "$PASS" > ".${user}.${ENV}.pass"
chmod 600 ".${user}.${ENV}.pass"
SPECHAR_ENC_PASS="$(cat .${user}.${ENV}.pass | openssl passwd -6 --stdin)"
enc_pass="$(printf '%q' "${SPECHAR_ENC_PASS}")"

IP_ADDR=$(yq '.webui.hosts.'$ENV'.ansible_host' environments/$ENV/hosts.yml | tr -d '"')
```

One liner to create user (not working for the password because of `expect` not handling special chars like `$` inside the `spawn` command line)
```shell
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$IP_ADDR"
expect << EOF
  spawn ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no -o StrictHostKeyChecking=accept-new root@${IP_ADDR:-127.0.0.1} "sh -c 'useradd -m -d /home/${user} -s /bin/bash -p ${enc_pass} ${user}; mkdir -p /home/${user}/.ssh; curl https://raw.githubusercontent.com/hashicorp/vagrant/refs/heads/main/keys/vagrant.pub > /home/${user}/.ssh/authorized_keys; chown -R ${user}:${user} /home/${user}/.ssh; chmod 700 /home/${user}/.ssh; chmod 600 /home/${user}/.ssh/authorized_keys; usermod -a -G sudo ${user}'"
  expect "password"
  send "$(cat .${ENV}.pass)\r"
  expect eof
EOF
```
Remove the new user
```shell
expect << EOF
  spawn ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no -o StrictHostKeyChecking=accept-new root@${IP_ADDR:-127.0.0.1} "sh -c 'userdel -r ${user}'"
  expect "password"
  send "$(cat .${ENV}.pass)\r"
  expect eof
EOF
```

Via script to create user
```shell
# You must be at the root of the git repo
cd ansible
# Establish first ssh connection
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$IP_ADDR"
expect << EOF
  spawn scp -o PreferredAuthentications=password -o PubkeyAuthentication=no -o StrictHostKeyChecking=accept-new scripts/newuser root@${IP_ADDR:-127.0.0.1}:/bin/
  expect "password"
  send "$(cat .${ENV}.pass)\r"
  expect eof
EOF
expect << EOF
  spawn ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no -o StrictHostKeyChecking=accept-new root@${IP_ADDR:-127.0.0.1} "newuser -u ${user} -p ${enc_pass}"
  expect "password"
  send "$(cat .${ENV}.pass)\r"
  expect eof
EOF
```

#### Test SSH connection with new user
```shell
copy ".${user}.${ENV}.pass"
ssh -o IdentitiesOnly=yes -i ~/.vagrant.d/insecure_private_key "${user}@${IP_ADDR:-127.0.0.1}" -t sudo -s
# Then paste the content of your clipboard (Ctrl+Maj+V)
```
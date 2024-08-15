
### Create Public Key Infrastructure (PKI, aka x509) and OpenVPN Server

`docker exec instance_builder bash -c "ansible-playbook -v -i vpn/inventory.ini vpn/openvpn.yml"`

### Step 1
The first step in this tutorial is to install OpenVPN and Easy-RSA. Easy-RSA is a public key infrastructure
(PKI) management tool that you will use on the OpenVPN Server to generate a certificate request that you will
then verify and sign on the CA Server.
To start off, update your OpenVPN Server’s package index and install OpenVPN and Easy-RSA. Both packages are
available in Ubuntu’s default repositories, so you can use apt for the installation:

```commandline
sudo apt update
sudo apt install -y openvpn easy-rsa
```

Next you will need to create a new directory on the OpenVPN Server as your non-root user called ~/easy-rsa:

`mkdir ~/easy-rsa`

Now you will need to create a symlink from the easyrsa script that the package installed into the ~/easy-rsa
directory that you just created:

`ln -fs /usr/share/easy-rsa/* ~/easy-rsa/`

Finally, ensure the directory’s owner is your non-root sudo user and restrict access to that user using chmod:

```commandline
sudo chown "${USER}" ~/easy-rsa
chmod 700 ~/easy-rsa
```

### Step 2
Before you can create your OpenVPN server’s private key and certificate, you need to create a local Public Key
Infrastructure directory on your OpenVPN server. You will use this directory to manage the server and clients
certificate requests instead of making them directly on your CA server.

To build a PKI directory on your OpenVPN server, you’ll need to populate a file called vars with some default
values. First you will cd into the easy-rsa directory, then you will create and edit the vars file using nano
or your preferred text editor.

```commandline
rm -f ~/easy-rsa/vars
touch ~/easy-rsa/vars
echo "set_var EASYRSA_REQ_COUNTRY    \"US\""                       >> ~/easy-rsa/vars
echo "set_var EASYRSA_REQ_PROVINCE   \"NewYork\""                  >> ~/easy-rsa/vars
echo "set_var EASYRSA_REQ_CITY       \"New York City\""            >> ~/easy-rsa/vars
echo "set_var EASYRSA_REQ_ORG        \"DigitalOcean\""             >> ~/easy-rsa/vars
echo "set_var EASYRSA_REQ_EMAIL      \"ipsharaev@gmail.com\""      >> ~/easy-rsa/vars
echo "set_var EASYRSA_REQ_OU         \"Community\""                >> ~/easy-rsa/vars
echo "set_var EASYRSA_ALGO           \"ec\""                       >> ~/easy-rsa/vars
echo "set_var EASYRSA_DIGEST         \"sha512\""                   >> ~/easy-rsa/vars
```

### Step 3
Once you have populated the vars file you can proceed with creating the PKI directory. To do so, run the easyrsa
script with the init-pki option. Although you already ran this command on the CA server as part of the prerequisites,
it’s necessary to run it here because your OpenVPN server and CA server have separate PKI directories:

```commandline
cd ~/easy-rsa
./easyrsa --batch init-pki
```

### Step 4
Now you’ll call the easyrsa with the gen-req option followed by a Common Name (CN) for the machine. The CN can be
anything you like but it can be helpful to make it something descriptive. Throughout this tutorial, the OpenVPN
Server’s CN will be server. Be sure to include the nopass option as well. Failing to do so will password-protect
the request file which could lead to permissions issues later on.

```commandline
cd ~/easy-rsa
./easyrsa --batch gen-req server nopass
sudo cp ~/easy-rsa/pki/private/server.key /etc/openvpn/server/
```

### Step 5
Building CA
```commandline
cd ~/easy-rsa
./easyrsa --batch build-ca nopass
```

### Step 6
Signing the OpenVPN Server’s Certificate Request

```commandline
cd ~/easy-rsa
./easyrsa --batch sign-req server server
sudo cp ~/easy-rsa/{pki/ca.crt,pki/issued/server.crt} /etc/openvpn/server
```

### Step 7
Generating a Client Certificate and Key Pair

```commandline
cd ~/easy-rsa
/usr/sbin/openvpn --genkey --secret ta.key
sudo cp ta.key /etc/openvpn/server
```

### Testing ssh connection to instance

```commandline
docker run --rm --volume "./vpn:/code/vpn" -it ghcr.io/djoongaar/terraform bash
ssh -i vpn/.ssh/id_rsa instance_public_ip
```

### Checking OpenCPN Server status

```commandline
docker run --rm --volume "./vpn:/code/vpn" -it ghcr.io/djoongaar/terraform bash -c "sudo systemctl status openvpn-server@server.service"
```

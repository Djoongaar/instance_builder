# Step 1
# The first step in this tutorial is to install OpenVPN and Easy-RSA. Easy-RSA is a public key infrastructure
# (PKI) management tool that you will use on the OpenVPN Server to generate a certificate request that you will
# then verify and sign on the CA Server.
# To start off, update your OpenVPN Server’s package index and install OpenVPN and Easy-RSA. Both packages are
# available in Ubuntu’s default repositories, so you can use apt for the installation:

sudo apt update
sudo apt install -y openvpn easy-rsa

# Next you will need to create a new directory on the OpenVPN Server as your non-root user called ~/easy-rsa:

mkdir ~/easy-rsa;

# Now you will need to create a symlink from the easyrsa script that the package installed into the ~/easy-rsa
# directory that you just created:

ln -s /usr/share/easy-rsa/* ~/easy-rsa/;

# Finally, ensure the directory’s owner is your non-root sudo user and restrict access to that user using chmod:

sudo chown "${USER}" ~/easy-rsa;
chmod 700 ~/easy-rsa;

# Step 2
# Before you can create your OpenVPN server’s private key and certificate, you need to create a local Public Key
# Infrastructure directory on your OpenVPN server. You will use this directory to manage the server and clients
# certificate requests instead of making them directly on your CA server.

# To build a PKI directory on your OpenVPN server, you’ll need to populate a file called vars with some default
# values. First you will cd into the easy-rsa directory, then you will create and edit the vars file using nano
# or your preferred text editor.

touch ~/easy-rsa/vars;
echo "set_var EASYRSA_ALGO \"ec\"" >> ~/easy-rsa/vars;
echo "set_var EASYRSA_DIGEST \"sha512\"" >> ~/easy-rsa/vars;

# Step 3
# Once you have populated the vars file you can proceed with creating the PKI directory. To do so, run the easyrsa
# script with the init-pki option. Although you already ran this command on the CA server as part of the prerequisites,
# it’s necessary to run it here because your OpenVPN server and CA server have separate PKI directories:

cd ~/easy-rsa;
./easyrsa --batch init-pki;

# Step 4
# Now you’ll call the easyrsa with the gen-req option followed by a Common Name (CN) for the machine. The CN can be
# anything you like but it can be helpful to make it something descriptive. Throughout this tutorial, the OpenVPN
# Server’s CN will be server. Be sure to include the nopass option as well. Failing to do so will password-protect
# the request file which could lead to permissions issues later on.

cd ~/easy-rsa;
./easyrsa --batch gen-req server nopass;
sudo cp ~/easy-rsa/pki/private/server.key /etc/openvpn/server/;

# Step 5
# Building CA
cd ~/easy-rsa;
./easyrsa --batch build-ca nopass

# Step 6
# Signing the OpenVPN Server’s Certificate Request

cd ~/easy-rsa;
./easyrsa --batch sign-req server server;
sudo cp ~/easy-rsa/{pki/ca.crt,pki/issued/server.crt} /etc/openvpn/server;

# Step 7
# Generating a Client Certificate and Key Pair

cd ~/easy-rsa;
/usr/sbin/openvpn --genkey --secret ta.key;
sudo cp ta.key /etc/openvpn/server

# Step 8
# Generating a Client Certificate and Key Pair
# Although you can generate a private key and certificate request on your client machine and then send it to the CA to
# be signed, this guide outlines a process for generating the certificate request on the OpenVPN server. The benefit of
# this approach is that we can create a script that will automatically generate client configuration files that contain
# all of the required keys and certificates. This lets you avoid having to transfer keys, certificates, and configuration
# files to clients and streamlines the process of joining the VPN.
# We will generate a single client key and certificate pair for this guide. If you have more than one client, you can
# repeat this process for each one. Please note, though, that you will need to pass a unique name value to the script
# for every client. Throughout this tutorial, the first certificate/key pair is referred to as client1.
# Get started by creating a directory structure within your home directory to store the client certificate and key files

mkdir -p ~/client-configs/keys;
chmod -R 700 ~/client-configs;

cd ~/easy-rsa;
./easyrsa --batch gen-req eugene nopass;             # Generating key and request
cp pki/private/eugene.key ~/client-configs/keys/;    # Copy key to client-config dir
./easyrsa --batch sign-req client eugene;
cp pki/issued/eugene.crt ~/client-configs/keys/;
cp pki/ca.crt ~/client-configs/keys/;
cp ~/ta.key ~/client-configs/keys/;

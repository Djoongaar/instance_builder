## Project helps to set up and configure OpenVPN Server

### To create the whole Infrastructure just run: 
```commandline
    ./run --create 
```
This command will:
* create micro Instance on AWS EC2 using Terraform
* set up and configure Public Key Infrastructure (PKI, aka x509)
* install and configure OpenVPN Server
* create default OpenVPN clients configurations 
* make all network configurations for NAT 
* creates default admin user and *.ovpn config
* create Firewall rules

### To create a new OpenVPN client:
```commandline
    ./run --add-client <new_client_name>
```

### To revoke users certificate:
```commandline

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

### Check current connections
```commandline
sudo cat /var/log/openvpn/openvpn-status.log | grep CLIENT_LIST
```
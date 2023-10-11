# Use the base image (ceph/daemon) to build the image
FROM quay.io/ceph/daemon:latest-reef

# Install necessary packages
RUN dnf -y update && dnf install -y openssh-server


# Generate SSH keys for cephadm
RUN ssh-keygen -t ecdsa -f /root/.ssh/ssh_host_ecdsa_key -N ""
RUN ssh-keygen -t ed25519 -f /root/.ssh/ssh_host_ed25519_key -N ""
RUN ssh-keygen -t rsa -f /root/.ssh/ssh_host_rsa_key -N ""

RUN cp /root/.ssh/ssh_host_rsa_key.pub /root/.ssh/authorized_keys
RUN cp -r /root/.ssh/* /etc/ssh/


# Disable password authentication
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config

# Expose the SSH port
EXPOSE 22
# Path: docker-compose.yml
WORKDIR /
ENTRYPOINT [ "/bin/sh", "-c"]

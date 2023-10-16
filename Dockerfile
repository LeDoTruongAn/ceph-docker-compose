# Use the base image (ceph/daemon) to build the image
FROM quay.io/ceph/ceph:v18.2.0

# Install necessary packages
RUN dnf -y update && dnf install -y openssh-server s3cmd

# Install the Docker package
RUN  dnf install -y --skip-broken docker || true

# Install the Chrony package
RUN yum -y install chrony

# Copy your Chrony configuration file into the container (if needed)
COPY conf/chrony.conf /etc/chrony/chrony.conf

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

# Expose the NTP port (123)
EXPOSE 123/udp
# Path: docker-compose.yml

WORKDIR /

ENTRYPOINT ["/usr/sbin/init"]

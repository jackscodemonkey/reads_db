FROM centos:centos7
LABEL maintainer="Marcus Robb <marcus.robb@initworx.com>"

ENV HOSTNAME=gpdbsne

RUN mkdir -p /software /data/master /data/primary
COPY docker_config/* /software/

RUN useradd gpadmin -m -p gpadmin

RUN mv /software/gp_init_config /home/gpadmin \
    && mv /software/entrypoint.sh / \
    && yum install -y software/*.rpm \
	&& yum clean all \
	&& rm -rf /var/cache/yum \
	&& rm -rf /software

RUN chown gpadmin.gpadmin /usr/local/greenplum* \
	&& echo "source /usr/local/greenplum-db/greenplum_path.sh" >> /home/gpadmin/.bashrc \
	&& echo "export MASTER_DATA_DIRECTORY=/data/master/gpseg-1" >> /home/gpadmin/.bashrc \
	&& sed -i 's/#*PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config \
	&& sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd \
	&& /usr/bin/ssh-keygen -A \
	&& echo 'root:changeme' | chpasswd \
	&& echo 'gpadmin:changeme' | chpasswd \
	&& cat /dev/zero | ssh-keygen -t rsa -q -N "" \
	&& echo "StrictHostKeyChecking no" >> ~/.ssh/config \
	&& cat ~/.ssh/id_rsa.pub | cut -d " " -f1,2 > ~/.ssh/authorized_keys \
	&& su - gpadmin -c 'cat /dev/zero | ssh-keygen -t rsa -q -N ""' \
	&& su - gpadmin -c 'echo "StrictHostKeyChecking no" >> ~/.ssh/config' \
	&& su - gpadmin -c 'cat ~/.ssh/id_rsa.pub | cut -d " " -f1,2 > ~/.ssh/authorized_keys' \
	&& chmod 400 ~/.ssh/config \
	&& chmod 400 /home/gpadmin/.ssh/config \
	&& chmod 400 ~/.ssh/authorized_keys \
	&& chmod 400 /home/gpadmin/.ssh/authorized_keys \
	&& su - gpadmin -c "echo $HOSTNAME >> ~/hostfile.txt" \
	&& chown -R gpadmin.gpadmin /data

RUN chmod +x /entrypoint.sh
RUN echo 1

EXPOSE 22
EXPOSE 5432

CMD /entrypoint.sh

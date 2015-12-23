FROM  centos:centos6
MAINTAINER Baptiste Mathus <batmat@batmat.net>

ADD yum.conf /tmp/yum.conf.proxy
RUN cp /etc/yum.conf /etc/yum.conf.original &&\
    mv /tmp/yum.conf.proxy /etc/yum.conf &&\
    yum -y install \
                   epel-release \
                   git \
                   openssh-server \
                   sudo \
                   tar

##############################################
# Configure locale
RUN localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
ENV LANG=fr_FR.UTF-8
##############################################

###############################################################################
# Configuration de l'image via le playbook ansible jenkins-slaves.yml existant
###############################################################################
RUN yum install -y ansible
# Autorise sudo sans tty
RUN sed -i 's/\(Defaults *requiretty\)/# disabled by forge \1/' /etc/sudoers &&\
    sed -i 's/\(Defaults *!visiblepw\)/# disabled by forge \1/' /etc/sudoers && \
    sed -i 's/# \(%wheel\s*ALL=(ALL)\s*NOPASSWD: ALL\)/\1/' /etc/sudoers
RUN useradd ic --home-dir /iclinux -G wheel

# On passe user ic pour que le playbook se déroule correctement (sudo, etc.)
# Note : à revoir ultérieurement lorsqu'on utilisera surtout le Dockerfile comme base de conf d'un slave
# au lieu d'ansible comme actuellement
WORKDIR /tmp/forge-config-mgt
ADD playbook.yml playbook.yml
ADD yum.conf yum.conf

# Note : l'appel à ansible-playbook ci-dessous peut mettre plusieurs longues minutes avant d'afficher quoi que ce soit
RUN echo -e "[jenkins-slaves]\n127.0.0.1 ansible_connection=local\n" > local-hosts
RUN ansible-playbook -i local-hosts playbook.yml

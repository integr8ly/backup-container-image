FROM centos:7

ARG OKD_URL=https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz

RUN yum --enablerepo=extras install -y epel-release && \
    yum install -y --setopt=tsflags=nodocs python-pip mysql && \
    yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm && \
    yum install -y postgresql96 postgresql10 redis python3 && \
    yum clean all && \
    ln -fs /usr/bin/python3 /usr/bin/python && \
    python -m ensurepip --upgrade && \
    pip3 install -U pip && \
    pip3 install awscli s3cmd && \
    curl --retry 999 --retry-max-time 0 -sSL ${OKD_URL} | tar xzv && \
    mv openshift-origin-*/* /usr/bin/

COPY tools /opt/intly/tools
RUN mkdir -p /opt/intly/output
RUN chown -R 1001:root /opt/intly

RUN find /opt/intly/tools -type f -exec chmod +x {} \; && \
    mkdir /.kube && touch /.kube/config && chmod -R 774 /.kube

ENTRYPOINT ["/opt/intly/tools/entrypoint.sh"]

USER 1001
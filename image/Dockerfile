FROM centos:7

RUN yum --enablerepo=extras install -y epel-release && \
    yum install -y --setopt=tsflags=nodocs python-pip mysql && \
    yum clean all && \
    pip install -U pip && \
    pip install awscli s3cmd

COPY tools /opt/intly/tools
#RUN chown -R default:root /opt/tools/intly

#USER default

RUN find /opt/intly/tools -type f -exec chmod +x {} \;

ENTRYPOINT ["/opt/intly/tools/entrypoint.sh"]

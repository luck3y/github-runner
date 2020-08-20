FROM registry.access.redhat.com/ubi7/ubi

ARG GITHUB_RUNNER_VERSION="2.267.1"

ENV RUNNER_NAME "runner"
ENV GITHUB_PAT ""
ENV GITHUB_OWNER ""
ENV GITHUB_REPOSITORY ""
ENV RUNNER_WORKDIR "/opt/github/_work"
ENV RUNNER_LABELS ""

# Update image
RUN yum update \
  --disablerepo=* --enablerepo=ubi-7 -y \
  && rm -rf /var/cache/yum

# Install additional dependencies
RUN yum install \
  --disablerepo=* --enablerepo=ubi-7 -y \
  hostname \
  iputils \
  wget \
  && rm -rf /var/cache/yum

RUN mkdir -p /opt/github
RUN mkdir -p /.m2

WORKDIR /opt/github

# Install runner dependencies
RUN curl -Ls https://github.com/actions/runner/releases/download/v${GITHUB_RUNNER_VERSION}/actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz | tar xz \
    && ./bin/installdependencies.sh

# Install EPEL (needed for jq)
#  installed after running installdependencies.sh script on purpose so
#  only jq and nothing else comes from epel
RUN yum install -y \
  https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
  && rm -rf /var/cache/yum

RUN wget http://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo -O /etc/yum.repos.d/epel-apache-maven.repo && yum install -y apache-maven && rm -rf /var/cache/yum

COPY settings.xml /usr/share/apache-maven/conf/

# Install jq
RUN yum install \
  --disablerepo=* --enablerepo=epel -y \
  jq \
  && rm -rf /var/cache/yum

COPY entrypoint.sh ./entrypoint.sh
RUN chmod u+x ./entrypoint.sh

# Fix up permissions for OpenShift random uids
RUN chgrp -R 0 /opt/github && \
    chmod -R g=u /opt/github && \
    chgrp -R 0 /.m2 && \
    chmod -R g=u /.m2

ENTRYPOINT ["/opt/github/entrypoint.sh"]

# s2i-springboot : 12-08-2017
#
# springboot-java
#
FROM openshift/base-centos7
LABEL maintainer Yann
# HOME in base image is /opt/app-root/src

# Builder version
ENV BUILDER_VERSION 1.0

LABEL io.k8s.description="Platform for building Spring Boot applications with maven or gradle" \
      io.k8s.display-name="Spring Boot builder 1.0" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="Java,Springboot,builder"

# Install required util packages.
RUN yum -y update; \
    yum install tar -y; \
    yum install unzip -y; \
    yum install ca-certificates -y; \
    yum install sudo -y; 

# Install OpenJDK 11, create required directories.
RUN yum install -y java-11-openjdk java-11-openjdk-devel && \
    mkdir -p /opt/openshift

# Chinese
RUN yum -y groupinstall "Fonts"    
RUN yum install -y kde-l10n-Chinese
RUN yum reinstall -y glibc-common
RUN localedef -c -f UTF-8 -i zh_CN zh_CN.UFT-8
RUN echo 'LANG="zh_CN.UTF-8"' > /etc/locale.conf && source /etc/locale.conf
RUN echo "export LC_ALL=zh_CN.UTF-8" >> /etc/profile && source /etc/profile
RUN source /etc/locale.conf

# location
RUN cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# Install consul
# RUN yum install -y yum-utils && \
#       yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo && \
#       yum -y install consul
      
# clean yum
RUN yum clean all -y

# Install Maven 3.5.2
ENV MAVEN_VERSION=3.6.3
#RUN (curl -fSL https://www-eu.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | \
#    tar -zx -C /usr/local) && \
#    mv /usr/local/apache-maven-$MAVEN_VERSION /usr/local/maven && \
#    ln -sf /usr/local/maven/bin/mvn /usr/local/bin/mvn && \
#    mkdir -p $HOME/.m2 && chmod -R a+rwX $HOME/.m2
COPY m2/settings.xml $HOME/.m2/
# Set the location of the mvn and gradle bin directories on search path
ENV PATH=/usr/local/bin/mvn:$PATH

# Set the default build type to 'Maven'
ENV BUILD_TYPE=Maven

ENV TARGET_DIR=$TARGET_DIR
ENV APP_OPTIONS=$APP_OPTIONS
# Drop the root user and make the content of /opt/openshift owned by user 1001
RUN chown -R 1001:1001 /opt/openshift /opt/app-root/src

# Change perms on target/deploy directory to 777
RUN chmod -R 777 /opt/openshift /opt/app-root/src

# Copy the S2I scripts to /usr/libexec/s2i, since openshift/base-centos7 image
# sets io.openshift.s2i.scripts-url label that way.
COPY ./s2i/bin/ /usr/libexec/s2i
RUN chmod -R 777 /usr/libexec/s2i

# This default user is created in the openshift/base-centos7 image
USER 1001

# Set the default port for applications built using this image
EXPOSE 8080

# Set the default CMD for the image
CMD ["/usr/libexec/s2i/usage"]

FROM jenkins/jenkins:lts

# switch to root user
USER root
# Install packages which are required
RUN apt-get update -y  && \
    apt-get install -y ssh git \
    apt-transport-https \
    ssh\
      ca-certificates \
      curl \
      gnupg2 \
      software-properties-common \
      python-pip && \
      pip install pyyaml &&\
      pip install jenkins-job-builder 

RUN pip install tox
# install jenkins plugins
COPY ./jenkins-plugins /usr/share/jenkins/plugins
RUN while read i ; \
    do /usr/local/bin/install-plugins.sh $i ; \
    done < /usr/share/jenkins/plugins


ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false
# Jenkins runs all grovy files from init.groovy.d dir
# use this for creating default admin user
COPY default-user.groovy /usr/share/jenkins/ref/init.groovy.d/
 
ADD tox.ini ~/
RUN apt-get install apt-utils sudo -y \
    && echo "jenkins ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/jenkins

COPY jenkins-plugin-cli.sh /usr/local/bin/jenkins-plugin-cli.sh
RUN chmod 755 /usr/local/bin/jenkins-plugin-cli.sh

## Create directory for jenkins-job-builder
RUN mkdir /etc/jenkins_jobs
RUN chmod u+x /etc/jenkins_jobs

## Create jenkins-job-builder config directory
ADD jenkins_jobs.ini /etc/jenkins_jobs/jenkins_jobs.ini

# All are written under RUN because if we use it multiple times it will create multiple layers 
ADD jenkins_jobs.ini /etc/jenkins_jobs/jenkins_jobs.ini

# Copy the files for creating job by job-buil
#RUN tox -e py27
RUN mkdir -p  /var/jenkins_home/jobs 
COPY sample1.yaml /var/jenkins_home/jobs/sample1.yaml
COPY sample2.yaml /var/jenkins_home/jobs/sample2.yaml
WORKDIR /var/jenkins_home
#CMD ["jenkins-jobs", "--conf" ,"/etc/jenkins_jobs/jenkins_jobs.ini", "update", "jobs"]

#RUN sleep 30 && sudo jenkins-jobs --conf /etc/jenkins_jobs/jenkins_jobs.ini update jobs


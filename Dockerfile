FROM ubuntu:14.04

RUN apt-get -y update && apt-get -y install \
vim curl wget openjdk-7-jre openjdk-7-jdk python git supervisor python-pip gcc python-dev rsyslog unzip daemon

ENV GERRIT_HOME /opt/gerrit
ENV JENKINS_HOME /var/lib/jenkins
ENV SITE_PATH $GERRIT_HOME/site_path

ENV GERRIT_VERSION 2.12.1

ENV GERRIT_URL https://www.gerritcodereview.com/download/gerrit-${GERRIT_VERSION}.war

ENV JENKINS_VERSION 1.580.3
ENV JENKINS_REPO_KEY https://jenkins-ci.org/debian/jenkins-ci.org.key
ENV JENKINS_REPO_PLUGINS https://updates.jenkins-ci.org/download/plugins
ENV JENKINS_GEARMAN_PLUGIN ${JENKINS_REPO_PLUGINS}/gearman-plugin/0.1.3/gearman-plugin.hpi

RUN mkdir -p $SITE_PATH
RUN mkdir $SITE_PATH/lib
RUN mkdir $SITE_PATH/etc
RUN mkdir $SITE_PATH/bin
RUN mkdir $SITE_PATH/plugins

RUN curl --silent --show-error --retry 12 --retry-delay 10 -L -o $SITE_PATH/gerrit.war $GERRIT_URL

RUN wget -q http://pkg.jenkins-ci.org/debian-stable/binary/jenkins_${JENKINS_VERSION}_all.deb
RUN dpkg -i jenkins_${JENKINS_VERSION}_all.deb

RUN mkdir -p $JENKINS_HOME/plugins
RUN curl --silent --show-error --retry 12 --retry-delay 10 -L -o $JENKINS_HOME/plugins/gearman-plugin.hpi $JENKINS_GEARMAN_PLUGIN

RUN pip install virtualenv nose flake8 mock

RUN mkdir -p /etc/zuul
RUN mkdir -p /var/log/zuul
RUN mkdir -p /var/lib/zuul
RUN mkdir -p /var/www/zuul
RUN pip install zuul
#RUN git clone https://github.com/openstack-infra/zuul /tmp/zuul
#RUN pip install /tmp/zuul
#RUN cp -Rf /tmp/zuul/etc/status/public_html/* /var/www/zuul/
#RUN rm -Rf /tmp/zuul
#
#RUN curl --silent --show-error --retry 12 --retry-delay 10 -L -o /var/www/zuul/fetch.sh https://raw.githubusercontent.com/openstack-infra/zuul/master#/etc/status/fetch-dependencies.sh
#RUN sed -i "s|public_html/||" /var/www/zuul/fetch.sh
#RUN bash /var/www/zuul/fetch.sh

RUN mkdir /etc/jenkins_jobs
RUN mkdir /etc/jenkins_jobs/jobs
RUN pip install jenkins-job-builder

ADD ./confs/gerrit.config $SITE_PATH/etc/gerrit.config

RUN mkdir -p $JENKINS_HOME/plugins/users/jenkins/
ADD ./confs/gearman_config.xml $JENKINS_HOME/hudson.plugins.gearman.GearmanPluginConfig.xml
ADD ./confs/jenkins-config.xml $JENKINS_HOME/config.xml
ADD ./confs/jenkins-user.xml $JENKINS_HOME/users/jenkins/config.xml
ADD ./confs/jenkins.model.JenkinsLocationConfiguration.xml $JENKINS_HOME/jenkins.model.JenkinsLocationConfiguration.xml
RUN chown -R jenkins:jenkins $JENKINS_HOME

ADD ./confs/zuul.conf /etc/zuul/zuul.conf
ADD ./confs/logging.conf /etc/zuul/logging.conf
ADD ./confs/merger-logging.conf /etc/zuul/merger-logging.conf
ADD ./confs/gearman-logging.conf /etc/zuul/gearman-logging.conf
ADD ./confs/layout.yaml /etc/zuul/layout.yaml
ADD ./confs/zuul_site.conf /etc/httpd/conf.d/zuul.conf

ADD ./confs/jenkins_jobs.ini /etc/jenkins_jobs/jenkins_jobs.ini
ADD ./confs/jjb.yaml /etc/jenkins_jobs/jobs/jjb.yaml

ADD ./confs/ssh_wrapper.sh /tmp/ssh_wrapper.sh
ADD ./confs/gerrit-post.sh /tmp/gerrit-post.sh
RUN chmod +x /tmp/ssh_wrapper.sh /tmp/gerrit-post.sh
ADD ./confs/project.config /tmp/project.config

ADD ./supervisord.conf /etc/supervisord.conf
ADD ./start.sh /start.sh

RUN chmod +x /start.sh

RUN useradd gerrit
RUN chown -R gerrit:gerrit $GERRIT_HOME

EXPOSE 29418 8080 8081 80

CMD ["/start.sh"]

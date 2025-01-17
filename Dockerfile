FROM ubuntu:20.04

RUN echo "Europe/Berlin" > /etc/timezone
ENV DEBIAN_FRONTEND=noninteractive
# Configuration variables.
ENV JIRA_HOME     /var/atlassian/jira
ENV JIRA_INSTALL  /opt/atlassian/jira
ENV JIRA_VERSION  8.12.0

# Install Atlassian JIRA and helper tools and setup initial home
# directory structure.
RUN apt-get update  \
&&  apt-get install curl -y \
&&  apt-get install net-tools -y \
&&  apt-get install nano -y \
&&  apt-get install sudo -y \
&&  apt-get install ufw -y \
&&  apt-get install wget -y \
&&  sudo /usr/sbin/useradd --create-home --comment "Account for running JIRA Software" --shell /bin/bash jira \
&&  apt-get install openjdk-8-jre -y \
&&  apt-get install mysql-server -y \
    &&  apt-get install mysql-client -y \
    && mkdir -p                "${JIRA_HOME}" \
    && mkdir -p                "${JIRA_HOME}/caches/indexes" \
    && chmod -R 700            "${JIRA_HOME}" \
    && mkdir -p                "${JIRA_INSTALL}/conf/Catalina" \
    && sudo chown -R jira          "${JIRA_INSTALL}" \
    && sudo chmod -R u=rwx,go-rwx  "${JIRA_INSTALL}" \
    && sudo chown -R jira  "${JIRA_HOME}" \
    && sudo chmod -R u=rwx,go-rwx "${JIRA_HOME}" \
    && sudo chmod -R o-x "${JIRA_HOME}" \
    && mkdir -p                "${JIRA_INSTALL}/conf/Catalina" \
    && curl -Ls                "https://www.atlassian.com/software/jira/downloads/binary/atlassian-jira-software-8.12.0.tar.gz" | tar -xz --directory "${JIRA_INSTALL}" --strip-components=1 --no-same-owner \
    && curl -Ls                "https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.38.tar.gz" | tar -xz --directory "${JIRA_INSTALL}/lib" --strip-components=1 --no-same-owner "mysql-connector-java-5.1.38/mysql-connector-java-5.1.38-bin.jar" \
    && chmod -R 700            "${JIRA_INSTALL}/conf" \
    && chmod -R 700            "${JIRA_INSTALL}/logs" \
    && chmod -R 700            "${JIRA_INSTALL}/temp" \
    && chmod -R 700            "${JIRA_INSTALL}/work" \
    && chown -R jira:jira  "${JIRA_INSTALL}/conf" \
    && chown -R jira:jira  "${JIRA_INSTALL}/logs" \
    && chown -R jira:jira  "${JIRA_INSTALL}/temp" \
    && chown -R jira:jira  "${JIRA_INSTALL}/work" \
    && chown -R jira:jira  "${JIRA_HOME}" \
    && sed --in-place          "s/java version/openjdk version/g" "${JIRA_INSTALL}/bin/check-java.sh" \
    && echo -e                 "\njira.home=$JIRA_HOME" >> "${JIRA_INSTALL}/atlassian-jira/WEB-INF/classes/jira-application.properties" \
    && touch -d "@0"           "${JIRA_INSTALL}/conf/server.xml"\

# Use the default unprivileged account. This could be considered bad practice
# on systems where multiple processes end up being executed by 'daemon' but
# here we only ever run one process anyway.
USER jira:jira

# Expose default HTTP connector port.
EXPOSE 8080

# Set volume mount points for installation and home directory. Changes to the
# home directory needs to be persisted as well as parts of the installation
# directory due to eg. logs.
VOLUME ["/var/atlassian/jira", "/opt/atlassian/jira/logs"]

# Set the default working directory as the installation directory.
WORKDIR /var/atlassian/jira


# Run Atlassian JIRA as a foreground process by default.
CMD ["/opt/atlassian/jira/bin/start-jira.sh", "-fg"]

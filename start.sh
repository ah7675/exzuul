#!/bin/bash

set -x

# export JAVA_HOME=/usr/lib/jvm/java-1.6.0-openjdk-1.6.0.34.x86_64/jre/

java -jar /opt/gerrit/site_path/gerrit.war init -d /opt/gerrit/site_path \
  --batch --no-auto-start \
  --install-plugin commit-message-length-validator \
  --install-plugin download-commands \
  --install-plugin replication
java -jar /opt/gerrit/site_path/gerrit.war reindex -d /opt/gerrit/site_path

# Init admin user
java -jar /opt/gerrit/site_path/gerrit.war gsql -d /opt/gerrit/site_path/ -c "delete from ACCOUNTS where FULL_NAME='Administrator'"
java -jar /opt/gerrit/site_path/gerrit.war gsql -d /opt/gerrit/site_path/ -c "delete from ACCOUNT_EXTERNAL_IDS where ACCOUNT_ID=1000000"
java -jar /opt/gerrit/site_path/gerrit.war gsql -d /opt/gerrit/site_path/ -c "insert into ACCOUNTS values ('2015-05-28 11:00:30.001', 'admin', 'admin@ci.localdomain', 25, 'Y', 'Y', NULL, NULL, 'N', NULL, NULL, 'N', NULL, 'Y', 'N', NULL, 'Y', 'N', 1000000)"
java -jar /opt/gerrit/site_path/gerrit.war gsql -d /opt/gerrit/site_path/ -c "insert into ACCOUNT_GROUP_MEMBERS values (1000000, 1)"
java -jar /opt/gerrit/site_path/gerrit.war gsql -d /opt/gerrit/site_path/ -c "insert into ACCOUNT_EXTERNAL_IDS values (1000000, 'admin@ci.localdomain', NULL, 'username:admin')"
java -jar /opt/gerrit/site_path/gerrit.war gsql -d /opt/gerrit/site_path/ -c "insert into ACCOUNT_EXTERNAL_IDS values (1000000, 'admin@ci.localdomain', NULL, 'mailto:admin@ci.localdomain')"

# Init zuul user
java -jar /opt/gerrit/site_path/gerrit.war gsql -d /opt/gerrit/site_path/ -c "insert into ACCOUNTS values ('2015-05-28 11:00:30.001', 'zuul', 'zuul@ci.localdomain', 25, 'Y', 'Y', NULL, NULL, 'N', NULL, NULL, 'N', NULL, 'Y', 'N', NULL, 'Y', 'N', 1000001)"
java -jar /opt/gerrit/site_path/gerrit.war gsql -d /opt/gerrit/site_path/ -c "insert into ACCOUNT_GROUP_MEMBERS values (1000001, 2)"
java -jar /opt/gerrit/site_path/gerrit.war gsql -d /opt/gerrit/site_path/ -c "insert into ACCOUNT_GROUP_MEMBERS values (1000001, 4)"
java -jar /opt/gerrit/site_path/gerrit.war gsql -d /opt/gerrit/site_path/ -c "insert into ACCOUNT_EXTERNAL_IDS values (1000001, 'zuul@ci.localdomain', NULL, 'username:zuul')"
java -jar /opt/gerrit/site_path/gerrit.war gsql -d /opt/gerrit/site_path/ -c "insert into ACCOUNT_EXTERNAL_IDS values (1000001, 'zuul@ci.localdomain', NULL, 'mailto:zuul@ci.localdomain')"

mkdir /var/lib/keys
ssh-keygen -N '' -f /var/lib/keys/id_rsa

pubkey=$(cat /var/lib/keys/id_rsa.pub)
java -jar /opt/gerrit/site_path/gerrit.war gsql -d /opt/gerrit/site_path/ -c "insert into account_ssh_keys values ('$pubkey', 'Y', 1000001, 1)"
java -jar /opt/gerrit/site_path/gerrit.war gsql -d /opt/gerrit/site_path/ -c "insert into account_ssh_keys values ('$pubkey', 'Y', 1000000, 1)"

# Post actions after gerrit start - this is a quick and dirty solution
bash -c "sleep 20; /tmp/gerrit-post.sh" &

supervisord -n

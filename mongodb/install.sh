#mongodb install 4.2
#https://docs.mongodb.com/manual/tutorial/install-mongodb-on-red-hat/
#Create a /etc/yum.repos.d/mongodb-org-4.2.repo file so that you can install MongoDB directly using yum:
cat>/etc/yum.repos.d/mongodb-org-4.2.repo<<EOF
[mongodb-org-4.2]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/4.2/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.2.asc
EOF

yum install -y mongodb-org

cat>>/etc/yum.conf<<EOF
exclude=mongodb-org,mongodb-org-server,mongodb-org-shell,mongodb-org-mongos,mongodb-org-tools
EOF
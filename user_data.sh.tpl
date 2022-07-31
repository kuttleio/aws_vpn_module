#!/bin/bash

set -x

yum -y update
yum -y install wget unzip dirmngr

#Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Set ENV Variables
INIT_CONFIG=false

BACKUP_BUCKET_NAME=${backup_bucket_name}
BACKUP_FILE=${backup_file_name}

ALLOCATION_ID=${eip_allocation_id}
HOST=${host}
REGION=`curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document|grep region|awk -F\" '{print $4}'`

# Set Elastic IP
INSTANCE_ID=`curl --silent http://169.254.169.254/latest/meta-data/instance-id`
aws ec2 associate-address --allow-reassociation --instance-id $INSTANCE_ID --allocation-id $ALLOCATION_ID --region=$REGION

tee /etc/yum.repos.d/mongodb-org-4.2.repo << EOF
[mongodb-org-4.2]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/8/mongodb-org/4.2/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.2.asc
EOF

tee /etc/yum.repos.d/pritunl.repo << EOF
[pritunl]
name=Pritunl Repository
baseurl=https://repo.pritunl.com/stable/yum/oraclelinux/8/
gpgcheck=1
enabled=1
EOF

# Disable SELINUX
sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
setenforce 0

# install mongodb and pritunl
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
gpg --homedir /root/.gnupg/ --keyserver hkp://keyserver.ubuntu.com --recv-keys 7568D9BB55FF9E5287D586017AE645C0CF8E292A
gpg --homedir /root/.gnupg/ --armor --export 7568D9BB55FF9E5287D586017AE645C0CF8E292A > key.tmp; sudo rpm --import key.tmp; rm -f key.tmp
yum -y install pritunl mongodb-org
systemctl start mongod
systemctl enable mongod
pritunl set-mongodb "mongodb://localhost:27017/pritunl"


# Check if backup of config available in S3 Bucket
LATEST_BACKUP=$(aws s3api list-objects --bucket $BACKUP_BUCKET_NAME \
    --prefix $BACKUP_FILE \
    --query 'Contents[*].[Key]'  \
    --output text | sort | tail -n 1)

# Download latest version of conifg backup
if [ ! -z "$LATEST_BACKUP" ]; then
    aws s3 cp s3://$BACKUP_BUCKET_NAME/$LATEST_BACKUP /tmp/
    if [ $? -ne 0 ]; then
          echo "Failed to download pritunl configuration from S3."
          INIT_CONFIG=true
    fi
else
    echo "No pritunl configuration was found."
    INIT_CONFIG=true
fi

if [ "$INIT_CONFIG" == "true" ]; then
# set default password  
  pritunl default-password
# start pritunl service  
  systemctl start pritunl
  systemctl enable pritunl
else
#Restote from Latest backup
  mongo pritunl --eval 'db.dropDatabase()'
  cd /tmp
  tar -xzf /tmp/$LATEST_BACKUP
  mongorestore -d pritunl dump/pritunl/
# clean tmp  
  rm -rf dump
  rm -rf /tmp/$LATEST_BACKUP
# start pritunl service   
  systemctl start pritunl
  systemctl enable pritunl
fi

# mongodb - backup and upload to S3 bucket
cat <<EOF > /usr/sbin/mongobackup.sh
#!/bin/bash -e
set -o errexit  # exit on cmd failure
set -o nounset  # fail on use of unset vars
set -o pipefail # throw latest exit failure code in pipes
set -o xtrace   # print command traces before executing command.
export PATH="/usr/local/bin:\$PATH"
export BACKUP_TIME=\$(date +'%Y-%m-%d-%H-%M-%S')
export BACKUP_FILENAME="${backup_file_name}-\$BACKUP_TIME.tar.gz"
export BACKUP_DEST="/tmp/\$BACKUP_TIME"

mkdir "\$BACKUP_DEST" && cd "\$BACKUP_DEST"
mongodump -d pritunl
tar zcf "\$BACKUP_FILENAME" dump
rm -rf dump
aws s3 sync . s3://$BACKUP_BUCKET_NAME
cd && rm -rf "\$BACKUP_DEST"
EOF
chmod 700 /usr/sbin/mongobackup.sh

# execute mongodb backup every hour
cat <<EOF > /etc/cron.hourly/pritunl-backup
#!/bin/bash -e
export PATH="/usr/local/sbin:/usr/local/bin:\$PATH"
mongobackup.sh 
EOF
chmod 755 /etc/cron.hourly/pritunl-backup

# logrotate for mongodb logs
cat <<EOF > /etc/logrotate.d/pritunl
/var/log/mongodb/*.log {
  daily
  missingok
  rotate 60
  compress
  delaycompress
  copytruncate
  notifempty
}
EOF
#!/bin/bash

apt update >/dev/null 2>&1

parted -s /dev/sdc mklabel gpt
parted -s -a optimal /dev/sdc mkpart logical 0% 100%
parted -s /dev/sdc 'set 1 lvm on'
pvcreate /dev/sdc1
vgcreate vg_data /dev/sdc1
lvcreate -l 100%FREE -n lv_elast vg_data
mkfs.ext4 /dev/vg_data/lv_elast
mkdir -p /var/lib/elasticsearch
echo "/dev/vg_data/lv_elast /var/lib/elasticsearch ext4 defaults 0 0" | tee -a /etc/fstab
mount -a

#configurar repositorio 
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
sudo apt-get install apt-transport-https
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list

#Instalacion elastic
rm -rf /var/lib/elasticsearch/lost+found/
sudo apt-get update && sudo apt-get install elasticsearch
chown elasticsearch:elasticsearch /var/lib/elasticsearch/
systemctl enable elasticsearch.service --now


passelastic=$(sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic -b -s)
passkibana=$(sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -u kibana_system -b -s)

echo $passelastic >> /elastic.txt
echo $passkibana >> /kibana.txt

#Instalacion Kibana

mkdir -p /etc/kibana/certs
cp /etc/elasticsearch/certs/http_ca.crt /etc/kibana/certs/
IP_Kibana=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | head -1 | cut -d '/' -f1)

apt-get update && apt-get install kibana

cat > /etc/kibana/kibana.yml << EOF
server.port: 5601
server.host: "$IP_Kibana"
elasticsearch.hosts: ["https://localhost:9200"]
elasticsearch.username: "kibana_system" 
elasticsearch.password: $passkibana
elasticsearch.ssl.certificateAuthorities: [ "/etc/kibana/certs/http_ca.crt" ]

logging:
  appenders:
    file:
      type: file
      fileName: /var/log/kibana/kibana.log
      layout:
        type: json
  root:
    appenders:
      - default
      - file

pid.file: /run/kibana/kibana.pid
EOF


#Instalacion Logstash
apt-get update && apt-get install logstash
mkdir -p /etc/logstash/certs
cp /etc/elasticsearch/certs/http_ca.crt /etc/logstash/certs/
chown logstash:logstash /etc/logstash/certs
chown logstash:logstash /etc/logstash/certs/http_ca.crt 


curl -XPOST --cacert /etc/logstash/certs/http_ca.crt -u elastic:$passelastic 'https://localhost:9200/_security/role/logstash_write_role' -H "Content-Type: application/json" -d '{
   "cluster": [
        "monitor",
        "manage_index_templates"
    ],
    "indices": [
    {
        "names": [
        "*"
        ],
        "privileges": [
            "write",
            "create_index",
            "auto_configure"
        ],
        "field_security": {
        "grant": [
            "*"
            ]
        }
    }     
    ],
    "run_as": [],
    "metadata": {},
    "transient_metadata": {
        "enabled": true
    }
}'

curl -XPOST --cacert /etc/logstash/certs/http_ca.crt -u elastic:$passelastic 'https://localhost:9200/_security/user/logstash' -H "Content-Type: application/json" -d '{
"password" : "keepcoding_logstash",
"roles" : ["logstash_admin", "logstash_system", "logstash_write_role"],
"full_name" : "Logstash User"
}'

cat > /etc/logstash/conf.d/02-beats-input.conf << END
input {
    beats {
        port => 5044
    }
}
END

cat > /etc/logstash/conf.d/30-elasticsearch-output.conf << END

output {
elasticsearch {
    hosts => ["https://localhost:9200"]
    manage_template => false
    index => "filebeat-demo-%{+YYYY.MM.dd}"
    user => "logstash"
    password => "keepcoding_logstash"
    cacert => "/etc/logstash/certs/http_ca.crt"
    }
}
END

systemctl enable logstash.service --now
systemctl enable kibana.service --now


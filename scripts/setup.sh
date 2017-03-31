sudo yum -y install https://s3.amazonaws.com/exchange-development-yum/exchange-development-repo-1.0.0.noarch.rpm
sudo yum -y update
sudo yum -y install exchange \
                 boundless-postgis2_96 \
                 elasticsearch \
                 rabbitmq-server \
                 erlang \
                 geonode-geoserver \
                 supervisor

sed -i -e "s/export SITEURL=.*$/export SITEURL=\$\{SITEURL\:\-'http:\/\/$(hostname)\\/'\}/" /etc/profile.d/exchange-settings.sh
grep DJANGO_SETTINGS_MODULE /etc/profile.d/exchange-settings.sh || \
sed -i -e "s/set +e/export DJANGO_SETTINGS_MODULE=\$\{DJANGO_SETTINGS_MODULE\:\-'bex.settings'\}\nset +e/" /etc/profile.d/exchange-settings.sh

sudo service postgresql-9.6 initdb

sed -i -e "s/localhost/$(hostname)/" /etc/profile.d/exchange-settings.sh

sudo chkconfig postgresql-9.6 on
sudo sed -i.exchange 's/peer$/trust/g' /var/lib/pgsql/9.6/data/pg_hba.conf
sudo sed -i.exchange 's/ident$/md5/g' /var/lib/pgsql/9.6/data/pg_hba.conf
sudo service postgresql-9.6 restart

sudo -u postgres psql -c "CREATE USER exchange WITH PASSWORD 'boundless';"
sudo -u postgres psql -c "CREATE DATABASE exchange OWNER exchange;"
sudo -u postgres psql -c "CREATE DATABASE exchange_data OWNER exchange;"
sudo -u postgres psql -d exchange_data -c 'CREATE EXTENSION postgis;'
sudo -u postgres psql -d exchange_data -c 'GRANT ALL ON geometry_columns TO PUBLIC;'
sudo -u postgres psql -d exchange_data -c 'GRANT ALL ON spatial_ref_sys TO PUBLIC;'

sudo chkconfig rabbitmq-server on
sudo service rabbitmq-server start

sudo chkconfig elasticsearch on
sudo service elasticsearch start

python - <<END
from xml.etree import ElementTree
import socket
file_name = '/opt/geonode/geoserver_data/global.xml'
tree = ElementTree.parse(file_name)
root = tree.getroot()
settings = tree.find("settings")
proxyBaseUrl = settings.find("proxyBaseUrl")
if proxyBaseUrl is None:
    proxyBaseUrl = ElementTree.SubElement(settings, "proxyBaseUrl")
proxyBaseUrl.text = "http://{0}/geoserver".format(socket.gethostname())
tree.write(file_name)
END

python - <<END
from xml.etree import ElementTree
import socket
file_name = '/opt/geonode/geoserver_data/security/role/geonode REST role service/config.xml'
tree = ElementTree.parse(file_name)
root = tree.getroot()
baseUrl = tree.find("baseUrl")
baseUrl.text = "http://{0}".format(socket.gethostname())
tree.write(file_name)
END

sudo chkconfig tomcat8 on
sudo service tomcat8 start

sudo echo 'y' | exchange-config django
sudo echo 'y' | exchange-config selinux
sudo chkconfig exchange on
sudo service exchange start
sudo chkconfig httpd on
sudo service httpd restart
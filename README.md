### Installing Boundless Exchange via RPMs
----

**Note:** The Operating System options are CentOS/RHEL Version 6.\*/7.\*. The instructions are also for development releases, which change quite frequently. If you are looking for production releases, please go to the [Boundless Exchange Site](https://boundlessgeo.com/boundless-exchange/).

While in a terminal session with sudo access, run the following commands.

    sudo yum -y install https://s3.amazonaws.com/exchange-development-yum/exchange-development-repo-1.0.0.noarch.rpm
    sudo yum -y update
    sudo yum install exchange \
                     boundless-postgis2_96 \
                     elasticsearch \
                     rabbitmq-server \
                     erlang \
                     geonode-geoserver

The above code snippet will do the following:

+ Install the Boundless and PostgreSQL repo files and GPG keys
+ Update your local packages
+ Install Exchange and additional services

Exchange is dependent on the following services and will each need to be configured:

+ postgresql (Django and Vector Data Storage)
+ elasticsearch (Advanced Search Capabilities)
+ rabbitmq (Celery Workers)
+ geoserver (OGC WFS, WMS, WMTS and GeoFence - Advanced Authentication/Authorization Engine)

**Note:** You can use external services, such as Amazon RDS, Amazon SQS or Amazon ES. Exchange uses a custom version of GeoServer that includes specific extensions and scripts. You do have the ability to install the service in a different host. If you will be using external services you can skip the install steps for those services.

#### Configuration of PostgreSQL Database

Exchange requires 2 x PostgreSQL databases. The first one is for Django and the second for GeoServer / GeoGig, which also requires the PostGIS extension installed.

Example steps to initialize the database instance on the same host

    # el7
    sudo /usr/pgsql-9.6/bin/postgresql96-setup initdb
    # el6
    sudo service postgresql-9.6 initdb

    sudo chkconfig postgresql-9.6 on
    sudo sed -i.exchange 's/peer$/trust/g' /var/lib/pgsql/9.6/data/pg_hba.conf
    sudo sed -i.exchange 's/ident$/md5/g' /var/lib/pgsql/9.6/data/pg_hba.conf
    sudo service postgresql-9.6 restart

The above code snippet will do the following:
+ Initialize the database
+ Enable the service to autostart
+ Adjust the config for trust and md5
+ Restart the service

Example steps to create the user and required databases

    psql -U postgres -c "CREATE USER exchange WITH PASSWORD 'boundless';"
    psql -U postgres -c "CREATE DATABASE exchange OWNER exchange;"
    psql -U postgres -c "CREATE DATABASE exchange_data OWNER exchange;"
    psql -U postgres -d exchange_data -c 'CREATE EXTENSION postgis;'
    psql -U postgres -d exchange_data -c 'GRANT ALL ON geometry_columns TO PUBLIC;'
    psql -U postgres -d exchange_data -c 'GRANT ALL ON spatial_ref_sys TO PUBLIC;'

The above code snippet will do the following:
+ Create the exchange database user
+ Create the Django database named `"exchange"`
+ Create the GeoServer/GeoGig databasenamed `"exchange_data"`
+ Install PostGIS extension into `"exchange_data"`
+ Set geometry_columns and spatial_ref_sys to PUBLIC

Once the above steps are completed, you will need to verify the variables `"DATABASE_URL"` and `"POSTGIS_URL"` in the exchange-settings.sh file to see if they need to be modified. The `exchange-settings.sh` is a bash script that will set environment variables that the Django application will use.

    sudo vi /etc/profile.d/exchange-settings.sh
    ....
    export DATABASE_URL=${DATABASE_URL:-'postgres://exchange:boundless@localhost:5432/exchange'}
    export POSTGIS_URL=${POSTGIS_URL:-'postgis://exchange:boundless@localhost:5432/exchange_data'}

The value is what dj-database-url (python package) uses to create the Django DATABASES dictionary and uses the following URL schema format.

    db_scheme://username:password@hostname_or_ip:port/database_name

**Note:** db_scheme = postgres or postgis

+ DATABASE_URL = Django Database
+ POSTGIS_URL = GeoServer and GeoGig Database

#### Configuration of Elasticsearch

Example steps to configure elasticsearch on the same host

    sudo chkconfig elasticsearch on
    sudo service elasticsearch start

The above code snippet will do the following:
+ Enable the service to autostart
+ Start the service

Verify the variable `"ES_URL"` in the exchange-settings.sh file to see if it needs to be modified.    

    sudo vi /etc/profile.d/exchange-settings.sh
    ....
    export ES_URL=${ES_URL:-'http://localhost:9200/'}

#### Configuration of RabbitMQ Server

Example steps to configure rabbitmq-server on the same host

    sudo chkconfig rabbitmq-server on
    sudo service rabbitmq-server start

The above code snippet will do the following:
+ Enable the service to autostart
+ Start the service

Verify the variable `"BROKER_URL"` in the exchange-settings.sh file to see if it needs to be modified.    

    sudo vi /etc/profile.d/exchange-settings.sh
    ....
    export BROKER_URL=${BROKER_URL:-'amqp://guest:guest@localhost:5672/'}

The URI specification can be found on [RabbitMQ's Site](https://www.rabbitmq.com/uri-spec.html)

#### Configuration of GeoServer

Exchange uses a proxy server (Apache httpd) to proxy requests to Django and GeoServer. GeoServer will need to be configured to include the `"Proxy Base Url"`.

    sudo vi /opt/geonode/geoserver_data/global.xml
    ....
    <onlineResource>http://geoserver.org</onlineResource>
    <proxyBaseUrl>http://192.168.99.110/geoserver/</proxyBaseUrl> # <-- add this entry

Exchange GeoServer also uses a custom security filter and role service. The following files will need to be modified to include the correct settings.

Security Filter:

    sudo vi /opt/geonode/geoserver_data/security/filter/geonode-oauth2/config.xml
    ....
    <!-- GeoNode accessTokenUri -->
    <accessTokenUri>http://192.168.99.110/o/token/</accessTokenUri> # <-- modify this entry

    <!-- GeoNode userAuthorizationUri -->
    <userAuthorizationUri>http://192.168.99.110/o/authorize/</userAuthorizationUri> # <-- modify this entry

    <!-- GeoServer Public URL -->
    <redirectUri>http://192.168.99.110/geoserver</redirectUri> # <-- modify this entry

    <!-- GeoNode checkTokenEndpointUrl -->
    <checkTokenEndpointUrl>http://192.168.99.110/api/o/v4/tokeninfo/</checkTokenEndpointUrl> # <-- modify this entry

    <!-- GeoNode logoutUri -->
    <logoutUri>http://192.168.99.110/account/logout/</logoutUri> # <-- modify this entry

Role Service:

    sudo vi /opt/geonode/geoserver_data/security/role/geonode\ REST\ role\ service/config.xml
    ....
    <baseUrl>http://192.168.99.110</baseUrl>

Example steps to configure geoserver on the same host

    sudo chkconfig tomcat8 on
    sudo service tomcat8 start

The above code snippet will do the following:
+ Enable the service to autostart
+ Start the service

Verify the variables `"GEOSERVER_URL"`, `"GEOSERVER_DATA_DIR"`, `"GEOSERVER_LOG"` and `"GEOGIG_DATASTORE_DIR"` in the exchange-settings.sh file to see if they need to be modified.

    sudo vi /etc/profile.d/exchange-settings.sh
    ....
    export GEOSERVER_URL=${GEOSERVER_URL:-'http://192.168.99.110/geoserver/'}  # <-- modify this entry
    export GEOSERVER_DATA_DIR=${GEOSERVER_DATA_DIR:-'/opt/geonode/geoserver_data'}
    export GEOSERVER_LOG=${GEOSERVER_LOG:-'/opt/geonode/geoserver_data/logs/geoserver.log'}
    export GEOGIG_DATASTORE_DIR=${GEOGIG_DATASTORE_DIR:-'/opt/geonode/geoserver_data/geogig'}

#### Configuration of Django

Verify the variable `"SITEURL"` in the exchange-settings.sh file to see if it needs to be modified.    

    export SITEURL==${SITEURL:-'http://192.168.99.110/'}  # <-- modify this entry
    export DJANGO_SETTINGS_MODULE=${DJANGO_SETTINGS_MODULE:-'bex.settings'}

Example steps to configure exchange on the same host

    sudo exchange-config django
    sudo exchange-config selinux
    sudo chkconfig exchange on
    sudo service exchange start
    sudo chkconfig httpd on
    sudo service httpd restart

### Exchange Port Diagram

                                           Apache httpd (Public 80 or 443)

                                                        |
                                                        |
                                                        |
                                                 --------------
                                                |              |
                                                |              |
                                                |     
                                                |     Tomcat/GeoServer (8080)
                                                |                            
                                                |                          |
                                        -----------------                  |
                                       |                 |                 |
                                       |                 |                 |
                                       |                 |                 |
                                                                           |
                                Exchange (8000)    Registry (8001)         |
                                                                           |
                                       |                 |                 |
                                       |                 |                 |
                                       |                 |                 |
                              ---------|                 |                 |
                             |         |                 |                 |  
                             |         |              ---------------      |
                             |         |             |               |     |
                                       |
                      RabbitMQ (5672)   --- Elasticsearch (9200)   PostgreSQL (5432)
                                       |                                
                                       |                                |
                                        --------------------------------

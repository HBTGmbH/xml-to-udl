FROM store/intersystems/irishealth-community:2021.1.0.215.3

USER root   
## add git
RUN apt update && apt-get -y install git
        
WORKDIR /opt/irisbuild
RUN chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /opt/irisbuild
USER ${ISC_PACKAGE_MGRUSER}

#COPY  Installer.cls .
COPY  src src
COPY module.xml module.xml
COPY iris.script iris.script
COPY do-conversion.sh do-conversion.sh

RUN iris start IRIS \
	&& iris session IRIS < iris.script \
    && iris stop IRIS quietly

CMD [ "-a", "/opt/irisbuild/do-conversion.sh", "-l", "/usr/irissys/mgr/messages.log"]
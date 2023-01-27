ARG IMAGE=intersystemsdc/irishealth-community
FROM $IMAGE

USER root   
# Add Git
RUN apt update && apt-get -y install git
        
WORKDIR /opt/irisbuild
RUN chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /opt/irisbuild
USER ${ISC_PACKAGE_MGRUSER}

COPY src src
COPY module.xml module.xml
COPY iris.script iris.script
COPY entrypoint.sh /entrypoint.sh
COPY do-conversion.sh do-conversion.sh
RUN chmod +x /entrypoint.sh

RUN iris start IRIS \
	&& iris session IRIS < iris.script \
    && iris stop IRIS quietly

ENTRYPOINT [ "/entrypoint.sh" ]
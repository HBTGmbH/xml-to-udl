ARG IMAGE=intersystemsdc/irishealth-community
FROM $IMAGE

USER root
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
# Add Git
RUN apt update && apt-get -y install git

WORKDIR /opt/irisbuild
RUN chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /opt/irisbuild
USER ${ISC_PACKAGE_MGRUSER}

COPY src src
COPY module.xml module.xml
COPY iris.script iris.script

USER root
# create volume for UDL export
RUN mkdir -p /irisrun/udl-export
RUN chown -R ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /irisrun/udl-export
VOLUME [ "/irisrun/udl-export" ]

USER ${ISC_PACKAGE_MGRUSER}

RUN iris start IRIS \
	&& iris session IRIS < iris.script \
    && iris stop IRIS quietly

ENTRYPOINT [ "/entrypoint.sh" ]
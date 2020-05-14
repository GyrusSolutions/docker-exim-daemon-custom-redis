FROM ubuntu:focal AS build-env

RUN cp /etc/apt/sources.list /etc/apt/sources.list~ && \
	sed -Ei 's/^# deb-src /deb-src /' /etc/apt/sources.list && \
	apt-get update && \
	DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata && \
	ln -fs /usr/share/zoneinfo/UTC /etc/localtime && \
	dpkg-reconfigure --frontend noninteractive tzdata && \
	apt-get install -y fakeroot devscripts pbuilder debhelper equivs && \
	mkdir /build

COPY EDITME.patch control.patch ./build/

WORKDIR /build

RUN apt-get source exim4

WORKDIR /build/exim4-4.93

RUN fakeroot debian/rules unpack-configs && \
	cp EDITME.exim4-heavy EDITME.exim4-custom && \
	patch EDITME.exim4-custom ../EDITME.patch && \
	patch debian/control ../control.patch && \
	fakeroot debian/rules pack-configs && \
	apt-get build-dep -y exim4 && \
	apt-get install -y libhiredis-dev && \
	customdaemon=exim4-daemon-custom debuild -us -uc

FROM ubuntu:focal AS prod-env
COPY --from=build-env /build/exim4-daemon-custom_4.93-13ubuntu1_amd64.deb /dist/

RUN apt-get update && \
	apt-get install -y libhiredis0.14 libgnutls-dane0 exim4-config exim4-base && \
	dpkg -i /dist/exim4-daemon-custom_4.93-13ubuntu1_amd64.deb && \
	rm -rf /dist && \
	apt-get install -y bsd-mailx && \
	apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    find /var/log -type f | while read f; do echo -ne '' > $f; done;	



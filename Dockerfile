FROM ubuntu:focal

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
	mk-build-deps debian/control --install --tool='apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends --yes' && \
#	apt-get install -y ./exim4-build-deps-depends_4.93-13ubuntu1_all.deb && \
#	apt-get install -y ./exim4-build-deps_4.93-13ubuntu1_all.deb && \
	customdaemon=exim4-daemon-custom debuild -us -uc

WORKDIR /

RUN apt-get install -y libhiredis0.14 libgnutls-dane0 exim4-config exim4-base && \
	dpkg -i /build/exim4-daemon-custom_4.93-13ubuntu1_amd64.deb && \
	rm -rf /build && \
	apt-get install -y bsd-mailx && \
	apt-get purge --auto-remove -y exim4-build-deps exim4-build-deps-depends fakeroot devscripts pbuilder debhelper equivs && \
	apt-get autoremove -y && \
	apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    find /var/log -type f | while read f; do echo -ne '' > $f; done;	



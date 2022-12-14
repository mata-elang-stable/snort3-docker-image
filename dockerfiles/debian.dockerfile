ARG DEBIAN_VERSION=11

FROM debian:${DEBIAN_VERSION} AS builder

ARG SNORT_VERSION=3.1.47.0
ARG HYPERSCAN_VERSION=5.4.0
ARG LIBDAQ_VERSION=3.0.9
ARG LIBDNET_VERSION=1.16.1

RUN set -eux; \
    apt-get update ; \
    apt-get install -y --no-install-recommends \
    build-essential cmake wget autoconf pkg-config \
    libpcap0.8 libpcap0.8-dev libpcre3 libpcre3-dev \
    luajit libluajit-5.1-dev check hwloc libhwloc-dev \
    libssl1.1 libssl-dev zlib1g zlib1g-dev flex bison \
    lzma lzma-dev uuid git \
    uuid-dev libunwind8 libunwind-dev libsafec-3.5-3 \
    libsafec-dev libjemalloc-dev libjemalloc2 libtool \
    libfl-dev ca-certificates openssl \
    libgoogle-perftools-dev libgoogle-perftools4 libtcmalloc-minimal4 ; \
    apt-get clean ; \
    rm -rf /var/lib/apt/lists/*

ADD https://github.com/intel/hyperscan/archive/refs/tags/v${HYPERSCAN_VERSION}.tar.gz /tmp/hyperscan.tar.gz

RUN set -eux; \
    if [ "$(uname -m)" = 'x86_64*' ] || [ "$(uname -m)" = 'i*86' ]; then \
    mkdir -p /tmp/hyperscan_src/build; \
    tar -xvzf /tmp/hyperscan.tar.gz --strip-components=1 -C /tmp/hyperscan_src ; \
    ( \
    cd /tmp/hyperscan_src/build && \
    cmake /tmp/hyperscan_src && \
    make -j$(nproc) && \
    make install \
    ) ; \
    fi

ADD https://github.com/snort3/libdaq/archive/refs/tags/v${LIBDAQ_VERSION}.tar.gz /tmp/libdaq.tar.gz

RUN set -eux; \
    mkdir -p /tmp/libdaq_src ; \
    tar -xvzf /tmp/libdaq.tar.gz --strip-components=1 -C /tmp/libdaq_src ; \
    (\
    cd /tmp/libdaq_src && \
    ./bootstrap && \
    ./configure && \
    make -j$(nproc) && \
    make install \
    ) ;

ADD https://github.com/ofalk/libdnet/archive/refs/tags/libdnet-${LIBDNET_VERSION}.tar.gz /tmp/libdnet.tar.gz

RUN set -eux; \
    mkdir -p /tmp/libdnet_src ; \
    tar -xvzf /tmp/libdnet.tar.gz --strip-components=1 -C /tmp/libdnet_src ; \
    (\
    cd /tmp/libdnet_src && \
    ./configure && \
    make -j$(nproc) && \
    make install \
    ) ;

ADD https://github.com/snort3/snort3/archive/refs/tags/${SNORT_VERSION}.tar.gz /tmp/snort.tar.gz

RUN set -eux; \
    mkdir -p /tmp/snort_src ; \
    tar -xvzf /tmp/snort.tar.gz --strip-components=1 -C /tmp/snort_src ; \
    (\
    cd /tmp/snort_src && \
    ./configure_cmake.sh --prefix=/usr/local/snort --enable-tcmalloc --enable-jemalloc && \
    cd /tmp/snort_src/build && \
    make -j$(nproc) && \
    make install \
    ) ;

RUN set -eux; \
    git clone --depth 1 --single-branch --branch main https://github.com/shirkdog/pulledpork3.git /usr/local/pulledpork3 ; \
    mkdir -p /usr/local/etc/pulledpork/ ; \
    mkdir -p /usr/local/bin/pulledpork/ ; \
    cp /usr/local/pulledpork3/pulledpork.py /usr/local/bin/pulledpork/ ; \
    cp -r /usr/local/pulledpork3/lib/ /usr/local/bin/pulledpork/ ; \
    cp /usr/local/pulledpork3/etc/pulledpork.conf /usr/local/etc/pulledpork/ ;


FROM debian:${DEBIAN_VERSION}

RUN set -eux; \
    apt-get update ; \
    apt-get install -y --no-install-recommends \
    hwloc luajit libpcap0.8 libunwind8 \
    libjemalloc2 libgoogle-perftools4 libsafec-3.5-3 \
    python3 python3-requests ; \
    apt-get clean ; \
    rm -rf /var/lib/apt/lists/* ; \
    mkdir -p /usr/local/etc/pulledpork/

COPY --from=builder /usr/local/lib/ /usr/local/lib/
COPY --from=builder /usr/local/snort/ /usr/local/
COPY --from=builder /usr/local/bin/pulledpork/ /usr/local/bin/
COPY --from=builder /usr/local/etc/pulledpork/ /usr/local/etc/pulledpork/
COPY conf/pulledpork.conf /usr/local/etc/pulledpork/pulledpork.conf

RUN set -eux; \
    ldconfig /usr/local/lib ; \
    chmod +x /usr/local/bin/pulledpork.py ; \
    # setup user
    groupadd -r snort ; \
    useradd snort -r -g snort ; \
    install -g snort -o snort -m 5775 -d /var/log/snort ; \
    # prepare snort rules diretories
    mkdir -p /usr/local/etc/rules ; \
    mkdir -p /usr/local/etc/so_rules/ ; \
    mkdir -p /usr/local/etc/lists/ ; \
    touch /usr/local/etc/rules/local.rules ; \
    touch /usr/local/etc/lists/default.blocklist ; \
    # download community rules
    pulledpork.py -c /usr/local/etc/pulledpork/pulledpork.conf

CMD [ "/usr/local/bin/snort", "-T", "-c", "/usr/local/etc/snort/snort.lua" ]

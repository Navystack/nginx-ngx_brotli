ARG NGINX_VERSION=1.25.3

FROM nginx:${NGINX_VERSION} as builder
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
	--mount=type=cache,target=/var/lib/apt,sharing=locked \
        apt-get update && apt-get install -y \
        wget \
        tar \
        build-essential \
        xz-utils \
        git \
        build-essential \
        zlib1g-dev \
        libpcre3 \
        libpcre3-dev \
        unzip uuid-dev && \
    mkdir -p /opt/build-stage

WORKDIR /opt/build-stage

RUN git clone https://github.com/nginx-modules/ngx_immutable.git && \
    cd ngx_immutable && \
    git checkout dab3852a2c8f6782791664b92403dd032e77c1cb

RUN wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
RUN tar zxvf nginx-${NGINX_VERSION}.tar.gz
WORKDIR nginx-${NGINX_VERSION}
RUN ./configure --with-compat --add-dynamic-module=../ngx_immutable/ && \
    make modules

FROM nginx:${NGINX_VERSION} as final
COPY --from=builder /opt/build-stage/nginx-${NGINX_VERSION}/objs/ngx_http_immutable_module.so /usr/lib/nginx/modules/

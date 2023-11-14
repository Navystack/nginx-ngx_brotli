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

RUN git clone https://github.com/google/ngx_brotli.git && \
    cd ngx_brotli && \
    git checkout a71f9312c2deb28875acc7bacfdd5695a111aa53

RUN wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
RUN tar zxvf nginx-${NGINX_VERSION}.tar.gz
WORKDIR nginx-${NGINX_VERSION}
RUN ./configure --with-compat --add-dynamic-module=../ngx_brotli/ && \
    make modules

FROM nginx:${NGINX_VERSION} as final
COPY --from=builder /opt/build-stage/nginx-${NGINX_VERSION}/objs/ngx_http_brotli_static_module.so /usr/lib/nginx/modules/
COPY --from=builder /opt/build-stage/nginx-${NGINX_VERSION}/objs/ngx_http_brotli_filter_module.so /usr/lib/nginx/modules/

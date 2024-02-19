FROM python:3.14-trixie

RUN apt-get update && \
    apt-get install -y \
        gdal-bin \
        osmosis \
        osm2pgsql \
        parallel \
        postgresql-client \
        python3-virtualenv

WORKDIR /opt/imposm
RUN wget https://github.com/omniscale/imposm3/releases/download/v0.14.2/imposm-0.14.2-linux-x86-64.tar.gz && \
    tar -xvzf imposm-0.14.2-linux-x86-64.tar.gz && \
    ln -s /opt/imposm/imposm-0.14.2-linux-x86-64/imposm /usr/bin/imposm

WORKDIR /opt/bano

ADD requirements.txt .
RUN pip install -r requirements.txt

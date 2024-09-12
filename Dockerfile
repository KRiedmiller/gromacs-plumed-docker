FROM nvidia/cuda:12.3.1-devel-ubuntu22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Berlin

ARG JOBS=6

RUN cat /etc/apt/sources.list
#install dependencies
RUN apt-get update 
RUN apt-get install -y cmake g++ gcc 
RUN apt-get install -y libblas-dev xxd 
RUN apt-get install -y mpich libmpich-dev 
RUN apt-get install -y curl
RUN apt-get install -y unzip

RUN mkdir /build
WORKDIR /build


ARG PLUMED_VERSION=master

RUN apt-get update
RUN apt-get install -y git

ENV GIT_SSL_NO_VERIFY=true
RUN git clone https://github.com/plumed/plumed2.git plumed2 --branch ${PLUMED_VERSION} --single-branch

# RUN cd /build && \
#     curl https://download.pytorch.org/libtorch/cpu/libtorch-cxx11-abi-shared-with-deps-1.12.1%2Bcpu.zip --output torch.zip && \
#     unzip torch.zip && \
#     rm torch.zip

# ENV LIBTORCH=/build/libtorch
# ENV CPATH=${LIBTORCH}/include/torch/csrc/api/include/:${LIBTORCH}/include/:${LIBTORCH}/include/torch:$CPATH
# ENV INCLUDE=${LIBTORCH}/include/torch/csrc/api/include/:${LIBTORCH}/include/:${LIBTORCH}/include/torch:$INCLUDE
# ENV LIBRARY_PATH=${LIBTORCH}/lib:$LIBRARY_PATH
# ENV LD_LIBRARY_PATH=${LIBTORCH}/lib:$LD_LIBRARY_PATH
# RUN cd plumed2 && ./configure --enable-libtorch --enable-modules=all && make -j ${JOBS} && make install 

RUN cd plumed2 && ./configure --enable-modules=reset && make -j ${JOBS} && make install 
RUN ldconfig

RUN apt update
RUN apt install -y python3

ARG GROMACS_VERSION=2023.2
ARG GROMACS_MD5=fb85104d9cd1f753fde761bcbf842566
ARG GROMACS_PATCH_VERSION=${GROMACS_VERSION}

RUN curl -o gromacs.tar.gz https://ftp.gromacs.org/gromacs/gromacs-${GROMACS_VERSION}.tar.gz
RUN echo ${GROMACS_MD5} gromacs.tar.gz > gromacs.tar.gz.md5 && md5sum -c gromacs.tar.gz.md5

RUN tar -xzvf gromacs.tar.gz
RUN cd gromacs-${GROMACS_VERSION} && plumed patch -e gromacs-${GROMACS_PATCH_VERSION} -p

COPY build-gmx.sh /build
RUN ./build-gmx.sh -s gromacs-${GROMACS_VERSION} -j ${JOBS} -a SSE2
RUN ./build-gmx.sh -s gromacs-${GROMACS_VERSION} -j ${JOBS} -a SSE2 -d

RUN ./build-gmx.sh -s gromacs-${GROMACS_VERSION} -j ${JOBS} -a AVX2_256 -r
RUN ./build-gmx.sh -s gromacs-${GROMACS_VERSION} -j ${JOBS} -a AVX2_256 -r -d

RUN ./build-gmx.sh -s gromacs-${GROMACS_VERSION} -j ${JOBS} -a AVX_512 -r
RUN ./build-gmx.sh -s gromacs-${GROMACS_VERSION} -j ${JOBS} -a AVX_512 -r -d


FROM nvidia/cuda:12.3.1-runtime-ubuntu22.04 

ENV TZ=Europe/Berlin
RUN apt update
RUN apt upgrade -y
RUN apt install -y mpich
RUN apt install -y libcufft10 libmpich12 libblas3 libgomp1
RUN apt install -y rsync tzdata

# COPY --from=builder /build/libtorch /build/libtorch
# ENV LD_LIBRARY_PATH=/build/libtorch/lib:$LD_LIBRARY_PATH
# ENV CPLUS_INCLUDE_PATH=/build/libtorch/include:$CPLUS_INCLUDE_PATH

# COPY --from=builder /build/libtorch/lib/* /usr/local/lib/
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/local/lib/libplumed* /usr/local/lib/
COPY --from=builder /usr/local/lib/plumed/ /usr/local/lib/plumed/

COPY --from=builder /gromacs /gromacs

COPY gmx-chooser.sh /gromacs
COPY gmx /usr/local/bin
RUN ln -s gmx /usr/local/bin/gmx_d
RUN ln -s gmx /usr/local/bin/mdrun
RUN ln -s gmx /usr/local/bin/mdrun_d

RUN apt-get install -y wget build-essential gdb lcov pkg-config \
    libbz2-dev libffi-dev libgdbm-dev libgdbm-compat-dev liblzma-dev \
    libncurses5-dev libreadline6-dev libsqlite3-dev libssl-dev \
    lzma lzma-dev tk-dev uuid-dev zlib1g-dev libmpdec-dev

RUN cd /usr/src && \
    wget https://www.python.org/ftp/python/3.10.14/Python-3.10.14.tgz && \
    tar xzf Python-3.10.14.tgz && \
    cd Python-3.10.14 && \
    ./configure --enable-optimizations && \
    make install
RUN rm -r /usr/src/Python-3.10.14.tgz

RUN cd /usr/src && \
    wget https://www.python.org/ftp/python/3.11.9/Python-3.11.9.tgz && \
    tar xzf Python-3.11.9.tgz && \
    cd Python-3.11.9 && \
    ./configure --enable-optimizations && \
    make install
RUN rm -r /usr/src/Python-3.11.9.tgz

RUN cd /usr/src && \
    wget https://www.python.org/ftp/python/3.9.19/Python-3.9.19.tgz && \
    tar xzf Python-3.9.19.tgz && \
    cd Python-3.9.19 && \
    ./configure --enable-optimizations && \
    make install
RUN rm -r /usr/src/Python-3.9.19.tgz

RUN cd /usr/src && \
    wget https://www.python.org/ftp/python/3.12.4/Python-3.12.4.tgz && \
    tar xzf Python-3.12.4.tgz && \
    cd Python-3.12.4 && \
    ./configure --enable-optimizations && \
    make install
RUN rm -r /usr/src/Python-3.12.4.tgz

RUN mkdir /venv
RUN cd /venv
RUN python3.9 -m pip install -U tox pip
RUN python3.10 -m pip install -U tox pip
RUN python3.11 -m pip install -U tox pip
RUN python3.12 -m pip install -U tox pip

RUN apt install -y nodejs
RUN apt install -y zip

RUN apt clean
RUN ldconfig

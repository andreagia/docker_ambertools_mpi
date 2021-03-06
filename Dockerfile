FROM ubuntu:18.04 as build

#MAINTAINER Andrea Giachetti <Giachetti@cerm.unifi.it>
#LABEL description="Container image to run ambertools with sander MPI"
ENV TZ=Europe/Rome
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt -y update
RUN apt -y upgrade
RUN mkdir /prog
# Download ambertools from https://ambermd.org/AmberTools.php
COPY AmberTools21.tar.bz2 /prog
RUN cd /prog \
#    && bunzip2 AmberTools21.tar.bz2 \
	&& tar xvf AmberTools21.tar.bz2 \
	&& rm AmberTools21.tar.bz2
RUN apt -y install tcsh make \
               gcc gfortran \
               flex bison patch \
               bc xorg-dev libbz2-dev wget \
               cmake
# Download openmpi from https://www.open-mpi.org/software/ompi/v4.1/
COPY openmpi-4.1.0.tar.bz2 /prog
RUN cd /prog \
    && tar xvf openmpi-4.1.0.tar.bz2 \
    && cd openmpi-4.1.0 \
    && ./configure \
    && make install -j5 \
    && cd .. \
    && rm -rf openmpi-4.1.0 openmpi-4.1.0.tar.bz2
ENV LD_LIBRARY_PATH=/usr/local/lib/
WORKDIR /prog/amber20_src/build
ENV AMBERHOME=/prog/amber20_src
RUN apt -y install python3
RUN cd .. && python3 update_amber --update
RUN apt -y remove python3*
RUN  cmake /prog/amber20_src \
    -DCMAKE_INSTALL_PREFIX=/prog/amber20 \
    -DCOMPILER=GNU \
    -DMPI=TRUE -DCUDA=FALSE -DINSTALL_TESTS=FALSE \
    -DDOWNLOAD_MINICONDA=FALSE -DMINICONDA_USE_PY3=FALSE
RUN  make install -j5

#RUN cd build && ./run_cmake && make install -j5
RUN cd /prog && rm -rf amber20_src
ENV AMBERHOME=/prog/amber20
ENV PATH=$PATH:$AMBERHOME/bin
WORKDIR /opt
ENV OMPI_ALLOW_RUN_AS_ROOT=1
ENV OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
ENV AMBERMPI=1
RUN apt -y install ssh

FROM ubuntu:18.04
MAINTAINER Andrea Giachetti <Giachetti@cerm.unifi.it>
LABEL description="Container image to run ambertools with sander MPI"
ENV TZ=Europe/Rome
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt -y update
RUN apt -y upgrade
RUN apt -y install tcsh make \
               gcc gfortran \
               flex bison patch \
               bc xorg-dev libbz2-dev wget \
               cmake ssh
RUN mkdir /prog
COPY openmpi-4.1.0.tar.bz2 /prog
RUN cd /prog \
    && tar xvf openmpi-4.1.0.tar.bz2 \
    && cd openmpi-4.1.0 \
    && ./configure \
    && make install -j5 \
    && cd .. \
    && rm -rf openmpi-4.1.0 openmpi-4.1.0.tar.bz2

COPY --from=build /prog/amber20 /prog/amber20
RUN useradd -ms /bin/bash ambertools
RUN chown -R ambertools:ambertools /prog/amber20
RUN chown -R  ambertools:ambertools /opt
USER ambertools
ENV LD_LIBRARY_PATH=/usr/local/lib/
ENV AMBERHOME=/prog/amber20
ENV PATH=$PATH:$AMBERHOME/bin
WORKDIR /opt
ENV OMPI_ALLOW_RUN_AS_ROOT=1
ENV OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
ENV AMBERMPI=1

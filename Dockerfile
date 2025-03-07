# Image: tapis/mpm

FROM fedora:32
MAINTAINER Krishna Kumar <krishnak@utexas.edu>

# Update to latest packages, remove vim-minimal & Install Git, GCC, Clang, Autotools and VIM
RUN dnf update -y && \
    dnf remove -y vim-minimal sqlite && \
    dnf install -y boost boost-devel clang clang-analyzer clang-tools-extra cmake cppcheck dnf-plugins-core \
                   diffutils eigen3-devel findutils freeglut freeglut-devel gcc gcc-c++ git hdf5 hdf5-devel \
                   kernel-devel lcov libnsl libXext libXext-devel make ninja-build openblas openblas-devel \
                   openblas-openmp python pip tar tbb tbb-devel \
                   valgrind vim vtk vtk-devel wget && \
dnf clean all

# Install GMSH
# RUN git clone https://gitlab.onelab.info/gmsh/gmsh.git --depth 1
# RUN cd gmsh && mkdir build && cd build && cmake -DENABLE_BUILD_DYNAMIC=1 .. && make && make install && export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib64/

# Install MKL
RUN dnf config-manager --add-repo https://yum.repos.intel.com/mkl/setup/intel-mkl.repo && \
    rpm --import https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB && \
    dnf install -y intel-mkl
    
# Install Intel MPI
RUN dnf config-manager --add-repo https://yum.repos.intel.com/mpi/setup/intel-mpi.repo && \
    rpm --import https://yum.repos.intel.com/mpi/setup/PUBLIC_KEY.PUB && \
    dnf install -y intel-mpi-2019.8-108.x86_64
    
# Create a user cbgeo
RUN useradd cbgeo
USER cbgeo

# Install pandas and tables
RUN pip3 install pandas tables --user

# Configure MKL
RUN echo "source /opt/intel/bin/compilervars.sh -arch intel64 -platform linux" >> ~/.bashrc
RUN echo "source /opt/intel/mkl/bin/mklvars.sh intel64" >> ~/.bashrc

# Configure MPI
RUN echo "source /opt/intel/compilers_and_libraries_2020.2.254/linux/mpi/intel64/bin/mpivars.sh" >> ~/.bashrc
RUN source /opt/intel/compilers_and_libraries_2020.2.254/linux/mpi/intel64/bin/mpivars.sh

# KaHIP
RUN cd /home/cbgeo/ && git clone https://github.com/schulzchristian/KaHIP.git && \
    source /opt/intel/compilers_and_libraries_2020.2.254/linux/mpi/intel64/bin/mpivars.sh && \
    cd KaHIP && sh ./compile_withcmake.sh -DCMAKE_CXX_COMPILER=mpicxx

# Partio
RUN cd /home/cbgeo/ && git clone https://github.com/wdas/partio.git && \
    cd partio && cmake . && make

# Create a research directory and clone git repo of mpm code
RUN mkdir -p /home/cbgeo/research && \
    cd /home/cbgeo/research && \
    source /opt/intel/compilers_and_libraries_2020.2.254/linux/mpi/intel64/bin/mpivars.sh  && \
    git clone https://github.com/cb-geo/mpm.git && cd mpm && mkdir -p build && cd build && \
    export CXX_COMPILER=mpicxx && \
    cmake -GNinja -DCMAKE_CXX_COMPILER=mpicxx -DCMAKE_EXPORT_COMPILE_COMMANDS=On -DKAHIP_ROOT=/home/cbgeo/KaHIP/ -DPARTIO_ROOT=/home/cbgeo/partio/ .. && \
    ninja -j2

# Clone benchmarks repo
RUN cd /home/cbgeo/research && git clone https://github.com/cb-geo/mpm-benchmarks.git 

# Done
WORKDIR /home/cbgeo/research/mpm/build

# Tapis things ----
USER root
RUN chmod 777 -R /home/cbgeo
RUN mkdir -p /TapisInput
RUN mkdir -p /TapisOutput/results
RUN chmod 777 -R /TapisInput
RUN chmod 777 -R /TapisOutput
ADD entrypoint.sh /home/cbgeo/research/mpm/build/
RUN chmod 777 /home/cbgeo/research/mpm/build/entrypoint.sh


USER cbgeo
#RUN chmod +x /home/cbgeo/research/mpm/build/entrypoint.sh
ENTRYPOINT ["./entrypoint.sh"]

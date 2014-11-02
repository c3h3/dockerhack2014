FROM c3h3/oblas-py278-shogun

EXPOSE 8888
ENV IPYNB_PROFILE "c3h3-dark"
#ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/usr/local/lib

RUN git clone https://github.com/c3h3/oblas-py278-shogun-demo /demo_ipynbs
RUN cd /demo_ipynbs && git submodule init && git submodule update

WORKDIR demo_ipynbs

RUN pip install networkx
RUN ipython profile create c3h3-dark

ADD c3h3_custom.csss /root/.ipython/profile_c3h3-dark/static/custom/custom.css
ADD ipython_notebook_config.py /root/.ipython/profile_c3h3-dark/ipython_notebook_config.py
CMD ipython notebook --no-browser --ip=0.0.0.0 --port 8888 --profile=$IPYNB_PROFILE


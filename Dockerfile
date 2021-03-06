# Magenta Dockerfile for Anaconda with TensorFlow stack
# Copyright (C) 2020  Chelsea E. Manning
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

FROM xychelsea/tensorflow:v0.1.2
LABEL description="Magenta Vanilla Container"

# $ docker build -t xychelsea/magenta:latest -f Dockerfile .
# $ docker run --rm -it xychelsea/magenta:latest /bin/bash
# $ docker push xychelsea/magenta:latest

ENV ANACONDA_ENV=magenta
ENV MAGENTA_PATH=/usr/local/magenta
ENV MAGENTA_HOME=${HOME}/magenta
ENV MAGENTA_MODELS=${MAGENTA_PATH}/magenta/models/
ENV MAGENTA_WORKSPACE=${MAGENTA_PATH}/workspace

# Start as root
USER root

# Update packages
RUN apt-get update --fix-missing \
    && apt-get -y upgrade \
    && apt-get -y dist-upgrade

# Install dependencies
RUN apt-get -y install \
    build-essential \
    fluid-soundfont-gm \
    git \
    libasound2-dev \
    libfluidsynth2 \
    libjack-dev \
    portaudio19-dev

# Create Magenta directory
RUN mkdir -p ${MAGENTA_PATH} \
    && fix-permissions ${MAGENTA_PATH}

# Switch to user "anaconda"
USER ${ANACONDA_UID}
WORKDIR ${HOME}

# Update Anaconda
RUN conda update -c defaults conda

# Install Magenta
RUN conda create -n magenta \
    && conda install -c conda-forge -n magenta \
        absl-py \
        cloudpickle \
        dm-sonnet \
        imageio \
        librosa \
        matplotlib \
        mir_eval \
        numba \
        numpy \
        pillow \
        pip \
        pygtrie \
        scikit-image \
        scipy \
        six \
        sk-video \
        sox \
        tensorflow-datasets \
        tensorflow-probability \
        tf-slim \
        wheel \
    && rm -rvf ${ANACONDA_PATH}/share/jupyter/lab/staging

RUN git clone git://github.com/magenta/magenta.git ${MAGENTA_PATH}

COPY ./scripts/setup.py ${MAGENTA_PATH}/setup.py

RUN pip install magenta -e ${MAGENTA_PATH}

# Switch back to root
USER root

# Install pre-trained models
ADD http://download.magenta.tensorflow.org/models/lookback_rnn.mag ${MAGENTA_MODELS}
ADD http://download.magenta.tensorflow.org/models/attention_rnn.mag ${MAGENTA_MODELS}
ADD http://download.magenta.tensorflow.org/models/basic_rnn.mag ${MAGENTA_MODELS}
ADD http://download.magenta.tensorflow.org/models/drum_kit_rnn.mag ${MAGENTA_MODELS}
ADD http://download.magenta.tensorflow.org/models/polyphony_rnn.mag ${MAGENTA_MODELS}
ADD http://download.magenta.tensorflow.org/models/rl_rnn.mag ${MAGENTA_MODELS}
ADD http://download.magenta.tensorflow.org/models/rl_tuner_note_rnn.ckpt ${MAGENTA_MODELS}

ADD http://download.magenta.tensorflow.org/models/multistyle-pastiche-generator-monet.ckpt ${MAGENTA_MODELS}
ADD http://download.magenta.tensorflow.org/models/multistyle-pastiche-generator-varied.ckpt ${MAGENTA_MODELS}

RUN mkdir -p ${MAGENTA_WORKSPACE} \
    && fix-permissions ${MAGENTA_WORKSPACE} \
    && fix-permissions ${MAGENTA_MODELS} \
    && ln -s ${MAGENTA_PATH}/magenta ${HOME}/magenta \
    && ln -s ${MAGENTA_WORKSPACE} ${HOME}/workspace

# Clean Anaconda
RUN conda clean -afy

# Clean packages and caches
RUN apt-get --purge -y autoremove git \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* \
    && rm -rvf /home/${ANACONDA_PATH}/.cache/yarn \
    && fix-permissions ${HOME} \
    && fix-permissions ${ANACONDA_PATH}

# Re-activate user "anaconda"
USER $ANACONDA_UID
WORKDIR $HOME

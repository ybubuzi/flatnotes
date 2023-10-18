ARG BUILD_DIR=/build

# Build Container
FROM --platform=linux/amd64  python:3.11-slim-bullseye AS build

ARG BUILD_DIR

RUN mkdir ${BUILD_DIR}
WORKDIR ${BUILD_DIR}

RUN apt update && apt install -y npm

COPY package.json package-lock.json .htmlnanorc ./
RUN npm ci

COPY flatnotes/src ./flatnotes/src
RUN npm run 



# Runtime Container
FROM python:3.11-slim-bullseye

ARG BUILD_DIR

ENV PUID=1000
ENV PGID=1000

ENV APP_PATH=/app
ENV FLATNOTES_PATH=/data

RUN mkdir -p ${APP_PATH}
RUN mkdir -p ${FLATNOTES_PATH}

RUN apt update && apt install -y gosu \
    && rm -rf /var/lib/apt/lists/*

RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

RUN pip install pipenv

WORKDIR ${APP_PATH}



COPY LICENSE Pipfile Pipfile.lock ./
RUN pipenv install --deploy --ignore-pipfile --system

COPY flatnotes ./flatnotes
COPY --from=build ${BUILD_DIR}/flatnotes/dist ./flatnotes/dist

VOLUME /data
EXPOSE 8080/tcp

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential \
    qtbase5-dev \
    qtbase5-dev-tools \
    qt5-qmake \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .
RUN qmake server.pro && make

# БД хранится в volume, путь задаётся через env
ENV DB_PATH=/app/data/campus_helper.db
RUN mkdir -p /app/data

EXPOSE 45454
CMD ["./server"]
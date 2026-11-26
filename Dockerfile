FROM python:3.15.2-alpine3.24
# apk upgrade: the python image lags behind the alpine package repo.
# pip goes after the install, with the CVEs in its vendored packages.
COPY requirements.txt /tmp/requirements.txt
RUN apk upgrade --no-cache \
    && pip install --no-cache-dir --only-binary=:all: -r /tmp/requirements.txt \
    && pip uninstall -y pip \
    && rm /tmp/requirements.txt \
    && adduser -D -H -u 10001 gotify-mcp
WORKDIR /opt/gotify-mcp
COPY ./server.py .
USER gotify-mcp
EXPOSE 8080
ENTRYPOINT ["python3", "-I", "-u", "server.py"]

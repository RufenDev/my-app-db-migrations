FROM redgate/flyway:latest

RUN mkdir -p /my-app/flyway

WORKDIR /my-app/flyway

COPY . .

CMD ["migrate"]
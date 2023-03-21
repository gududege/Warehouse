FROM docker:20.10.23-cli
USER root
WORKDIR /runner
ENV GITEA_URL=\
GITEA_RUNNER_TOKEN=
RUN apk add curl && curl -o ./act_runner -s https://dl.gitea.com/act_runner/main/act_runner-main-linux-amd64 && chmod 775 ./act_runner
CMD ["sh", "-c", "./act_runner register --instance $GITEA_URL --token $GITEA_RUNNER_TOKEN --no-interactive && ./act_runner daemon"]
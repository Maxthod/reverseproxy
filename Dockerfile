FROM nginx
COPY ./data/nginx /etc/nginx/conf.d/

RUN apt update
RUN apt install -y letsencrypt


ADD run.sh /usr/local/bin/run.sh
RUN chmod u+x /usr/local/bin/run.sh
ENTRYPOINT "/usr/local/bin/run.sh"


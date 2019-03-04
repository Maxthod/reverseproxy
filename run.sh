#!/bin/bash
#set -e
base="/etc/letsencrypt/"
rsa_key_size=4096

prepareNginx () {
    
    declare -a domains=("${!1}")
    echo "### Domain name $domains"

    live="$base/live/$domains"
    renewal="$base/renewal/$domains.conf"
    archive="$base/archive/$domains"
    todelete="$base/todelete-$domains"

    if [ ! -d "$live" ]; then
        echo "### Sll prepartion for $domains"

        echo "### Creating $live ..."
        mkdir -p $live

        echo "### Creating penssl keys/chains ..."
        openssl req -x509 -nodes -newkey rsa:1024 -days 1\
            -keyout "$live/privkey.pem" \
            -out "$live/fullchain.pem" \
            -subj '/CN=localhost'

        echo "### Certificated created."
        
        touch $todelete
    else  
        echo "$domains exist already."
    fi
    
}

clearKeys () {
    echo "### Clean dummies"
    
    declare -a domains=("${!1}")

    live="$base/live/$domains"
    archive="$base/archive/$domains"
    renewal="$base/renewal/$domains.conf"
    todelete="$base/todelete-$domains"

    if [ -f "$todelete" ]; then
        echo "### Cleaning dummies ..."
        rm -Rf $live
        rm -Rf $archive
        rm -Rf $renewal
        echo "### Dummies cleaned."
    else  
        echo "$domains had no dummies."
    fi
     
}


registerSSL () {
    email=$EMAIL
    staging=$STAGING

    declare -a domains=("${!1}")

    live="$base/live/$domains"
    archive="$base/archive/$domains"
    renewal="$base/renewal/$domains.conf"
    todelete="$base/todelete-$domains"

    if [ -f "$todelete" ]; then
        echo "### Requesting Let's Encrypt certificate for $domains ..."

        domain_args=""
        for domain in "${!1}"; do
          domain_args="$domain_args -d $domain"
        done


        # Select appropriate email arg
        case "$email" in
          "") email_arg="--register-unsafely-without-email" ;;
          *) email_arg="--email $email" ;;
        esac

        # Enable staging mode if needed
        if [[ -z $staging && $staging == "true" ]]; then staging_arg="--staging"; fi



        echo "### Launching certbot ..."
        certbot certonly --webroot -w /var/www/certbot \
            $staging_arg \
            $email_arg \
            $domain_args \
            --rsa-key-size $rsa_key_size \
            --agree-tos
        
        echo "### Cerbot laucnhed."

        echo "### Cleanup ..."
        rm "$todelete"
        echo "### Cleaned."


    else  
        echo "$domains certificates ready."
    fi


    
}

afunc(){

   ### LIST DOMAIN HERE


   #local domain1=(
   #     "superhero.philippeduval.ca"
   #     "www.superhero.philippeduval.ca"
   #)


   local domain1=(
        "superhero.philippeduval.ca"
    )

    local domain2=(
        "jenkins.philippeduval.ca"
    )

     local domain3=(
        "dockertest.philippeduval.ca"
    )

    echo "### Creating directories for certbox ..."
    mkdir -p /var/www/certbot
    chmod -R 777 /var/www/certbot
    echo "### Directories created."

    ### REGISTER DOMAIN HERE
    ### REGISTER DOMAIN HERE
    ### REGISTER DOMAIN HERE
    prepareNginx domain1[@]
    prepareNginx domain2[@]
    prepareNginx domain3[@]
   
    echo "### Starting nginx ... "
    service nginx start

    while [ ! -e /var/run/nginx.pid ]
    do
        echo "Nginx didnt started"
        sleep 5s
    done

    if [ -e /var/run/nginx.pid ]; then 
        echo "### Nginx started."; 

        ### AND HERE
        ### AND HERE
        ### AND HERE

        clearKeys domain1[@]
        clearKeys domain2[@]
        clearKeys domain3[@]
      
        ### AND HERE
        ### AND HERE
        ### AND HERE
        registerSSL domain1[@]
        registerSSL domain2[@]
        registerSSL domain3[@]

        echo "### Reloading nginx ..."
        service nginx reload

        
        if [ -e /var/run/nginx.pid ]; then 
            echo "### Nginx reloaded."; 
            echo "### Certbot renew every 12h ..."
            while :; do certbot renew; sleep 12h; done;
            echo "Certbot renew loop stopped."
        else 
            echo "### Nginx didnt reload."; 
        fi
        
    else 
        
        echo "### Nginx didnt started."; 
        while :; do sleep 12h; done;
    
    fi

    
    


}

afunc

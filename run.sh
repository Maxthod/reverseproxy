#!/bin/bash
#set -e
base="/etc/letsencrypt/"
rsa_key_size=4096

stringToSearch="SSL domain names"
prefix="server_name"
confDirectory="/etc/nginx/conf.d/*"

prepareNginx () {
    
    declare -a domain=$1
    echo "### Domain name $domain"

    live="$base/live/$domain"
    renewal="$base/renewal/$domain.conf"
    archive="$base/archive/$domain"
    todelete="$base/todelete-$domain"

    if [ ! -d "$live" ]; then
        echo "### Sll prepartion for $domain"

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
        echo "$domain exist already."
    fi
    
}

clearKeys () {
    echo "### Clean dummies"
    
    local domain=$1

    live="$base/live/$domain"
    archive="$base/archive/$domain"
    renewal="$base/renewal/$domain.conf"
    todelete="$base/todelete-$domain"

    if [ -f "$todelete" ]; then
        echo "### Cleaning dummies ..."
        rm -Rf $live
        rm -Rf $archive
        rm -Rf $renewal
        echo "### Dummies cleaned."
    else  
        echo "$domain had no dummies."
    fi
     
}


registerSSL () {
    email=$EMAIL
    staging=$STAGING

    local domain=$1
    local domains=$2

    live="$base/live/$domain"
    archive="$base/archive/$domain"
    renewal="$base/renewal/$domain.conf"
    todelete="$base/todelete-$domain"

    if [ -f "$todelete" ]; then
        echo "### Requesting Let's Encrypt certificate for $domain ..."

        IFS=' ' read -ra LIST_DOMAIN_NAME <<< "$domains"

        domain_args=""
        for domain_name in "${LIST_DOMAIN_NAME[@]}"; do
          domain_args="$domain_args -d $domain_name"
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
        
        echo "### Cerbot launched."

        echo "### Cleanup ..."
        rm "$todelete"
        echo "### Cleaned."


    else  
        echo "$domains certificates ready."
    fi


    
}

afunc(){


    echo "### Creating directories for certbox ..."
    mkdir -p /var/www/certbot
    chmod -R 777 /var/www/certbot
    echo "### Directories created."

   ### LIST DOMAIN HERE
   local domains=""

    for file in $(grep -lir "$stringToSearch" $confDirectory)
    do
        domain=$(awk "/$stringToSearch/{getline; print}" $file)
        domain=$(echo $domain | xargs)
        domain=${domain#$prefix}
        domain=${domain%?}
        domains+="$domain;"
    done

    domains=${domains%?}

    IFS=';' read -ra domain_names <<< "$domains"
    
    for domain_name in "${domain_names[@]}"; do
        echo "Domaine : $domain_name"

        IFS=' ' read -ra LIST_DOMAIN_NAME <<< "$domain_name"

        FIRST_DOMAINE_NAME="${LIST_DOMAIN_NAME[0]}"

        prepareNginx "$FIRST_DOMAINE_NAME"
    done


    echo "### Starting nginx ... "
    service nginx start

    while [ ! -e /var/run/nginx.pid ]
    do
        echo "Nginx didnt started"
        sleep 5s
    done

    if [ -e /var/run/nginx.pid ]; then 
        echo "### Nginx started."; 

        for domain_name in "${domain_names[@]}"; do
            echo "Domaine : $domain_name"

            IFS=' ' read -ra LIST_DOMAIN_NAME <<< "$domain_name"

            FIRST_DOMAINE_NAME="${LIST_DOMAIN_NAME[0]}"
            
            clearKeys "$FIRST_DOMAINE_NAME"

            registerSSL "$FIRST_DOMAINE_NAME" "$domain_name"
            
        done

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
        
        echo "### Service Nginx failed to start."; 
        while :; do sleep 12h; done;
    
    fi

}

afunc

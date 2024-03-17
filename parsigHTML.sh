#!/bin/bash

running=1

draw_layout() {
    clear # Limpa o terminal para o novo layout
    height=$(tput lines) # Altura atual do terminal
    width=$(tput cols) # Largura atual do terminal
    
    local host=$1
    local title=" NFSOCIETY "
    local script_length=${#title}
    local left_padding=$(( (width / 2) - (script_length / 2) ))

    printf '%*s' "$left_padding" '' | tr ' ' '#'
    echo -n "$title"
    printf '%*s\n' $((width - left_padding - script_length)) '' | tr ' ' '#'

    # Calcula o número de linhas disponíveis para o corpo do script
    body_height=$((height - 4)) 

    for ((i=1; i<=body_height; i++))
    do
        if [ $i -eq $((body_height / 2)) ]; then
            parse_html "$1"
        fi
    done

    printf '%*s\n' "${COLUMNS:-$width}" '' | tr ' ' '#'
}

parse_html() {
    if [ "$1" == "" ]
    then
	    echo "URL não fornecida"
	    running=0
    else	    
	local html_content=$(wget -qO- "$1")
   	local title=$(echo "$html_content" | grep -oP '(?<=<title>)(.*)(?=</title>)' | head -1)
    	echo
    	printf "%*s\n\n" $(( (width + ${#title}) / 2 )) "Título da página: $title"
    	printf "[+] Buscando Hosts...\n\n"
    	sleep 2
	local domains=$(echo "$html_content" | grep "a href" | cut -d "/" -f3 | cut -d '"' -f1 | grep -v ">"  | grep -v "<" | sort -u)
	domains=$(echo "$domains" | grep -v '^$')
	local domains_size=$(echo "$domains" | wc -l)
	printf "[+] Encontrados $domains_size domínios únicos.\n"
	sleep 2
	
	host_resolver "$domains" "$1"

    fi
}

host_resolver() {
    local domains="$1"
    local filename="./scans/domains-$(echo "$2" | sed 's/[^a-zA-Z0-9]/_/g').txt" # Cria um nome de arquivo seguro
    printf "[+] Resolvendo Hosts...\n\n"
    
    # Define larguras para cada coluna
    local line_width=5
    local address_width=30
    local ip_width=15


    printf "%-${line_width}s %-${address_width}s %s\n" "LINE" "ADDRESS" "IP"
    printf "%-5s %-30s %s\n" "LINE" "ADDRESS" "IP" > "$filename"
    index=1
    for host in $domains; do
        # Resolve o IP do host
        local ip=$(host $host | grep "has address" | cut -d " " -f4)
        if [ -z "$ip" ]; then
            ip="NF"
        fi

        # Formata a saída para cada linha
        printf "%-5d %-30s %-15s\n" "$index" "$host" "$ip" | tee -a "$filename"
        ((index++))
    done
    
    printf "\n[+] Salvando os resultados em $filename...\n\n"
}

trap draw_layout SIGWINCH # Captura redimensionamento do terminal
[[ ! -d "./scans" ]] && mkdir -p "./scans"
draw_layout $1 # Desenha o layout inicial

while [ "$running" = 1 ]; do sleep 1; done # Mantém o script executando


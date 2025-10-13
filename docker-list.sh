# Colar este conteúdo:
#!/bin/bash
echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║                     CONTAINERS ATIVOS                                      ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
printf "\n%-25s %-18s %-35s\n" "CONTAINER" "IP" "PORTAS"
echo "-------------------------------------------------------------------------------"
docker ps -q | while read cid; do
    name=$(docker inspect -f '{{.Name}}' $cid | sed 's/\///')
    ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $cid)
    ports=$(docker inspect -f '{{range $p, $conf := .NetworkSettings.Ports}}{{if $conf}}{{$p}}->{{(index $conf 0).HostPort}} {{end}}{{end}}' $cid)
    printf "%-25s %-18s %-35s\n" "$name" "$ip" "$ports"
done
echo ""


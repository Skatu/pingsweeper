#!/bin/bash

#Variável que guardará o ficheiro recebido como parâmetro
ip_list=$1
#Variáveis que guardarão a contagem de cada tipo de ips (ativos, inativos e inválidos)
inactiveIps=0
invalidIps=0
activeIps=0

#A variável "n" é o contador que guarda o número de tentativas caso o utilizador não tenha passado o parâmetro ao invocar o script
n=1
#b

#Se o número de parâmetros passados for diferente de 1, pede ao utilizador para inserir o ficheiro manualmente
if [ $# -ne 1 ]; then
	echo "Tentativa 1 de 3"
	echo "Ficheiro não inserido como parâmetro."
	read -p "Inserir ficheiro: " ip_list
	n=$((n+1))
	sleep 1
fi

#c

#Se o utilizador ultrapassar as 3 tentativas ou inserir um parâmetro válido, então o programa sai do loop
while [ $n -le 3 ] && [ ! -f "$ip_list" ]
do
	echo ""
	echo "Ficheiro inválido."
	echo "Tentativa $n de 3"
	read -p "Inserir ficheiro válido: " ip_list
	if [ ! -f "$ip_list" ];then
		n=$((n+1))
	fi
	sleep 1
done

#Caso o utilizador ultrapasse as 3 tentativas, o programa é fechado.
if [ $n -gt 3 ]
	then
		echo "Número máximo de tentativas excedidas. A fechar programa..."
		sleep 1
		echo ""
		exit 1 
fi
#Verificação do ip
for ip in $(cat $ip_list)
do
	#Guardar na variável "res" só os elementos que contem 4 conjunto de números separados por pontos
	res=$(echo "$ip" | grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$")

	#Se "res" for vazia, então a linha do ficheiro não é um ip e guarda o resultado no ficheiro "invalidIps.tmp"
	#e incrementa o contador "$invalidIps"
	if [ -z $res ]; then
		echo "$ip não é um ip."
		echo $ip >> invalidIps.tmp
		invalidIps=$((invalidIps+1))
		continue
	fi
	#Se passar o teste anterior, guardar cada octeto numa váriavel
	o1=$(echo $ip | cut -d. -f1)
	o2=$(echo $ip | cut -d. -f2)
	o3=$(echo $ip | cut -d. -f3)
	o4=$(echo $ip | cut -d. -f4)

	#Se algum dos octetos for maior que 255, falha o teste e guarda o resultado no ficheiro "invalidIps.tmp"
	#e incrementa o contador "$invalidIps"
	if [ $o1 -gt 255 ] || [ $o2 -gt 255 ] || [ $o3 -gt 255 ] || [ $o4 -gt 255 ] ; then
		echo "$ip é um ip inválido"
		echo $ip >> invalidIps.tmp
		invalidIps=$((invalidIps+1))
		continue
	fi

	#Se passar ambos os testes, testar o ping do endereço.
	#Se log retornar algures a frase "100% packet loss", guarda o resultado no ficheiro "inactiveIps.tmp"
	#e incrementa o contador "$inactiveIps"
	log=$(ping -c 1 $ip | grep "100% packet loss")

	#if [[ $log = *"100% packet loss"* ]]; then
	if [ -z "$log" ]; then
		echo $ip >> inactiveIps.tmp
		inactiveIps=$((inactiveIps+1))
		echo "O ip $ip tem loss de 100% de packets"
		continue
	else
		echo $ip >> activeIps.tmp
		activeIps=$((activeIps+1))
	fi
done

#Criar o ficheiro "reachability_test.txt"
if [ -f "reachability_test.txt" ];then
	rm reachability_test.txt
fi

touch reachability_test.txt

#Escrever para o ficheiro "reachability_test.txt" 
 echo "Número de Ips ativos: $activeIps" >reachability_test.txt
 echo "Lista de ips ativos" >> reachability_test.txt
 cat activeIps.tmp >> reachability_test.txt
 echo "" >> reachability_test.txt

 echo "Número de Ips inativos: $inactiveIps" >>reachability_test.txt
 echo "Lista de ips inativos" >> reachability_test.txt
 cat inactiveIps.tmp >> reachability_test.txt
 echo "" >> reachability_test.txt

 echo "Número de Ips inválidos: $invalidIps" >>reachability_test.txt
 echo "Lista de ips inválidos" >> reachability_test.txt
 cat invalidIps.tmp >> reachability_test.txt
 echo "" >> reachability_test.txt

#Eliminar os ficheiros temporários
rm activeIps.tmp
rm inactiveIps.tmp
rm invalidIps.tmp

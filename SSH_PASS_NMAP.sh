#!/bin/bash


#SSH_PASS function = after the remote server details that shown to the script runner the funtion uses sshpass to to connect to the remote server and running
#there whois and nmap saving them into a file format and copy them to the local machine with scp and removing them from the remote server

function  SSH_PASS()
{
	SSH_DETAILS
	
	echo "please enter target ip..."
	read TARGET_IP
	
	sshpass -p "$password" ssh -o StrictHostKeyChecking=no "$host"@"$ip" "whois  $TARGET_IP > /home/$host/whois.txt"
	sshpass -p "$password" ssh -o StrictHostKeyChecking=no "$host"@"$ip" "nmap $TARGET_IP -sV -oG /home/$host/nmap.txt"
	sshpass -p "$password" scp "$host"@"$ip":/home/"$host"/whois.txt /home/kali/
	sshpass -p "$password" scp "$host"@"$ip":/home/"$host"/nmap.txt /home/kali/
	sshpass -p "$password" ssh -o StrictHostKeyChecking=no "$host"@"$ip" "rm /home/\"$host\"/whois.txt"
	sshpass -p "$password" ssh -o StrictHostKeyChecking=no "$host"@"$ip" "rm /home/\"$host\"/nmap.txt "
}

#SSH_DETAILS function = shows the details of the remote server with sshpass commands and prints them on the terminal

function SSH_DETAILS()
{
	SSH_IP=$(sshpass -p "$password" ssh -o StrictHostKeyChecking=no "$host"@"$ip" "echo "$password" | sudo -S curl ifconfig.me") #using $password with sudo -S becasue all commands needs sudo
	SSH_UPTIME=$(sshpass -p "$password" ssh -o StrictHostKeyChecking=no "$host"@"$ip" "echo "$password" | sudo -S uptime")
	SSH_COUNTRY=$(sshpass -p "$password" ssh -o StrictHostKeyChecking=no "$host"@"$ip" "echo "$password" | sudo -S apt-get install geoip-bin | geoiplookup "$SSH_IP" ")
	
	echo "_"
	echo "the remote server ip is $SSH_IP"
	echo "the remote server uptime is $SSH_UPTIME"
	echo "the remote server country is $SSH_COUNTRY"
}

#NIPE_CHECKER function = cheking if the machine that is running the script has nipe allready or not, if the maschine dosent have nipe the script installing it with NIPE_INSTALLER

function NIPE_CHECKER()
{
	echo "checking if nipe is installed..."
	if [ -d "/home/$host/nipe" ]
	then
		echo "nipe is installed"
	else
		echo "nipe is not installed... instailling now"
		NIPE_INSTALLER
	fi
}

#NIPE_WORKING function = cheking if nipe is working (annoymous or not), with a simple if statement that shows if you are not from israel and what country you are from now 

function NIPE_WORKING()
{	
	cd nipe
	echo "cheking if you using NIPE correctly (if you are annoymous)..."
	sudo perl nipe.pl start
	sudo perl nipe.pl restart #sometimes nipe is not working corecetly so i restart it just in case
	ADDR=$(sudo perl nipe.pl status | grep Ip | awk '{print $3}')
	COUNTRY=$(geoiplookup $ADDR | awk '{print $NF}')
	
	if [ '$COUNTRY' == 'Israel' ]
	then
		echo "you are not annoymous... exiting"
		exit
	else
		echo "you are annoymous - Country:$COUNTRY (NIPE is working correctly)"
	fi
}


#NIPE_INSTALLER function = installing nipe and perl moduls from github

function NIPE_INSTALLER()
{	
	git clone https://github.com/htrgouvea/nipe && cd nipe
	cpanm --installdeps .
	sudo cpan install try::Tiny Config::Simple JSON
	sudo perl nipe.pl install
}
#START fuction = gets all the information for the other functions with "read"

function START()

{
	echo "what is the ip address of the remote server?"
	read ip
	
	echo "what is the host name of the remote server?"
	read host
	
	echo "what is the password of the remote server?"
	read -s password
}


#the order of the entire script

figlet "NMAP and WHOIS on SSHPASS"
START
NIPE_CHECKER
NIPE_WORKING
SSH_PASS

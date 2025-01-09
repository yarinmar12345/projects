#!/bin/bash

home=$(pwd)

LIST_TOOLS=("nmap" "medusa" "masscan" "exploitdb" "crunch")

KEYWORDS() # Using text manipulation to get keyword that the user want from the results
{
    read -p "Would you like to search within the results? [yes/no]: " answer
    answer="${answer,,}" # Convert to lowercase

    if [[ "$answer" == "yes" ]]; then
        read -p "Enter the keyword(s) to search for: " keyw0rds
        echo
        if ! grep -iR "$keyw0rds"; then
            echo "No matches found for '$keyw0rds'."
        fi
        echo
    elif [[ "$answer" != "no" ]]; then
        echo  "Invalid option. Please try again."
        KEYWORDS
    fi
}

ZIP() # Zip the results to a zip file that the user want
{
    read -p "Would you like to compress the results into a ZIP file? [yes/no]: " answer
    answer="${answer,,}" # Convert input to lowercase

    if [[ "$answer" == "yes" ]]; then
        zip -r "${dir_name}.zip" "$home/$dir_name" > /dev/null
        echo "ZIP file created at: $home/$dir_name/${dir_name}.zip"
    elif [[ "$answer" != "no" ]]; then
        echo "Invalid input. Please try again."
        ZIP
    fi
}


END() # Ending function
{
	echo "the results are saved in $dir_name directory"
	KEYWORDS
	ZIP
	echo "The end of the script, you can keep using it, hope you like it :)"
}


EXPLOIT_FINDER() # Using searchsploit to find the service that the user want
{
	echo
	read -p "please enter the service you want to find exploits for: " service
	DB_SEARCHSPLOIT "$service"
	echo
	echo "please enter 'again' if you want to search again for exploits for another service and insert anything else if you don't want: "
	read input
	if [[ "${input,,}" == "again" ]]
	then
		EXPLOIT_FINDER
	fi
}
 
 
EXPLOIT_CHECK() # 
{
	read -p "do you want to use searchsploit? [yes/no]: " var
	
	if [[ "${var,,}" == "yes" ]]
	then
		for ip in $ip_list
		do
			{
				if grep -q '[^[:space:]]' "$home/$dir_name/${ip}_nmap.txt"
				then
					echo "the version services of the ip $ip are:"
					cat "$home/$dir_name/${ip}_nmap.txt"
				fi
			}
		done
		EXPLOIT_FINDER
	else
		if [[ "${var,,}" != "no" ]]
		then
			echo "you inserted invalid option please try again"
			EXPLOIT_CHECK
		fi
	fi
	
}

DB_SEARCHSPLOIT() # Searchigng for exploits or vulnerabilities using seachsploit
{
	echo "showing results of exploits for every ip"
	
	for ip in $ip_list;
	do
		{
		
			echo "the exploit results of $ip are:"
			echo
			cat "$home/$dir_name/${ip}_vuln.txt"
			echo
		}
	done
	EXPLOIT_CHECK
}


function FILE_UPLOAD() # Allows the user to upload is own password list to check
{
    read -p "Enter full path to your own password list: " uploaded_file

    for attempt in {1..5}; do
        if [ -f "$uploaded_file" ]; then
            return 0
        fi
        echo -e "\nThe file does not exist. Attempt $attempt of 5."
        read -p "Please enter full path again: " uploaded_file
    done

    echo -e "\nYou have provided incorrect paths 5 times, exiting..."
    exit
}

function CRUNCH() # Using crunch to make a password list that we use to fine weak passwords
{
	read -p "Choose your minimum characters for list of passwords: " min
    read -p "choose your maximum characters for list of passwords: " max

    if ! [[ "$min" =~ ^[0-9]+$ ]] || ! [[ "$max" =~ ^[0-9]+$ ]] || [ "$min" -gt "$max" ]; then
        echo "Invalid input. Ensure you enter numbers and that minimum is not greater than maximum."
        return
    fi
    
    read -p "Please insert the characters you want the list to contain: " string
    crunch "$min" "$max" "$string" -o crunch_list.txt
    echo "The list of passwords saved as crunch_list.txt"
    
    for ip in $ip_list; do
        if [[ -n "$ip" ]]; then # Ensure the IP is not empty
			echo "Using medusa to cheak for weak passwords $ip ..."
			timeout 30 medusa -h "$ip" -U "$home/$dir_name/crunch_list.txt" -P "$home/$dir_name/crunch_list.txt" -M ssh -t 10 -f >> "${ip}_medusa.txt" 2>&1
			timeout 30 medusa -h "$ip" -U "$home/$dir_name/crunch_list.txt" -P "$home/$dir_name/crunch_list.txt" -M rdp -t 10 -f >> "${ip}_medusa.txt" 2>&1
			timeout 30 medusa -h "$ip" -U "$home/$dir_name/crunch_list.txt" -P "$home/$dir_name/crunch_list.txt" -M ftp -t 10 -f >> "${ip}_medusa.txt" 2>&1
			timeout 30 medusa -h "$ip" -U "$home/$dir_name/crunch_list.txt" -P "$home/$dir_name/crunch_list.txt" -M telnet -t 10 -f >> "${ip}_medusa.txt" 2>&1
			echo "Finished..."
		else
			echo "Skipping empty entry in IP list."
        fi
    done
	
	
}

function OWN_LIST() # Using FILE_UPLOAD function to use the user own list to find weak passwords
{
	echo
	FILE_UPLOAD
	echo
	
	for ip in $ip_list; do
        if [[ -n "$ip" ]]; then # Ensure the IP is not empty
			echo "Using medusa to cheak for weak passwords $ip ..."
			timeout 30 medusa -h "$ip" -U $uploaded_file -P $uploaded_file -M ssh -t 10 -f >> "${ip}_medusa.txt" 2>&1
			timeout 30 medusa -h "$ip" -U $uploaded_file -P $uploaded_file -M rdp -t 10 -f >> "${ip}_medusa.txt" 2>&1
			timeout 30 medusa -h "$ip" -U $uploaded_file -P $uploaded_file -M ftp -t 10 -f >> "${ip}_medusa.txt" 2>&1
			timeout 30 medusa -h "$ip" -U $uploaded_file -P $uploaded_file -M telnet -t 10 -f >> "${ip}_medusa.txt" 2>&1
			echo "Finished..."
		else
			echo "Skipping empty entry in IP list."
        fi
    done
}

function DEFAULT() # Using the default password list for weak password from my repository
{
	echo
	git clone https://github.com/yarinmar12345/project_files.git >/dev/null 2>&1
	
	for ip in $ip_list; do
        if [[ -n "$ip" ]]; then # Ensure the IP is not empty
			echo "Using medusa to cheak for weak passwords $ip ..."
			timeout 30 medusa -h "$ip" -U "$home/$dir_name/project_files/default_list" -P "$home/$dir_name/project_files/default_list" -M ssh -t 10 -f >> "${ip}_medusa.txt" 2>&1
			timeout 30 medusa -h "$ip" -U "$home/$dir_name/project_files/default_list" -P "$home/$dir_name/project_files/default_list" -M rdp -t 10 -f >> "${ip}_medusa.txt" 2>&1
			timeout 30 medusa -h "$ip" -U "$home/$dir_name/project_files/default_list" -P "$home/$dir_name/project_files/default_list" -M ftp -t 10 -f >> "${ip}_medusa.txt" 2>&1
			timeout 30 medusa -h "$ip" -U "$home/$dir_name/project_files/default_list" -P "$home/$dir_name/project_files/default_list" -M telnet -t 10 -f >> "${ip}_medusa.txt" 2>&1
			echo "Finished..."
		else
			echo "Skipping empty entry in IP list."
        fi
    done
	
}

function WEAK_PASSWORDS() # Using case to allows the user to choose what he want to do with what function to check for weak passwords
{
	echo -e "what do you want to do now? \n{1} using the default pass_list to check for week passwords. \n{2} using your own pass_list to check for week passwords. \n{3} using crunch to create your own list."
	read -p "Enter your choice (1, 2, 3): " num
	
	case $num in
	1)
		DEFAULT
		;;
	
	2)
		OWN_LIST
		;;
	
	3)
		CRUNCH
		;;
	
	*) echo "Invalid input - please try again (1, 2, 3)."
		WEEK_PASSWORDS
		;;
	
	esac
}

function INSTALL_TOOLS() # Installing the required tools for the script and checking if there all ready exist
{
	echo "Checking for tools..."
	
	for tool in "${LIST_TOOLS[@]}"; do
		dpkg -s "$tool" >/dev/null 2>&1 ||
		(echo -e "[*] installing the tool $tool.." &&
		sudo apt-get install "$tool" -y >/dev/null 2>&1)
		echo "The tool $tool is installed on the machine."
	done
}

function FULL() # The more complete scan using more tools and function for more inforamtion
{
	echo
	INSTALL_TOOLS
	echo
	
	for ip in $ip_list; do
        if [[ -n "$ip" ]]; then # Ensure the IP is not empty
			echo "Scanning $ip ..."
			timeout 30 nmap "$ip" -sV -F | grep open | awk '{for (i=4; i<=NF; i++) printf "%s ", $i; print ""}' > "$home/$dir_name/${ip}_nmap.txt" 2>&1
			timeout 30 masscan "$ip" -p U:1-100 > "$home/$dir_name/${ip}_masscan.txt" 2>&1
			timeout 30 nmap "$ip" -sV -sC --script=ftp-brute.nse -oN "$home/$dir_name/${ip}_brute.txt" > /dev/null 2>&1
			timeout 30 nmap "$ip" -F -sV -sC --script=vulners.nse -oN "$home/$dir_name/${ip}_vuln.txt" > /dev/null 2>&1
			echo "Finished..."
		else
			echo "Skipping empty entry in IP list."
        fi
    done
    
    DB_SEARCHSPLOIT
    END
}

function BASIC() # The basic scan 
{
	echo
	INSTALL_TOOLS
	echo
	
    for ip in $ip_list; do
        if [[ -n "$ip" ]]; then # Ensure the IP is not empty
            echo "Scanning $ip ..."
            timeout 30 nmap "$ip" -sV -F | grep open | awk '{for (i=4; i<=NF; i++) printf "%s ", $i; print ""}' > "$home/$dir_name/${ip}_nmap.txt" 2>&1
            timeout 30 masscan "$ip" -p U:1-100 > "$home/$dir_name/${ip}_masscan.txt" 2>&1
            timeout 30 nmap "$ip" -sV -sC --script=ftp-brute.nse -oN "$home/$dir_name/${ip}_brute.txt" > /dev/null 2>&1
            echo "Finished..."
        else
            echo "Skipping empty entry in IP list."
        fi
    done
    
    WEAK_PASSWORDS
}

function SCAN() # Allows the user to choose the scan he want to preform 
{	
	
	while true; do
     echo -e "Please choose the level of the scan you want to make: \n{1} Basic - scans the network for TCP and UDP, including the service version and weak password. \n{2} Full - include Nmap Scripting Engine (NSE), weak passwords, and vulnerability analysis. \n{3} Exit"
     read -p "Enter your choice (1, 2, 3): " num

    case $num in
    1)
        BASIC
        ;;
    2)
        FULL 
        ;;
    3)
        echo "Exiting"
        exit 0
        ;;
    *)
        echo "Invalid input - please try again (1, 2, 3)."
        ;;
    esac
   done
}

function START() # The start function
{
    echo "Please enter the IP or IP subnet you want to run the automation on:"
    read ip_range
    echo "Choose the name of the directory for all the results:"
    read dir_name
    mkdir -p "$dir_name"

    # Extract live hosts and clean up the list
    ip_list=$(nmap -n "$ip_range" -sn | grep -i "Nmap scan report" | awk '{print $NF}' | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')

    echo "Detected IPs:"
    echo "$ip_list"

    if [[ -z "$ip_list" ]]; then
        echo "No live hosts detected in the range $ip_range."
        exit 1
    fi

    SCAN
}

figlet "PT_Automation"
START


#!/bin/bash

NC="\033[0m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
DIR="$HOME/.42-hack"

function fatal_error()
{
	printf "${RED}$1${NC}"
	exit 1
}

function user_cookie_exists()
{
	url_effective=$(curl -fLsS --cookie $DIR/cookies.txt -o /dev/null -w "%{url_effective}" 'https://profile.intra.42.fr')
	if [ $url_effective == 'https://profile.intra.42.fr/' ]
	then
		return 0
	else
		return 1
	fi
}

# Asks the user for his username and password
function read_credentials()
{
	printf "User: "
	read username
	stty -echo
	printf "Password: "
	read password
	stty echo
	printf "\n"
}

function get_authenticity_token()
{
	curl_result=$(curl -fLsS -c $DIR/cookies.txt --cookie $DIR/cookies.txt $1)
	if [ $? -ne 0 ]
	then
		fatal_error "A fatal error occured while fetching the authenticity token..."
	fi

	authenticity_token=$(echo $curl_result | sed -En "s/.*name=\"authenticity_token\"[[:blank:]]*value=\"([^\"]*)\".*/\1/p")
	if [ -z $authenticity_token ]
	then
		fatal_error "No authenticity token found..."
	fi
}

function signin_user()
{
	curl -fLsS -c $DIR/cookies.txt --cookie $DIR/cookies.txt "https://signin.intra.42.fr/users/sign_in" \
		--header "User-Agent: vfurmane's ssh_gitlab script" \
		--data-urlencode "authenticity_token=$authenticity_token" \
		--data-urlencode "user[login]=$username" \
		--data-urlencode "user[password]=$password" > /dev/null
}

function setup()
{
	mkdir -p $DIR
}

setup
while ! user_cookie_exists
do
	printf "${RED}Please login${NC}\n"
	read_credentials
	get_authenticity_token https://signin.intra.42.fr/users/sign_in
	signin_user
done
printf "${GREEN}Logged in!${NC}\n"

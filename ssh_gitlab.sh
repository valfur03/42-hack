#!/bin/bash

NC="\033[0m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
DIR="$HOME/.42-hack"
PUBKEY="$HOME/.ssh/id_rsa.pub"

function fatal_error()
{
	printf "${RED}$1${NC}\n"
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
	curl -fLsS -c $DIR/cookies.txt --cookie $DIR/cookies.txt -o /dev/null \
		"https://signin.intra.42.fr/users/sign_in" \
		--header "User-Agent: vfurmane's ssh_gitlab script" \
		--data-urlencode "authenticity_token=$authenticity_token" \
		--data-urlencode "user[login]=$username" \
		--data-urlencode "user[password]=$password"
}

function get_gitlab_user()
{
	gitlab_user=$(echo $curl_result | sed -En "s/.*value=\"([^\"]*)\"[[:blank:]]*type=\"hidden\"[[:blank:]]*name=\"gitlab_user\[user_id\]\".*/\1/p")
	if [ -z $gitlab_user ]
	then
		fatal_error "No gitlab user found..."
	fi
}

function new_ssh_key()
{
	if ! [ -f $PUBKEY ]
	then
		fatal_error "Cannot read file at $PUBKEY."
	fi
	curl -fLsS -c $DIR/cookies.txt --cookie $DIR/cookies.txt -o /dev/null \
		"https://profile.intra.42.fr/gitlab_users" \
		--header "User-Agent: vfurmane's ssh_gitlab script" \
		--data-urlencode "authenticity_token=$authenticity_token" \
		--data-urlencode "gitlab_user[public_key]=$(cat $PUBKEY)" \
		--data-urlencode "gitlab_user[user_id]=$gitlab_user"
}

function setup()
{
	mkdir -p $DIR
	while [ $# -gt 0 ]
	do
		case $1 in
			--public-key)
				if [ $# -gt 1 ]
				then
					shift
					PUBKEY=$1
				else
					fatal_error "Expected file name after --public-key"
				fi
				shift;;
			*)
				fatal_error "Unexpected parameter $1";;
		esac
	done
}

setup $@
while ! user_cookie_exists
do
	printf "${BLUE}Please login${NC}\n"
	read_credentials
	get_authenticity_token https://signin.intra.42.fr/users/sign_in
	signin_user
done
printf "${GREEN}Logged in!${NC}\n"

get_authenticity_token https://profile.intra.42.fr/gitlab_users/new
get_gitlab_user
printf "${GREEN}Got the user id!${NC}\n"

new_ssh_key
printf "${GREEN}Updated the SSH key!${NC}\n"

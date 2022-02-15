#!/bin/bash
#
#
#
#           Created by A.Hodgson                     
#            Date: 2021-11-17                            
#            Purpose: Create a default Prestage
#
#
#
#############################################################
#############################################################
macOS_URL="https://raw.githubusercontent.com/Aaron-ElectricAI/JamfPro-JSON/main/macos-prestage.json"
iOS_URL="https://raw.githubusercontent.com/Aaron-ElectricAI/JamfPro-JSON/main/ios-prestage.json"
#############################################################
# Just for fun
script_title="Electric Default PreStage Generator"
echo ""
echo ""
cat << "EOF"
          _ _,---._
       ,-','       `-.___
      /-;'               `._
     /\/          ._   _,'o \
    ( /\       _,--'\,','"`. )
     |\      ,'o     \'    //\
     |      \        /   ,--'""`-.
     :       \_    _/ ,-'         `-._
      \        `--'  /                )
       `.  \`._    ,'     ________,','
         .--`     ,'  ,--` __\___,;'
          \`.,-- ,' ,`_)--'  /`.,'
           \( ;  | | )      (`-/
             `--'| |)       |-/
               | | |        | |
               | | |,.,-.   | |_
               | `./ /   )---`  )
              _|  /    ,',   ,-'
             ,'|_(    /-<._,' |--,
             |    `--'---.     \/ \
             |          / \    /\  \
           ,-^---._     |  \  /  \  \
        ,-'        \----'   \/    \--`.
       /            \              \   \
EOF
echo "    $script_title!!!"
echo ""
echo ""
#############################################################
# Functions
#############################################################
function generateAuthToken() {
  # created base64-encoded credentials
  encodedCredentials=$( printf "$apiUser:$apiPass" | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i - )
  # generate an auth token
  authToken=$( /usr/bin/curl "$instanceName/api/v1/auth/token" --header 'Accept: application/json' --silent --request POST --header "Authorization: Basic $encodedCredentials" )
  # parse authToken for token, omit expiration
  token=$(echo "$authToken" | python3 -c 'import json,sys;obj=json.load(sys.stdin);print(obj["token"])')
}

function apiResponse() #takes api response code variable
{
    HTTP_Status=$1
    if [ $HTTP_Status -eq 200 ] || [ $HTTP_Status -eq 201 ]; then
        echo "Success."
    elif [ $HTTP_Status -eq 400 ]; then
        echo "Failure - Bad request. Verify the syntax of the request specifically the XML body."
    elif [ $HTTP_Status -eq 401 ]; then
        echo "Failure - Authentication failed. Verify the credentials being used for the request."
    elif [ $HTTP_Status -eq 403 ]; then
        echo "Failure - Invalid permissions. Verify the account being used has the proper permissions for the object/resource you are trying to access."
    elif [ $HTTP_Status -eq 404 ]; then
        echo "Failure - Object/resource not found. Verify the URL path is correct."
    elif [ $HTTP_Status -eq 409 ]; then
        echo "Failure - Conflict, check XML data"
    elif [ $HTTP_Status -eq 500 ]; then
        echo "Failure - Internal server error. Retry the request or contact Jamf support if the error is persistent."
    fi
}

#############################################################
# Main 
#############################################################
read -r -p "Please enter a JAMF instance to take action on: " instanceName
if [[ -z "$apiUser" ]]; then 
  read -r -p "Please enter a JAMF API administrator name: " apiUser
fi
if [[ -z "$apiPass" ]]; then 
  read -r -s -p "Please enter the password for the account: " apiPass
fi
echo ""
generateAuthToken
echo ""

#prompt user and loop until we have a valid option 
while true; do
  echo ""
  echo "What is your target?"
  echo "1 - macOS "
  echo "2 - iOS "
  echo "3 - Both"
  read -p "Please enter an option number: " option

  case $option in 
    1)
      echo "Getting macOS JSON data from Github..."
      macos_json=$(curl -sk -H "Authorization: token $github_token" -H 'Accept: application/vnd.github.v3.raw' $macOS_URL)
      echo "Creating macOS PreStage..."
      response=$(curl --write-out "%{http_code}" -sk -X POST "$instanceName/api/v2/computer-prestages" -H "accept: application/json" -H "Authorization: Bearer $token" -H "Content-Type: application/json" -d  "$macos_json")  
      responseStatus=${response: -3}
      apiResponse "$responseStatus"
      break
      ;;
    2)
      echo "Getting iOS JSON data from Github..."
      ios_json=$(curl -sk -H "Authorization: token $github_token" -H 'Accept: application/vnd.github.v3.raw' $iOS_URL)
      echo "Creating iOS PreStage..."
      response=$(curl --write-out "%{http_code}" -sk -X POST "$instanceName/api/v2/mobile-device-prestages" -H "accept: application/json" -H "Authorization: Bearer $token" -H "Content-Type: application/json" -d "$ios_json")
      responseStatus=${response: -3}
      apiResponse "$responseStatus"
      break
      ;;
    3)
      echo "Getting macOS JSON data from Github..."
      macos_json=$(curl -sk -H "Authorization: token $github_token" -H 'Accept: application/vnd.github.v3.raw' $macOS_URL)
      echo "Creating macOS PreStage..."
      response=$(curl --write-out "%{http_code}" -sk -X POST "$instanceName/api/v2/computer-prestages" -H "accept: application/json" -H "Authorization: Bearer $token" -H "Content-Type: application/json" -d "$macos_json")  
      responseStatus=${response: -3}
      apiResponse "$responseStatus"
      echo "Getting iOS JSON data from Github..."
      ios_json=$(curl -sk -H "Authorization: token $github_token" -H 'Accept: application/vnd.github.v3.raw' $iOS_URL)
      echo "Creating iOS PreStage..."
      response=$(curl --write-out "%{http_code}" -sk -X POST "$instanceName/api/v2/mobile-device-prestages" -H "accept: application/json" -H "Authorization: Bearer $token" -H "Content-Type: application/json" -d "$ios_json")
      responseStatus=${response: -3}
      apiResponse "$responseStatus"
      break
      ;;
    *)
      echo "That is not a valid choice, try a number from the list."
        ;;
    esac
done

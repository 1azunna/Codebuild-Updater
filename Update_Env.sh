#! /bin/bash
## Written and maintained by @1azunna

echo ""
echo -e "\x1B[1;33mA script to update Environment Variables in a codebuild project. \nEnsure your environment variables are saved in JSON format in the file named env_var.json \x1B[0m"
echo -e  '\x1B[0;35m
  _____           _      _           _ _     _        _____ _   _ _   _        _   _           _       _
 /  __ \         | |    | |         (_) |   | |      |  ___| \ | | | | |      | | | |         | |     | |
|  /  \/ ___   __| | ___| |__  _   _ _| | __| |______| |__ |  \| | | | |______| | | |_ __   __| | __ _| |_ ___ _ __
| |    /  _ \ / _  |/ _ \ _ \ | | | | | |/ _  |______|  __|| .   | | | |______| | | |  _ \ / _  |/ _  | __/ _ \ _ _|
|  \__/\ (_) | (_| |  __/ |_) | |_| | | | (_| |      | |___| |\  \ \_/ /      | |_| | |_) | (_| | (_| | ||  __/ |
 \____/ \___/ \__,_|\___|_.__/ \__,_|_|_|\__,_|      \____/\_| \_/\___/        \___/| .__/ \__,_|\__,_|\__\___|_|
                                                                                    | |
                                                                                    |_|


 \x1B[0m'
read -rp $'\x1B[1;34m Enter target region: \x1B[0m' region
read -rp $'\x1B[1;34m Enter aws cli profile: \x1B[0m' profile

envfile1=env_var.json
envfile2=/tmp/var.json

duplicate_check () {
  dup_count=$(cat $envfile1 | jq -r '.name' | sort | uniq -d | wc -l)
  if [ $dup_count -gt 0 ]; then
    echo -e "\x1B[0;47m\x1B[1;31mDuplicate environment variables are not allowed.\x1B[0m Check $envfile1"
    echo "Exiting...."
    exit 1
  fi
}

get_lineNumbers () {
  line_no=$(cat $envfile1 | jq -S '.environmentVariables[]' | sed -n '/'$var'/=')
  line_no2=$(sed -n '/'$var'/=' $envfile2)
  prev_line=$(($line_no - 1))
  next_line=$(($line_no + 1))
  next2_line=$(($line_no + 2))
  next_line2=$(($line_no2 + 1))
  next2_line2=$(($line_no2 + 2))
  next3_line=$(($line_no + 3))
}

find_andReplace () {
  TYPE1=$(cat $envfile1 | jq -S '.environmentVariables[]' | sed -n "$next_line"p)
  TYPE2=$(sed -n "$next_line2"p $envfile2)
  VALUE1=$(cat $envfile1 | jq -S '.environmentVariables[]' | sed -n "$next2_line"p)
  VALUE2=$(sed -n "$next2_line2"p $envfile2)
  if [ $? == 0 ] ; then
    if [ "$TYPE1" != "$TYPE2" ]; then
      sed -i -e "${next_line2}s|.*|${TYPE1}|" $envfile2
      echo -e "\x1B[1;34m Type\x1B[0m of \x1B[0;32m$var\x1B[0m has been updated"
    fi
    if [ "$VALUE1" != "$VALUE2" ]; then
      sed -i -e ''$next2_line2's|'.*'|'"$VALUE1"'|' $envfile2
      echo -e "\x1B[1;34m Value\x1B[0m of \x1B[0;32m$var\x1B[0m has been updated"
    fi
  else
    echo -e "\x1B[0;47m\x1B[1;31mError handling JSON input\x1B[0m Check $envfile1 and ensure proper quotes and comma-separators"
  fi
}


update_env () {
  jq -s . $envfile2
  variables=$(jq -s . $envfile2 )
  #set environment variable
  aws codebuild update-project --name $project --environment "{\"type\": \"$envType\",\"image\": \"$imageType\",\"computeType\": \"$computeType\",\"privilegedMode\": $privilegeMode,\"environmentVariables\": $variables}" --profile $profile --region $region >/dev/null
  if [ $? == 0 ] ; then
    echo -e "\x1B[0;36m$project environment variables update was \x1B[0;42m\x1B[1;37mSUCCESSFUL\x1B[0m"
  else
    echo -e "\x1B[0;36m$project environment variables update \x1B[0;47m\x1B[1;31mFAILED\x1B[0m"
  fi
}

while [[ $REPLY != 5 ]]; do

read -rp $'
\x1B[1;34m MENU \x1B[0m
\x1B[1;33mSelect an option:\x1B[0m
\x1B[1;32m1).\x1B[0m View all projects in the target region.
\x1B[1;35m2).\x1B[0m Update all projects in the target region.
\x1B[1;34m3).\x1B[0m Specify projects to update in the target region.
\x1B[1;36m4).\x1B[0m Re-enter target region and/or profile.
\x1B[1;31m5).\x1B[0m Exit.

\x1B[1;34mEnter yor selection and hit ENTER: \x1B[0m' REPLY

			if [[ $REPLY =~ ^[1-5]$ ]]; then
					if [[ $REPLY == 1 ]]; then
						echo -e "\x1B[1;33mProjects in $region : \x1B[0m"
						echo ""
						projects=$(aws codebuild list-projects --profile  $profile --region $region | jq -r '.projects[]' | sed $'s/^/\t/')
						echo -e "\x1B[1;31m$projects\x1B[0m"
						continue
					fi

					if [[ $REPLY == 2 ]]; then
						echo -e "\x1B[1;33m Updating Environment Variables for Projects in $region \x1B[0m "
						projects=($(aws codebuild list-projects --profile  $profile --region $region | jq -r '.projects[]'))
						declare -a projects
						for project in "${projects[@]}"
							do
								#get current project settings
								echo -e "\x1B[1;31m$project\x1B[0m"
								computeType=$(aws codebuild batch-get-projects --names $project --profile $profile --region $region | jq -r '.projects[] | .environment.computeType')
								imageType=$(aws codebuild batch-get-projects --names $project --profile $profile --region $region | jq -r '.projects[] | .environment.image')
								envType=$(aws codebuild batch-get-projects --names $project --profile $profile --region $region | jq -r '.projects[] | .environment.type')
                privilegeMode=$(aws codebuild batch-get-projects --names $project --profile $profile --region $region | jq -r '.projects[] | .environment.privilegedMode')
								aws codebuild batch-get-projects --names $project --profile $profile --region $region | jq -S '.projects[] | .environment.environmentVariables | .[]' > $envfile2
                # aws codebuild batch-get-projects --names $project --profile $profile --region $region | jq -S '.projects[] | .environment | {environmentVariables}' > $envfile2
                # Check if the environment variables already exist.
                duplicate_check
                envVars=($(cat $envfile1 | jq -r '.environmentVariables[] | .name' | sort -u))
                declare -a envVars
                for var in "${envVars[@]}"
                  do
                    if grep -q $var "$envfile2"; then
                      #Get the line numbers
                      get_lineNumbers
                      # Find and Replace with new updates
                      if [[ $line_no != 0 && $line_no2 != 0 ]]; then
                        find_andReplace
                      else
                        echo -e "\x1B[0;47m\x1B[1;31mError encountered while setting Environment Varibles. Check your Environment variable file\x1B[0m"
                      fi
                    else
                      get_lineNumbers
                      newVar=$(cat $envfile1 | jq -S '.environmentVariables[]' | sed -n ''$prev_line,$next3_line' p' )
                      echo $newVar >> $envfile2
                      echo -e "\x1B[0;33m New Environment Variable \x1B[0;32m$var\x1B[0m \x1B[0;33m Added \x1B[0m"
                    fi
                  done
                 update_env
					  done
						rm /tmp/var.json
						continue
					fi

				 if [[ $REPLY == 3 ]]; then
						echo ""
						read -rp "Enter the projects space-delimited: " -a arr
						echo -e "\x1B[1;33m Updating Environment Variables for $arr in $region \x1B[0m "
						for project  in "${arr[@]}"
							do
								#get current project settings
								echo -e "\x1B[1;31m$project\x1B[0m"
								computeType=$(aws codebuild batch-get-projects --names $project --profile $profile --region $region | jq -r '.projects[] | .environment.computeType')
								imageType=$(aws codebuild batch-get-projects --names $project --profile $profile --region $region | jq -r '.projects[] | .environment.image')
								envType=$(aws codebuild batch-get-projects --names $project --profile $profile --region $region | jq -r '.projects[] | .environment.type')
                privilegeMode=$(aws codebuild batch-get-projects --names $project --profile $profile --region $region | jq -r '.projects[] | .environment.privilegedMode')
                aws codebuild batch-get-projects --names $project --profile $profile --region $region | jq -S '.projects[] | .environment.environmentVariables | .[]' > $envfile2
                # Check if the environment variables already exist.
                duplicate_check
                envVars=($(cat $envfile1 | jq -r '.environmentVariables[] | .name' | sort -u))
                declare -a envVars
                for var in "${envVars[@]}"
                  do
                    if grep -q $var "$envfile2"; then
                      #Get the line numbers
                      get_lineNumbers
                      # Find and Replace with new updates
                      if [[ $line_no != 0 && $line_no2 != 0 ]]; then
                        find_andReplace
                      else
                        echo -e "\x1B[0;47m\x1B[1;31mError encountered while setting Environment Varibles. Check your Environment variable file\x1B[0m"
                      fi
                    else
                      get_lineNumbers
                      newVar=$(cat $envfile1 | jq -S '.environmentVariables[]' | sed -n ''$prev_line,$next3_line' p' )
                      echo $newVar >> $envfile2
                      echo -e "\x1B[0;33m New Environment Variable \x1B[0;32m$var\x1B[0m \x1B[0;33m Added \x1B[0m"
                    fi
                  done
                update_env
							done
							rm /tmp/var.json
						continue
					fi

					if [[ $REPLY == 4 ]]; then
						./$(basename $0) && exit
					fi
					continue
			else
				echo -e "\x1B[0;31mInvalid Option! \x1B[0;33mPlease select a valid option\x1B[0m"
			fi
done

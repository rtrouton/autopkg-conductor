#!/bin/bash

# AutoPkg automation script

# Adjust the following variables for your particular configuration.
#
# autopkg_user_account - This should be the user account you're running AutoPkg in.
# autopkg_user_account_home - This should be the home folder location of the AutoPkg user account
#
# Note: The home folder location is currently set to be automatically discovered 
# using the autopkg_user_account variable.
#
# recipe_list - This is the location of the plain text file being used to store
# your list of AutoPkg recipes. For more information about this list, please see
# the link below:
#
# https://github.com/autopkg/autopkg/wiki/Running-Multiple-Recipes
#
# log_location - This should be the location and name of the AutoPkg run logs.
#
# Note: The location is currently set to be automatically discovered 
# using the autopkg_user_account_home variable.

autopkg_user_account="username_goes_here"
autopkg_user_account_home=$(/usr/bin/dscl . -read /Users/"$autopkg_user_account" NFSHomeDirectory | awk '{print $2}')
recipe_list="/path/to/recipe_list.txt"
log_location="$autopkg_user_account_home/Library/Logs/autopkg-run-for-$(date +%Y-%m-%d-%H%M%S).log"

# If you're using JSSImporter or Jamf Upload, the URL of your Jamf Pro server should be populated
# into the jamfpro_server variable automatically.
#
# If you're not using JSSImporter or Jamf Upload, this variable will return nothing and that's OK.

jamfpro_server=$(/usr/bin/defaults read "$autopkg_user_account_home"/Library/Preferences/com.github.autopkg JSS_URL)

# Optional variables

# This script supports using either Jamf Upload's JamfUploaderSlacker or JSSImporter's Slacker processors

# JamfUploaderSlacker - used with Jamf Upload
# 
# To use the JamfUploaderSlacker post-processor, you'll need to use add Graham Pugh's
# Autopkg repo by running the command below:
#
# autopkg repo-add grahampugh-recipes
#
# The slack_post_processor variable should look like this:
# slack_post_processor="com.github.grahampugh.jamf-upload.processors/JamfUploaderSlacker"
#
# Slacker - used with JSSImporter
# 
# To use the Slacker post-processor, you'll need to use either Graham Pugh's or my
# fork of Graham's. For information on Graham's, please see the following post:
#
# http://grahampugh.github.io/2017/12/22/slack-for-autopkg-jssimporter.html
#
# To use mine, please add my AutoPkg repo by running the following command:
#
# autopkg repo-add rtrouton-recipes
#
# If using Graham's, the slack_post_processor variable should look like this:
# slack_post_processor="com.github.grahampugh.recipes.postprocessors/Slacker"
#
# If using mine, the slack_post_processor variable should look like this:
# slack_post_processor="com.github.rtrouton.recipes.postprocessors/Slacker"

slack_post_processor=""

# The key used by the JamfUploaderSlacker and Slacker AutoPkg processors is slightly different
# so the right one needs to be used when running AutoPkg. 
#
# JamfUploaderSlacker: slack_webhook_url
#
# Slacker: webhook_url
#
# Setting the slack_autopkg_processor variable will enable the script to use the correct key for the processor.
#
# If using JamfUploaderSlacker, the slack_autopkg_processor processor should be set as shown below:
#
# slack_autopkg_processor="JamfUploaderSlacker"
#
# If using Slacker, the slack_autopkg_processor processor should be set as shown below:
#
# slack_autopkg_processor="Slacker"

slack_autopkg_processor=""

# If you're sending the results of your AutoPkg run to Slack, you'll need to set up
# a Slack webhook to receive the information being sent by the script. 
# If you need help with configuring a Slack webhook, please see the links below:
#
# https://api.slack.com/incoming-webhooks
# https://get.slack.help/hc/en-us/articles/115005265063-Incoming-WebHooks-for-Slack
#
# Once a Slack webhook is available, the slack_webhook variable should look similar
# to this:
# slack_webhook="https://hooks.slack.com/services/XXXXXXXXX/YYYYYYYYY/ZZZZZZZZZZ" 

slack_webhook=""


# don't change anything below this line

# Set script exit status

exit_error=0

# Define logger behavior

ScriptLogging(){

    DATE=$(date +%Y-%m-%d\ %H:%M:%S)
    LOG="$log_location"
    
    echo "$DATE" " $1" >> $LOG
}

# Function for sending multi-line output to a Slack webhook. Original script from here:
# 
# http://blog.getpostman.com/2015/12/23/stream-any-log-file-to-slack-using-curl/

SendToSlack(){

cat "$1" | while read LINE; do
  (echo "$LINE" | grep -e "$3") && curl -X POST --silent --data-urlencode "payload={\"text\": \"$(echo $LINE | sed "s/\"/'/g")\"}" "$2";
done

}

# If the AutoPkg run's log file is not available, create it

if [[ ! -r "$log_location" ]]; then
    touch "$log_location"
fi

# If the AutoPkg recipe list is missing or unreadable, stop the script with an error.

if [[ ! -r "$recipe_list" ]]; then
    ScriptLogging "Error Detected. Unable to start AutoPkg run."
    echo "" > /tmp/autopkg_error.out
    
    if [[ "$jamfpro_server" = "" ]]; then    
        echo "AutoPkg run failed" >> /tmp/autopkg_error.out
    else
        echo "AutoPkg run for $jamfpro_server failed" >> /tmp/autopkg_error.out
    fi
    
    echo "$recipe_list is missing or unreadable. Fix immediately." >> /tmp/autopkg_error.out
    echo "" > /tmp/autopkg.out
    
    # If a Slack webhook is configured, send the error log to Slack.
    
    if [[ ! -z "$slack_webhook" ]]; then
        SendToSlack /tmp/autopkg_error.out ${slack_webhook}
    fi
    
    cat /tmp/autopkg_error.out >> "$log_location"
    ScriptLogging "Finished AutoPkg run"
    exit_error=1
fi

# If the the AutoPkg recipe list is readable and AutoPkg is installed,
# run the recipes stored in the recipe list. 

if [[ -x /usr/local/bin/autopkg ]] && [[ -r "$recipe_list" ]]; then

    ScriptLogging "AutoPkg installed at $(which autopkg)"
    ScriptLogging "Recipe list located at $recipe_list and is readable."
    echo "" > /tmp/autopkg.out    
    
    if [[ "$jamfpro_server" = "" ]]; then    
        echo "Starting AutoPkg run" >> /tmp/autopkg_error.out
    else
        echo "Starting AutoPkg run for $jamfpro_server" >> /tmp/autopkg.out
    fi
        
    echo "" >> /tmp/autopkg.out
    echo "" > /tmp/autopkg_error.out
    echo "Error log for AutoPkg run" >> /tmp/autopkg_error.out
    echo "" >> /tmp/autopkg_error.out 
    /usr/local/bin/autopkg repo-update all 2>&1 >> /tmp/autopkg.out 2>>/tmp/autopkg_error.out
    cat /tmp/autopkg.out >> "$log_location" && cat /tmp/autopkg_error.out >> "$log_location"

    if [[ ! -z "$slack_webhook" ]]; then
    
       if [[ ! -z "$slack_post_processor" ]] && [[ ! -z "$slack_autopkg_processor" ]]; then
       
         if [[ ${slack_autopkg_processor} = "Slacker" ]] || [[ ${slack_autopkg_processor} = "JamfUploaderSlacker" ]]; then

          # If both a post-processor to post to Slack and a Slack webhook are configured, the JSSImporter
          # and Jamf Upload recipes should have their outputs posted to Slack using the post-processor, while
          # all other standard output should go to /tmp/autopkg.out. All standard error output 
          # should go to /tmp/autopkg_error.out
          
            if [[ ${slack_autopkg_processor} = "Slacker" ]]; then
                slack_autopkg_processor_key="webhook_url"
            elif [[ ${slack_autopkg_processor} = "JamfUploaderSlacker" ]]; then
                slack_autopkg_processor_key="slack_webhook_url"
            fi
             
             /usr/local/bin/autopkg run --recipe-list=${recipe_list} --post=${slack_post_processor} --key ${slack_autopkg_processor_key}=${slack_webhook} >> /tmp/autopkg.out 2>>/tmp/autopkg_error.out
 
          else

            # If for some reason the slack_autopkg_processor variable is configured with an unknown value,
            # neither processor is called and all standard output should go to /tmp/autopkg.out.
            # All standard error output should go to /tmp/autopkg_error.out.
            
            /usr/local/bin/autopkg run --recipe-list=${recipe_list} >> /tmp/autopkg.out 2>>/tmp/autopkg_error.out
            
          fi

        else

          # If only using a Slack webhook, all standard output should go to /tmp/autopkg.out.
          # All standard error output should go to /tmp/autopkg_error.out.
          
          /usr/local/bin/autopkg run --recipe-list=${recipe_list} >> /tmp/autopkg.out 2>>/tmp/autopkg_error.out
          
        fi
         
      
      else

          # If a Slack webhook is not configured, all standard output should go to /tmp/autopkg.out.
          # All standard error output should go to /tmp/autopkg_error.out.
    
       /usr/local/bin/autopkg run --recipe-list="$recipe_list" >> /tmp/autopkg.out 2>>/tmp/autopkg_error.out
    fi    
        
    if [[ "$jamfpro_server" = "" ]]; then    
        echo "Finished with AutoPkg run" >> /tmp/autopkg.out
    else
        echo "Finished with AutoPkg run for $jamfpro_server" >> /tmp/autopkg.out
    fi
    
    echo "" >> /tmp/autopkg.out && echo "" >> /tmp/autopkg_error.out 
    cat /tmp/autopkg.out >> "$log_location"
    cat /tmp/autopkg_error.out >> "$log_location"    
    ScriptLogging "Finished AutoPkg run"
    echo "" >> /tmp/autopkg_error.out
    echo "End of error log for AutoPkg run" >> /tmp/autopkg_error.out
    echo "" >> /tmp/autopkg_error.out
    
    if [[ -z "$slack_post_processor" ]] && [[ ! -z "$slack_webhook" ]]; then
    
       # If the AutoPkg post-processor for posting to Slack is not
       # configured but we do have a Slack webhook set up, all 
       # standard output should be sent to Slack.
       
       ScriptLogging "Sending AutoPkg output log to Slack"
       SendToSlack /tmp/autopkg.out ${slack_webhook}
       ScriptLogging "Sent AutoPkg output log to $slack_webhook."
    
    fi
    
    if [[ ! -z "$slack_post_processor" ]] && [[ ! -z "$slack_webhook" ]] && [[ ${slack_autopkg_processor} != "Slacker" ]] && [[ ${slack_autopkg_processor} != "JamfUploaderSlacker" ]]; then
    
       # If the AutoPkg post-processor for posting to Slack is 
       # misconfigured but we do have a Slack webhook set up, 
       # all standard output should be sent to Slack.
       
       ScriptLogging "Sending AutoPkg output log to Slack"
       SendToSlack /tmp/autopkg.out ${slack_webhook}
       ScriptLogging "Sent AutoPkg output log to $slack_webhook."
    
    fi
       
    if [[ ! -z "$slack_webhook" ]]; then
    
       # If using a Slack webhook, at the end of the AutoPkg run all standard
       # error output logged to /tmp/autopkg_error.out should be output to Slack,
       # using the SendToSlack function.
    
       if [[ $(wc -l </tmp/autopkg_error.out) -gt 7 ]]; then
           ScriptLogging "Sending AutoPkg error log to Slack"
           SendToSlack /tmp/autopkg_error.out ${slack_webhook}
           ScriptLogging "Sent autopkg log to $slack_webhook. Ending run."
       else
           ScriptLogging "Error log was empty. Nothing to send to Slack."
       fi
    
    fi
fi

exit "$exit_error"
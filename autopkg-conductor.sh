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

# Choose whether or not you want to update your AutoPkg repos as part of the script run.
#
# If you want to have AutoPkg update your repos as part of the script run, the update_repos 
# variable should look like this:
#
# update_repos="yes"
#
# By default, this is how the variable is configured.
#
# If you don't want to have AutoPkg update your repos as part of the script run, the update_repos 
# variable should look like this:
#
# update_repos=""

update_repos="yes"

# If you're using Jamf Upload, the URL of your Jamf Pro server should be populated into the jamfpro_server variable automatically.
#
# If you're not using Jamf Upload, this variable will return nothing and that's OK.

jamfpro_server=$(/usr/bin/defaults read "$autopkg_user_account_home"/Library/Preferences/com.github.autopkg JSS_URL)

# Optional variables

# This script supports using either Jamf Upload's JamfUploaderSlacker or Jamf Upload's JamfUploaderTeamsNotifier processors

# JamfUploaderSlacker - used with Jamf Upload
# 
# To use the JamfUploaderSlacker post-processor, you'll need to use add Graham Pugh's
# Autopkg repo by running the command below:
#
# autopkg repo-add grahampugh-recipes
#
# The slack_post_processor variable should look like this:
# slack_post_processor="com.github.grahampugh.jamf-upload.processors/JamfUploaderSlacker"

slack_post_processor=""

# JamfUploaderTeamsNotifier - used with Jamf Upload
# 
# To use the JamfUploaderTeamsNotifier post-processor, you'll need to use add Graham Pugh's
# Autopkg repo by running the command below:
#
# autopkg repo-add grahampugh-recipes
#
# The teams_post_processor variable should look like this:
# teams_post_processor="com.github.grahampugh.jamf-upload.processors/JamfUploaderTeamsNotifier"

teams_post_processor=""

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

# If you're sending the results of your AutoPkg run to Teams, you'll need to set up
# a Teams webhook to receive the information being sent by the script. 
# If you need help with configuring a Teams webhook, please see the links below:
#
# https://learn.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/how-to/add-incoming-webhook
#
# Once a Teams webhook is available, the teams_webhook variable should look similar
# to this:
# teams_webhook="https://companyname.webhook.office.com/webhookb2/7ce853bd-a9e1-462f-ae32-d3d35ed5295d@7c155bae-5207-4bb5-8b58-c43228bc1bb7/IncomingWebhook/8155d8581864479287b68b93f89556ae/651e63f8-2d96-42ab-bb51-65cb05fc62aa"

teams_webhook=""

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

# Function for sending multi-line output to a Teams webhook. We add an extra Return to
# each line of the log file ($1) to prevent Teams from showing the log on a single line.
# The Teams Card format requires JSON to be sent to the Teams webhook ($2).
# You can add a title to the Card by specifying it as a third argument.


SendToTeams(){

LOG_TEXT=$( cat "$1" | sed "s/\"/'/g" | sed "s/$/\r\r/g" )
TEAMS_JSON="{\"title\": \"$3\", \"text\": \"${LOG_TEXT}\" }"
curl -H "Content-Type: application/json" -d "${TEAMS_JSON}" "$2"

}

# Function for AutoPkg runs

RunAutoPkg(){

if [[ ! -z "$slack_autopkg_report" ]] && [[ -z "$teams_autopkg_report" ]]; then
    /usr/local/bin/autopkg run --recipe-list="${recipe_list}" --post=${slack_post_processor} --key ${slack_autopkg_postprocessor_key}=${slack_webhook} >> /tmp/autopkg.out 2>>/tmp/autopkg_error.out
elif [[ -z "$slack_autopkg_report" ]] && [[ ! -z "$teams_autopkg_report" ]]; then
   /usr/local/bin/autopkg run --recipe-list="${recipe_list}" --post=${teams_post_processor} --key ${teams_autopkg_postprocessor_key}=${teams_webhook} >> /tmp/autopkg.out 2>>/tmp/autopkg_error.out
elif [[ ! -z "$slack_autopkg_report" ]] && [[ ! -z "$teams_autopkg_report" ]]; then
   /usr/local/bin/autopkg run --recipe-list="${recipe_list}" --post=${slack_post_processor} --key ${slack_autopkg_postprocessor_key}=${slack_webhook} --post=${teams_post_processor} --key ${teams_autopkg_postprocessor_key}=${teams_webhook} >> /tmp/autopkg.out 2>>/tmp/autopkg_error.out
else
   /usr/local/bin/autopkg run --recipe-list="${recipe_list}" >> /tmp/autopkg.out 2>>/tmp/autopkg_error.out
fi

}

# The key used by the JamfUploaderSlacker and JamfUploaderTeamsNotifier AutoPkg processors is slightly different
# so the right one needs to be used when running AutoPkg. 
#
# JamfUploaderSlacker: slack_webhook_url
#
# JamfUploaderTeamsNotifier: teams_webhook_url
#
# The slack_autopkg_postprocessor and teams_autopkg_postprocessor variables will enable
# the script to identify the correct key for the processor.

slack_autopkg_postprocessor=${slack_post_processor#*/}

teams_autopkg_postprocessor=${teams_post_processor#*/}

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
    
    # If a Teams webhook is configured, send the error log to Teams.
    
    if [[ ! -z "$teams_webhook" ]]; then
        SendToTeams /tmp/autopkg_error.out ${teams_webhook} "AutoPkg-Conductor Configuration Error"
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
    
    if [[ "$jamfpro_server" = "" ]]; then    
         echo "Error log for AutoPkg run" >> /tmp/autopkg_error.out
    else
         echo "Error log for AutoPkg run to $jamfpro_server" >> /tmp/autopkg_error.out
    fi

    echo "" >> /tmp/autopkg_error.out

    if [[ "$update_repos" = "yes" ]]; then
        /usr/local/bin/autopkg repo-update all 2>&1 >> /tmp/autopkg.out 2>>/tmp/autopkg_error.out
    fi

    cat /tmp/autopkg.out >> "$log_location" && cat /tmp/autopkg_error.out >> "$log_location"

    # If a webhook for Slack is configured, send output to Slack

    if [[ ! -z "$slack_webhook" ]]; then
    
       if [[ ! -z "$slack_post_processor" ]] && [[ ! -z "$slack_autopkg_postprocessor" ]]; then

          # If both a post-processor to post to Slack and a Slack webhook are configured and nothing is configured for Teams,
          # the Jamf Upload recipes should have their outputs posted to Slack using the post-processor, while all other
          # output should go to /tmp/autopkg.out. All standard error output should go to /tmp/autopkg_error.out.
          
          if [[ ${slack_autopkg_postprocessor} = "JamfUploaderSlacker" ]]; then
             slack_autopkg_postprocessor_key="slack_webhook_url"
             slack_autopkg_report=1
          fi
       fi
    fi

    # If a webhook for Teams is configured, send output to Teams

    if [[ ! -z "$teams_webhook" ]]; then
    
       if [[ ! -z "$teams_post_processor" ]] && [[ ! -z "$teams_autopkg_postprocessor" ]]; then

          # If both a post-processor to post to Teams and a Teams webhook are configured and nothing is configured for Slack,
          # the Jamf Upload recipes should have their outputs posted to Teams using the post-processor, while all other
          # output should go to /tmp/autopkg.out. All standard error output should go to /tmp/autopkg_error.out.
          
          if [[ ${teams_autopkg_postprocessor} = "JamfUploaderTeamsNotifier" ]]; then
             teams_autopkg_postprocessor_key="teams_webhook_url"
             teams_autopkg_report=1
          fi
       fi
    fi   
    
    # Run AutoPkg with the configured reporting options for Slack and/or Teams         

    RunAutoPkg 
        
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
    
       # If the AutoPkg post-processor for posting to Slack is 
       # not configured but we do have a Slack webhook set up, 
       # all standard output should be sent to Slack.
       
       ScriptLogging "Sending AutoPkg output log to Slack"
       SendToSlack /tmp/autopkg.out ${slack_webhook}
       ScriptLogging "Sent AutoPkg output log to $slack_webhook."
    
    fi

    if [[ -z "$teams_post_processor" ]] && [[ ! -z "$teams_webhook" ]]; then
    
       # If the AutoPkg post-processor for posting to Teams is 
       # not configured but we do have a Teams webhook set up, 
       # all standard output should be sent to Teams.
       
       ScriptLogging "Sending AutoPkg output log to Teams"
       SendToTeams /tmp/autopkg.out ${teams_webhook} "AutoPkg-Conductor Run $(date +%Y-%m-%d\ %H:%M:%S)"
       ScriptLogging "Sent AutoPkg output log to $teams_webhook."
    
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

    if [[ ! -z "$teams_webhook" ]]; then
    
       # If using a Teams webhook, at the end of the AutoPkg run all standard
       # error output logged to /tmp/autopkg_error.out should be output to Teams,
       # using the SendToTeams function.
    
       if [[ $(wc -l </tmp/autopkg_error.out) -gt 7 ]]; then
           ScriptLogging "Sending AutoPkg error log to Teams"
           SendToTeams /tmp/autopkg_error.out ${teams_webhook} "AutoPkg-Conductor Error Log"
           ScriptLogging "Sent autopkg log to $teams_webhook. Ending run."
       else
           ScriptLogging "Error log was empty. Nothing to send to Teams."
       fi
    
    fi
fi

exit "$exit_error"

LANGUAGES="shell go python"
ORGS="github grafana awslabs"

# Actions metadata
#

REPO_OWNER=$GITHUB_ACTOR
REPO_NAME=$(basename $(pwd))
RSS_FEED_URL="https://$GITHUB_ACTOR.github.io/$REPO_NAME/feed.xml"


LANGUAGES=$(echo "$LANGUAGES" | tr -s ' ' | tr ' ' '|')

(
        # Boilerplate
        #

        echo '<?xml version="1.0" encoding="UTF-8" ?>'
        echo '<rss version="2.0">'
        printf "<channel>\n<title>Help Wanted</title>\n<description>Help Wanted Issues</description>\n<link>https://lbonanomi.github.io/rss/feed.xml</link>\n"


        for ORG in $ORGS
        do
                #Plumb
                STOP=$(curl -v -u :$TOKEN "https://api.github.com/users/$ORG/repos" -o /dev/null 2>&1 | tr [:punct:] ' ' | awk '/next/ { print $21 }')

                for PAGE in $(seq 1 $STOP)
                do
                        # Reduce to repositories with issues
                        curl -s -u :$TOKEN "https://api.github.com/users/$ORG/repos?page=$PAGE" | jq '.[] | "\(.open_issues) \(.full_name)"' | tr -d '"' | awk '$1 > 0 { print $2}' | while read ISSUED
                        do
                                # Only tell me about repos that contain languages I use
                                curl -s -u :$TOKEN "https://api.github.com/repos/$ISSUED/languages" | jq . | egrep -qi "$LANGUAGES" && (
                                        curl -s -u :$TOKEN "https://api.github.com/repos/$ISSUED/issues" |\
                                         jq '.[] | "\(.labels[].name)_\(.title)_\(.html_url)"' |\
                                         awk -F"_" '/help wanted/ { printf "<item>\n\t<title>"$2"</title>\n\t<link>"$3"</link>\n</item>\n" }'
                                )
                        done
                done

                #curl -s -u :$TOKEN "https://api.github.com/users/$ORG/repos" | jq '.[] | "\(.open_issues) \(.issues_url)"' | tr -d '"' | awk '$1 > 0 { print $0}'
        done

        printf "\n</channel>\n</rss>\n"
) | base64 | tr -d "\n" > feed.xml

# Harvest current SHAof feed.xml
CURRENT_SHA=$(curl -s -u :$TOKEN https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents/feed.xml | jq .sha | tr -d '"')

# Push feed.xml to Github
curl -s -u :$TOKEN -X PUT -d '{ "message":"RSS Refresh Activity", "sha":"'$CURRENT_SHA'", "content":"'$(cat feed.xml)'" }' https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents/feed.xml

echo -X PUT -d '{ "message":"RSS Refresh Activity", "sha":"'$CURRENT_SHA'", "content":"'$(cat feed.xml)'" }' https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents/feed.xml

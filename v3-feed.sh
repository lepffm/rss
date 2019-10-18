LANGUAGES="shell go python"
ORGS="github grafana awslabs"

# Actions metadata
#

REPO_OWNER=$GITHUB_ACTOR
REPO_NAME=$(basename $(pwd))
RSS_FEED_URL="https://$GITHUB_ACTOR.github.io/$REPO_NAME/feed.xml"

if [[ -z "$TOKEN" ]]
then
    echo "Please create a secret called \"TOKEN\" at https://github.com/$REPO_OWNER/$REPO_NAME/settings/secrets with a valid access token"
    exit 2
fi

LANGUAGES=$(echo "$LANGUAGES" | tr -s ' ' | tr ' ' '|')

(
    # RSS Boilerplate
    #

    echo '<?xml version="1.0" encoding="UTF-8" ?>'
    echo '<rss version="2.0">'
    printf "<channel>\n<title>Help Wanted</title>\n<description>Help Wanted Issues</description>\n<link>$RSS_FEED_URL</link>\n"

    for ORG in $ORGS
    do
        #Plumb
        STOP=$(curl -k -v -u :$TOKEN "https://api.github.com/users/$ORG/repos" -o /dev/null 2>&1 | tr [:punct:] ' ' | awk '/next/ { print $21 }')

        for PAGE in $(seq 1 $STOP)
        do
            # Reduce to repositories with issues
            curl -k -s -u :$TOKEN "https://api.github.com/users/$ORG/repos?page=$PAGE" | jq '.[] | "\(.open_issues) \(.full_name)"' | tr -d '"' | awk '$1 > 0 { print $2}' | while read ISSUED
            do
                # Only tell me about repos that contain languages I use
                curl -k -s -u :$TOKEN "https://api.github.com/repos/$ISSUED/languages" | jq . | egrep -qi "$LANGUAGES" && (
                    curl -k -s -u :$TOKEN "https://api.github.com/repos/$ISSUED/issues" |\
                     jq '.[] | "\(.labels[].name)_\(.title)_\(.html_url)_\(.body)"' |\
                     awk -F"_" '/help wanted/ && $3 ~ /http/ { gsub(/\\n/, "<br\/>", $4); print "<item>\n\t<title>"$2"</title>\n\t<link>"$3"</link>\n\t<description><![CDATA["$4" ]]></description>\n</item>\n" }' 2>/dev/null | perl -e 'while(<>){$_=~s/\\r//g;print}'
                )
            done
        done
    done

    printf "\n</channel>\n</rss>\n"
) | sed -e 's/&/&amp;/g' | perl -le 'while (<>) {chomp; $bfr.=$_;} $bfr =~ s/\)/\)\n/g; foreach $f (split(/\n/, $bfr)){ if ($f =~ /(.*)\[(.*?)\]\((.*?\))(.*?)/) { print "$1 <a href=\"$3\">$2</a> $4\n"; } else { print $f; }}' | base64 | tr -d "\n" > feed.xml

# Harvest current SHA of feed.xml
CURRENT_SHA=$(curl -s -u :$TOKEN https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents/feed.xml | jq .sha | tr -d '"')

# Push feed.xml to Github
curl -s -u :$TOKEN -X PUT -d '{ "message":"RSS Refresh Activity", "sha":"'$CURRENT_SHA'", "content":"'$(cat feed.xml)'" }' https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents/feed.xml

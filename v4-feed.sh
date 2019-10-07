# SAID PLAINLY THIS CODE DOESN'T WORK PROPERLY AT THIS TIME. THE V3-FEED IS SCHEDULED AS AN ACTION.

# Get the last 100 updated repos under the defined organizations,
# Get the last 100 issues labelled "Help Wanted" and format as
# RSS articles

REPO_OWNER=$GITHUB_ACTOR
REPO_NAME=$(basename $(pwd))
RSS_FEED_URL="https://$GITHUB_ACTOR.github.io/$REPO_NAME/feed.xml"
echo "FEED URL: $RSS_FEED_URL"

ORGS="github grafana awslabs"

get_issues() {
    # Isn't this hideous?
    curl -s  -H "Authorization: bearer $TOKEN" -X POST -d '{ "query": "query { organization(login: \"'$ORG'\") { repositories(last: 100, orderBy: {field: UPDATED_AT, direction: ASC}) { edges { node { issues(labels: \"Help Wanted\", last: 100) { nodes { url } } } } } } }" }'  https://api.github.com/graphql | jq . | awk -F'"' '/url/ { print $4 }'  | while read ISSUE
    do
        printf "<item>\n<title>\n"
        curl -s -u :$TOKEN $(echo $ISSUE | awk -F"/" '{ print "https://api.github.com/repos/"$4"/"$5"/"$6"/"$7 }') | jq .title
        printf "</title>\n<link>"
        echo $ISSUE
        printf "</link>\n</item>\n"
    done
}

# Add some boilerplate to arranged "articles" into a coherent feed,
# base64-encode it and smash it into a single line

(
    echo '<?xml version="1.0" encoding="UTF-8" ?>'
    echo '<rss version="2.0">'
    printf "<channel>\n<title>Help Wanted</title>\n<description>Help Wanted Issues</description>\n<link>$RSS_FEED_URL</link>\n"

    for ORG in $ORGS
    do
        get_issues "github"
    done
    printf "\n</channel>\n</rss>\n"
) | base64 | tr -d "\n" > feed.xml

# Harvest current SHAof feed.xml
CURRENT_SHA=$(curl -s -u :$TOKEN https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents/feed.xml | jq .sha | tr -d '"')

# Push feed.xml to Github
curl -s -u :$TOKEN -X PUT -d '{ "message":"RSS Refresh Activity", "sha":"'$CURRENT_SHA'", "content":"'$(cat feed.xml)'" }' https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents/feed.xml

echo -X PUT -d '{ "message":"RSS Refresh Activity", "sha":"'$CURRENT_SHA'", "content":"'$(cat feed.xml)'" }' https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents/feed.xml

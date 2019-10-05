ORGS="github grafana awslabs"

get_issues() {
    curl -s  -H "Authorization: bearer $TOKEN" -X POST -d '{ "query": "query { organization(login: \"'$ORG'\") { repositories(last: 100, orderBy: {field: UPDATED_AT, direction: ASC}) { edges { node { issues(labels: \"Help Wanted\", last: 100) { nodes { url } } } } } } }" }'  https://api.github.com/graphql | jq . | awk -F'"' '/url/ { print $4 }'  | while read ISSUE
    do
        printf "<item>\n<title>\n"
        curl -s -u :$TOKEN $(echo $ISSUE | awk -F"/" '{ print "https://api.github.com/repos/"$4"/"$5"/"$6"/"$7 }') | jq .title
        printf "</title>\n<link>"
        echo $ISSUE
        printf "</link>\n</item>\n"
    done
}

echo '<?xml version="1.0" encoding="UTF-8" ?>'
echo '<rss version="2.0">'
echo '<channel>'

for ORG in $ORGS
do
        get_issues "github"
done
printf "\n</channel>\n</rss>\n"

import feedparser
import requests
import string

link = ""

feed = 'https://github.com/trimstray/the-book-of-secret-knowledge/commits/master.atom'
raw = feedparser.parse(feed)

print('<?xml version="1.0" encoding="UTF-8" ?>', "\n", '<rss version="2.0">')
print('<channel>\n<title>Trimstray</title>\n<description>Whats New</description>\n<link>', link, "</link>\n")

for entry in raw.entries:
        print("<item>\n\t<title>", entry.title, "</title>\n\t<link>", entry.link, "</link>")
        print('<description><![CDATA[')

        patch = requests.get(entry.link + '.patch', verify=False)

        for line in patch.text.split("\n"):
                try:
                        lead = list(line)[0]

                        if list(line)[0] == "+" and list(line)[1] != "+":
                                print(line, "<br>\n")

                except Exception:
                        continue

        print(' ]]></description>', "\n</item>\n")

print("\n</channel>\n</rss>\n")

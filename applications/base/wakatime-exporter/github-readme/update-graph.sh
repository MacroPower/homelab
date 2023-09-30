#!/bin/bash

go install github.com/MacroPower/prometheus_ascii@latest

git clone $WAKATIME_GITHUB_REPO_URL
cd MacroPower
git config user.email "jacobcolvin1+bot@gmail.com"
git config user.name "[bot] MacroPower"

GRAPH=$(prometheus_ascii \
    --server.endpoint="http://prometheus-operated.prometheus.svc:9090" \
	--query.selector="wakatime_cumulative_seconds_total" \
	--graph.width="100" \
	--graph.height="12" \
	--query.duration="168h")

# Store generated content in a file to avoid problems with sed and special characters.
touch insert_file

echo -e "\n\`\`\`" >>insert_file

echo -e "$GRAPH" >>insert_file

# Append X axis labels. TODO: add support to asciigraph
echo -e "             ┼─────────────┬─────────────┬─────────────┬─────────────┬─────────────┬─────────────┬─────────────┤ " >>insert_file
echo -e "            -7d           -6d           -5d           -4d           -3d           -2d           -1d           now" >>insert_file

echo -e "\`\`\`\n" >>insert_file

COMMENT_START="<!-- START_SECTION:ascii_graph -->"
COMMENT_END="<!-- END_SECTION:ascii_graph -->"

NEW_README=$(sed -e "/$COMMENT_START/,/$COMMENT_END/{ /$COMMENT_START/{p; r insert_file
        }; /$COMMENT_END/p; d }" README.md)

rm insert_file

echo "$NEW_README" >README.md

git add README.md
git commit -m "Update graph : $(date)"

git push $WAKATIME_GITHUB_REPO_URL

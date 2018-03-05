#!/usr/bin/env python

import json,sys

data=json.load(sys.stdin)

if len(data) == 0:
    print("No data")
else:
    for issue in data:
        fileName = ".git/issues/{0}".format(issue["number"])
        f = open(fileName, "w")
        f.write(issue["title"])
        f.close()

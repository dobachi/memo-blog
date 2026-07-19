#!/usr/bin/env python3

import glob
import os
import re

print("# Category")

bin_path = os.path.dirname(os.path.abspath(__file__))
home_path = os.path.abspath(os.path.join(bin_path, ".."))

print(bin_path)
print(home_path)

re_pat = "^(?!.*/page.*)(.*public/categories/)(.*)$"
glob_list = glob.glob(home_path + "/public/categories/**", recursive=True)

for g in glob_list:
    if os.path.isdir(g):
        result = re.match(re_pat, g)
        if result != None:
            cat_str = result.group(2)
            category = cat_str.split("/")
            for keywords in category:
                print("  - " + keywords.replace("-", " "))
            print("")

print("# Tag")

re_pat = "(.*public/tags/)(.*)$"
glob_list = glob.glob(home_path + "/public/tags/*")
for g in glob_list:
    if os.path.isdir(g):
        result = re.match(re_pat, g)
        print("  - " + result.group(2).replace("-", " ").strip("/"))

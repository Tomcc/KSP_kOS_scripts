import re

names = ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "A", "S", "D", "F", "G", "H", "J", "K", "L", "Z", "X", "C", "V", "B", "N", "M", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
counter = 0

keywords = ["THROTTLE", "HEADING", "STEERING"]

with open('hop.ks', 'r') as f:
	content = f.read()

	content = re.sub("//.*", "", content)
	content = re.sub("([\w])(\s+)([^\w.])", "\\1\\3", content)
	content = re.sub("([^\w.])(\s+)([\w])", "\\1\\3", content)

	for i in range(3):
		content = re.sub("([\W])(\s+)([\W])", "\\1\\3", content)

	content = re.sub("\. ", ".\n", content)

	decls = set()
	for s in re.findall("\WSET\s+[\w]+\s", content):
		decls.add(s[5:-1])

	for s in re.findall("\WLOCAL\s+[\w]+\s", content):
		decls.add(s[7:-1])

	for s in re.findall("\WFUNCTION\s+[\w]+\W", content):
		decls.add(s[10:-1])

	for s in re.findall("\WLOCK\s+[\w]+\W", content):
		decls.add(s[6:-1])

	for k in keywords:
		decls.discard(k)

	for d in decls:
		content = re.sub("(\W)(" + d + ")(\W)", "\\1" + names[counter] + "\\3", content )
		counter = counter + 1

	print(content)
	
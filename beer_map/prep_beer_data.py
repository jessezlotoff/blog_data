#####
# Prep raw beer data for use in R
# Jesse Zlotoff
# 8/19/18
# Updated 6/24/25 to run in Python3, strip address and phone from intermediate files
#####

import re
import pandas as pd

f = open('brewers_association_raw.txt', 'r')
lines = f.readlines()
f.close()

mapre = re.compile(r'(.*) \| Map\n')
phre = re.compile(r'^Phone: (.*)\n')
web1re = re.compile(r'^www\..*')
web2re = re.compile(r'.*\.com\n')
typere = re.compile(r'^Type: (.*)\n')
abre = re.compile(r'Greater than (\d+). ownership by Anheuser\-Busch InBev.\n')
adr2re = re.compile(r'.*, [A-Z]{2}( \d+)?(.\d+)?\n')

all_breweries = []
i = 0
raw = {'name': '', 'addr1': '', 'addr2': '', 'phone': '',
	'url': '', 'type': '', 'seal_brewer_member': '',
	'ba_associate_member': '', 'ab_inbev': ''}
cur = raw.copy()
flags = 0

while i < len(lines):
	if mapre.match(lines[i]): # map line/start of new brewery
		if cur['name']:
			all_breweries.append(cur)
			cur = raw.copy()
		cur['name'] = lines[i-2].strip()
		cur['addr1'] = lines[i-1].strip()
		cur['addr2'] = mapre.sub(r'\1', lines[i])

	if phre.match(lines[i]):
		if cur['phone']:
			all_breweries.append(cur)
			cur = raw.copy()
			cur['name'] = lines[i-2].strip()
			cur['addr2'] = lines[i-1].strip()
		cur['phone'] = phre.sub(r'\1', lines[i])

	if web1re.match(lines[i]) or web2re.match(lines[i]):
		if cur['url']:
			all_breweries.append(cur)
			cur = raw.copy()
		cur['url'] = lines[i].strip()

	if typere.match(lines[i]):
		if cur['type']:
			if adr2re.match(lines[i-1]):
				all_breweries.append(cur)
				cur = raw.copy()
				cur['name'] = lines[i-2].strip()
				cur['addr2'] = lines[i-1].strip()
			elif lines[i-1] == ',\n' or re.match(r'.*, [A-Z][A-Za-z] ?.*\n',lines[i-1]): # type after addr line with just a comma
				all_breweries.append(cur)
				cur = raw.copy()
				cur['name'] = lines[i-2].strip()
				cur['addr2'] = lines[i-1].strip()
			elif phre.match(lines[i-1]):
				all_breweries.append(cur)
				cur = raw.copy()
				cur['name'] = lines[i-3].strip()
				cur['addr2'] = lines[i-2].strip()
				cur['phone'] = phre.sub(r'\1', lines[i-1])
			else:
				flags += 1
				print('2nd type found at line'), i+1

		cur['type'] = typere.sub(r'\1', lines[i])

	if lines[i] == 'Independent Craft Brewers SealBrewers Association Member\n':
		if cur['seal_brewer_member']:
			flags += 1
			print('2nd seal_brewer_member found at line', i+1)
			cur = raw.copy()
		cur['seal_brewer_member'] = 'Y'

	if lines[i] == 'BA Associate Member\n':
		if cur['ba_associate_member']:
			flags += 1
			print('2nd ba_associate_member found at line', i+1)
			cur = raw.copy()
		cur['ba_associate_member'] = 'Y'

	if abre.match(lines[i]):
		if cur['ab_inbev']:
			flags += 1
			print('2nd ab_inbev found at line', i+1)
			cur = raw.copy()
		cur['ab_inbev'] = abre.sub(r'\1', lines[i])

	i += 1

if cur:
	all_breweries.append(cur)

print(len(all_breweries), 'breweries found')
print(flags, 'flags raised')

df = pd.DataFrame(all_breweries)

# pull out state
df['state'] = df['addr2'].str.replace(r'^.*, ([a-zA-Z]{2})( [\d-]+)?.*', r'\1', regex=True)
df.loc[df['state']=='Ma', 'state'] = 'ME' # Maine
df['state'] = df['state'].str.upper()
df['state'] = df['state'].replace(',', '')

# suppress PII
df = df.drop(['addr1', 'addr2', 'phone'], axis='columns')

df = df.drop_duplicates()
print(len(df), 'breweries after cleaning')

df.to_csv('all_breweries.csv', index=False)


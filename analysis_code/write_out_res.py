import codecs
from time import sleep
import json
import pymongo
from pymongo import MongoClient
from itertools import izip_longest
from collections import defaultdict
from pyquery import PyQuery as pq
import sys

def print_json(json_data):
	print json.dumps(json_data, sort_keys=True,indent=4, separators=(',', ': '))

def write_tweet(tweet,out_file):
	dat = [unicode(tweet[field]) for field in fields]
	user = [unicode(tweet["user"][f]) for  f in mult_fields["user"]]
	entities = [unicode(len(tweet["entities"][f])) for  f in mult_fields["entities"]]
	dat.append(pq(tweet["source"]).text().replace(","," "))
	dat.append(unicode(tweet["in_reply_to_status_id"] is not None))
	out_file.write(",".join(dat+user+entities) + "\n")




##Specify your users here
##TODO: get from config
users = ["kjoseph","cmu_tt","cmu_casos","cmu_tt4","cmu_tt5"]

directory = sys.argv[1]
collection_name = sys.argv[2]

fields = ["id","created_at","filter_level"]

mult_fields = {"user": ["id","followers_count","friends_count","favourites_count","statuses_count","verified"],
			   "entities" : ["hashtags","urls","user_mentions"]}

client = MongoClient()

out_file = codecs.open(directory+"/tweet_descrip_"+collection_name+".csv","w","utf-8") 

print 'collection name: ' + collection_name

header = []
for field in fields:
	header.append(field)
header += ["source","is_reply"]
for f in mult_fields["user"]:
	header.append("user_"+f)
for f in mult_fields["entities"]:
	header.append(f+"_count")


print ",".join(header)+"\n"
out_file.write(",".join(header)+"\n")

fin = set()

for user in users:
	db = client[user]
	collection_to_use = db[collection_name]
	collection_to_use.ensure_index([("id",pymongo.ASCENDING)])

	print 'starting'
	if len(fin) == 0:
		for tweet in collection_to_use.find():
			write_tweet(tweet, out_file)
			fin.add(tweet["id"])
	else: 
		in_db = set(collection_to_use.distinct("id"))
		difference_set =  in_db.difference(fin)
		for tw_id in difference_set:
			tweet = collection_to_use.find_one({"id":tw_id})
			write_tweet(tweet,out_file)
			fin.add(tweet["id"])
	

out_file.close()
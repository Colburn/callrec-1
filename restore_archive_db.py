import lxml.etree as ET
import pg
import glob
import zipfile


filemask = '/home/admin/archive/archive*.zip'
files = glob.glob(filemask)

database = 'callrec'
port = 5432
user = 'callrec'
password = 'callrec'
hostname = 'localhost'
callrec = pg.DB(database, hostname, 5432, None, None, user, password)

callQuery = "insert into calls (id, cplcnt, start_ts, stop_ts, length) values ({0}, '{1}', '{2}', '{3}', '{4}')"
couplesQuery = '''insert into couples
(id, 
callid, 
start_ts, 
stop_ts, 
length, 
cfcnt,  
callingip, 
calledip, 
callingnr, 
originalcallednr, 
finalcallednr, 
callingpartyname, 
calledpartyname, 
cpltype,
problemstatus,
description,
protected,
sid,
synchronized,
deleted,
archived,
b_method,
b_location,
state,
direction,
dayofweek,
timeofday) values 

('{0}', '{1}', '{2}', '{3}', '{4}', '{5}', '{6}', '{7}', '{8}', '{9}', '{10}', '{11}', '{12}', '{13}', '{14}', '{15}', '{16}', '{17}', '{18}', '{19}', '{20}', '{21}', '{22}', '{23}', '{24}', '{25}', '{26}')
'''
extDataQuery="insert into couple_extdata (cplid, key, value) values ('{0}', '{1}', '{2}')"

callDict = []
def xmlToDict(root):
	for parent in root:
		if parent.tag == 'call':
			d = {}
			d[parent.tag] = {}
			d[parent.tag]['value'] = parent.attrib
			d[parent.tag]['couples'] = []
			for child in parent:
				if child.tag == 'cplcnt':
					d[parent.tag]['cplcnt']=child.text
				elif child.tag == 'couple':
					c = {}
		  			c['value'] = child.attrib
		  			c['data'] = []
		  			c['file'] = {}
					for i in child:
						if i.tag == 'data':					
							c['data'].append({i[0].text: i[1].text})
						elif i.tag == 'file':
							for fileData in i:
								c['file'][fileData.tag] = fileData.text
						else:
							c[i.tag] = i.text
					d['call']['couples'].append(c)						
			callDict.append(d)


def updateCalls(filename = ''):
	for i in callDict:
		call = i['call']['value']
		callrec.query(callQuery.format(
			call['id'],
			i['call']['cplcnt'],
			call['start'], 
			call['stop'], 
			call['length']))

		for couple in i['call']['couples']:
			callrec.query(couplesQuery.format(
				couple['value']['id'], 
				call['id'], 
				couple['value']['start'], 
				couple['value']['stop'],
				couple['value']['length'],
				couple['cfcnt'],
				couple['callingIP'],
				couple['calledIP'],
				couple['callingNr'],
				couple['originalCalledNr'],
				couple['finalCalledNr'],
				couple['callingPartyName'],
				couple['calledPartyName'],
				couple['cpltype'],
				couple['problemStatus'],
				couple['description'],
				'f',
				couple['sid'],
				couple['synchroFlag'],
				'D',
				'A',
				'ARC',
				filename,
				couple['state'],
				couple['coupleDirection'],
				couple['dayOfWeek'],
				couple['timeOfDay']
				))

			for dataValue in couple['data']:
				callrec.query(extDataQuery.format(couple['value']['id'], dataValue.keys()[0], dataValue[dataValue.keys()[0]]))

for filename in files:

	archive = zipfile.ZipFile(filename, 'r')
	xmldata = archive.read('calls.xml')

	root = ET.fromstring(xmldata)

	xmlToDict(root)
	updateCalls(filename)

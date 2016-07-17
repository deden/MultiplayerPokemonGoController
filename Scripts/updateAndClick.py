import xml.etree.cElementTree as ET
import urllib2
import json
import os
import time

lastLat = ""
lastLng = ""
lastPos = []

def getPokemonLocation():
    try:
        response = urllib2.urlopen("http://192.168.1.178/", timeout=10)
        return json.load(response)
    except urllib2.URLError as e:
        print e.reason


def clickAction():
    if os.path.isfile("click.applescript"):
				os.system("osascript click.applescript > /dev/null 2>&1")

def generateXMLs():
	global lastPos
	folders = ["player1", "player2"]
	geo = getPokemonLocation()
	if geo != None:
		if len(geo):
			newPos = []
			for i in range(len(geo)):
				pos = geo[i]
				if len(lastPos) != len(geo) or pos["lat"] != lastPos[i]["lat"] or pos["lng"] != lastPos[i]["lng"]:
					dic = {'lat': pos["lat"], 'lng' : pos["lng"]}
					newPos.append(dic)
					gpx = ET.Element("gpx", version="1.1", creator="Xcode")
					wpt = ET.SubElement(gpx, "wpt", lat=pos["lat"], lon=pos["lng"])
					ET.SubElement(wpt, "name").text = "PokemonLocation"
					ET.ElementTree(gpx).write("".join((folders[i], "/pokemonLocation.gpx")))
					print "Location ", i, "Updated!", "latitude:", pos["lat"], "longitude:" ,pos["lng"]
			lastPos = newPos
			clickAction()

def start():
	while True:
		generateXMLs()
		time.sleep(0.5)

start()
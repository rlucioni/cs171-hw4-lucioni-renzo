import json
from datetime import datetime

# In order for this script to work, the original allData2003_2004.json 
# file must be downloaded and placed in this directory!
f = open('allData2003_2004.json', 'r')
g = open('aggregated-radiation-data.json', 'wb')

raw = json.load(f)

# Since month-by-month aggregation isn't required for the final 
# visualization, I've chosen to aggregate by hour only.
aggregated = {}
for station, measurements in raw.iteritems():
    # Note my use of a 24-element array to hold hourly sums.
    aggregated[station] = {'sum': 0, 'hourly': [0]*24}
    for measurement in measurements:
        value = measurement['value']
        aggregated[station]['sum'] += value

        date = datetime.strptime(measurement['date'], "%b %d, %Y %I:%M:%S %p")
        ix = int(date.strftime('%H'))
        aggregated[station]['hourly'][ix] += value

g.write(json.dumps(aggregated, indent=2))

f.close()
g.close()

# Mike Bostock's margin convention
margin =
    top:    20,
    right:  20,
    bottom: 20,
    left:   20

canvasWidth = 1100 - margin.left - margin.right
canvasHeight = 800 - margin.bottom - margin.top

svg = d3.select("#visualization").append("svg")
    .attr("width", canvasWidth + margin.left + margin.right)
    .attr("height", canvasHeight + margin.top + margin.top)
    .append("g")
    .attr("transform", "translate(#{margin.left}, #{margin.top})")

bbFocus =
    x: 50,
    y: 10,
    width: canvasWidth - 50,
    height: 350

mapX = canvasWidth/2
mapY = canvasHeight/2 - 100

focusFrame = svg.append("g")
    .attr("transform", "translate(#{bbFocus.x}, #{bbFocus.y})")

projection = d3.geo.albersUsa()
    .translate([mapX, mapY])
    # .precision(.1)
path = d3.geo.path().projection(projection)

# dataset = {}

loadStations = () ->
    d3.csv("../data/NSRDB_StationsMeta.csv", (error, data) ->

    )

loadStats = () ->
    d3.json("../data/reducedMonthStationHour2003_2004.json", (error, data) ->
        completeDataSet = data  
        loadStations()
    )

d3.json("../data/us-named.json", (data) ->
    usMap = topojson.feature(data, data.objects.states).features
    console.log usMap

    svg.selectAll("path")
        .data(usMap)
        .enter()
        .append("path")
        .attr("d", path)

    # loadStats()
)

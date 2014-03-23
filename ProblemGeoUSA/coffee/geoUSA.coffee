# Mike Bostock's margin convention
margin =
    top: 50,
    right: 50,
    bottom: 50,
    left: 50

canvasWidth = 1060 - margin.left - margin.right
canvasHeight = 800 - margin.bottom - margin.top

bbVis =
    x: 100,
    y: 10,
    width: canvasWidth - 100,
    height: 300

focusFrame = d3.select("#focusVis").append("svg")
    .attr("width", 350)
    .attr("height", 200)

canvas = d3.select("#vis").append("svg")
    .attr("width", canvasWidth + margin.left + margin.right)
    .attr("height", canvasHeight + margin.top + margin.bottom)

svg = canvas.append("g")
    .attr("transform", "translate(#{margin.left}, #{margin.top})")

projection = d3.geo.albersUsa()
    .translate([canvasWidth / 2, canvasHeight / 2])
    # .precision(.1);
path = d3.geo.path().projection(projection)

dataSet = {}

loadStations = () ->
    d3.csv("../data/NSRDB_StationsMeta.csv", (error, data) ->

    )

loadStats = () ->
    d3.json("../data/reducedMonthStationHour2003_2004.json", (error, data) ->
        completeDataSet = data;    
        loadStations()
    )

d3.json("../data/us-named.json", (error, data) ->
    usMap = topojson.feature(data, data.objects.states).features
    console.log usMap

    # see http://bl.ocks.org/mbostock/4122298
    # svg.selectAll(".country").data(usMap).enter()

    loadStats();
)

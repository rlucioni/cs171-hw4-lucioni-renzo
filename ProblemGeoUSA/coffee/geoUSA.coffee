# Mike Bostock's margin convention
margin =
    top:    20,
    right:  20,
    bottom: 20,
    left:   20

canvasWidth = 1200 - margin.left - margin.right
canvasHeight = 800 - margin.bottom - margin.top

svg = d3.select("#visualization").append("svg")
    .attr("width", canvasWidth + margin.left + margin.right)
    .attr("height", canvasHeight + margin.top + margin.top)
    .append("g")
    .attr("transform", "translate(#{margin.left}, #{margin.top})")

bbContext =
    x: 0,
    y: 0,
    width: canvasWidth,
    height: 500

contextOuterFrame = svg.append("g")
    .attr("transform", "translate(#{bbContext.x}, #{bbContext.y})")

# Clipping mask
contextOuterFrame.append("clipPath")
    .attr("id", "clip")
    .append("rect")
    .attr("width", bbContext.width)
    .attr("height", bbContext.height)

contextFrameMask = contextOuterFrame.append("g").attr("clip-path", "url(#clip)")

contextInnerFrame = contextFrameMask.append("g")
    .attr("width", bbContext.width)
    .attr("height", bbContext.height)

contextInnerFrame.append("rect")
    .attr("id", "contextBackground")
    .attr("width", bbContext.width)
    .attr("height", bbContext.height)
    .on("click", clicked);

bbFocus =
    x: 0,
    y: 500,
    width: canvasWidth,
    height: 300

focusFrame = svg.append("g")
    .attr("transform", "translate(#{bbFocus.x}, #{bbFocus.y})")

# Used for centering map
mapX = bbContext.width/2
mapY = bbContext.height/2

projection = d3.geo.albersUsa().translate([mapX, mapY])
path = d3.geo.path().projection(projection)

# Indentifies centered state
centered = null
clicked = (d) ->
    [x, y, k] = [0, 0, 0]

    if d and (centered != d)
        centroid = path.centroid(d)
        x = centroid[0]
        y = centroid[1]
        k = 4
        centered = d
    else
        x = mapX
        y = mapY
        k = 1
        centered = null

    contextInnerFrame.selectAll("path")
        .classed("active", centered and ((d) -> d == centered))

    contextInnerFrame.transition()
        .duration(750)
        .attr("transform", "translate(#{mapX}, #{mapY})scale(#{k})translate(#{-x}, #{-y})")
        .style("stroke-width", "#{1.5/k}px")

loadStations = () ->
    d3.csv("../data/NSRDB_StationsMeta.csv", (error, data) ->

    )

loadStats = () ->
    d3.json("../data/reducedMonthStationHour2003_2004.json", (error, data) ->
        completeDataSet = data  
        loadStations()
    )

d3.json("../data/us-named.json", (data) ->
    contextInnerFrame.append("g")
        .attr("id", "states")
        .selectAll("path")
        .data(topojson.feature(data, data.objects.states).features)
        .enter()
        .append("path")
        .attr("class", "state")
        .attr("d", path)
        .on("click", clicked)

    contextInnerFrame.append("path")
        .datum(topojson.mesh(data, data.objects.states, (a, b) -> a != b))
        .attr("id", "state-borders")
        .attr("d", path)

    # loadStats()
)

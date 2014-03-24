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
    .style("stroke-width", "1.5px")

# Used for centering map
mapX = bbContext.width/2
mapY = bbContext.height/2

# Contains active (i.e., centered) state
active = d3.select(null)

clicked = (d) ->
    return reset() if (active.node() == this)
    active.classed("active", false)
    active = d3.select(this).classed("active", true)

    bounds = path.bounds(d)
    dx = bounds[1][0] - bounds[0][0]
    dy = bounds[1][1] - bounds[0][1]
    x = (bounds[0][0] + bounds[1][0])/2
    y = (bounds[0][1] + bounds[1][1])/2
    scale = 0.9/Math.max(dx/bbContext.width, dy/bbContext.height)
    translate = [bbContext.width/2 - scale*x, bbContext.height/2 - scale*y]

    contextInnerFrame.transition()
        .duration(750)
        .style("stroke-width", "#{1.5/scale}px")
        .attr("transform", "translate(#{translate})scale(#{scale})")

reset = () ->
    active.classed("active", false)
    active = d3.select(null)

    contextInnerFrame.transition()
        .duration(750)
        .style("stroke-width", "1.5px")
        .attr("transform", "")

contextInnerFrame.append("rect")
    .attr("id", "contextBackground")
    .attr("width", bbContext.width)
    .attr("height", bbContext.height)
    .on("click", reset)

bbFocus =
    x: 0,
    y: 500,
    width: canvasWidth,
    height: 300

focusFrame = svg.append("g")
    .attr("transform", "translate(#{bbFocus.x}, #{bbFocus.y})")

projection = d3.geo.albersUsa().translate([mapX, mapY])
path = d3.geo.path().projection(projection)

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

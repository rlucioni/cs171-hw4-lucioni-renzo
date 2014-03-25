# Mike Bostock's margin convention
margin =
    top:    20,
    right:  20,
    bottom: 20,
    left:   20

canvasWidth = 1100 - margin.left - margin.right
canvasHeight = 750 - margin.bottom - margin.top

svg = d3.select("#visualization").append("svg")
    .attr("width", canvasWidth + margin.left + margin.right)
    .attr("height", canvasHeight + margin.top + margin.top)
    .append("g")
    .attr("transform", "translate(#{margin.left}, #{margin.top})")

bbContext =
    x: 0,
    y: 0,
    width: canvasWidth,
    height: 470

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
    x: 70,
    y: 500,
    width: canvasWidth - 70,
    height: 180

offset = 
    focusGraph: 30
    focusTitle: 200
    tooltip: 5

focusFrame = svg.append("g")
    .attr("transform", "translate(#{bbFocus.x}, #{bbFocus.y})")

focusXScale = d3.scale.linear().range([0, bbFocus.width])
focusYScale = d3.scale.linear().range([bbFocus.height + offset.focusGraph, offset.focusGraph])

focusXAxis = d3.svg.axis().scale(focusXScale).orient("bottom")
focusYAxis = d3.svg.axis().scale(focusYScale)
    .ticks([5])
    .orient("left")

focusLine = d3.svg.line()
    .interpolate("linear")
    .x((d) -> focusXScale(d.hour))
    .y((d) -> focusYScale(d.ghi))

focusArea = d3.svg.area()
    .x((d) -> focusXScale(d.hour))
    .y0(bbFocus.height + offset.focusGraph)
    .y1((d) -> focusYScale(d.ghi))

projection = d3.geo.albersUsa()
    .scale(975)
    .translate([mapX, mapY])
path = d3.geo.path().projection(projection)

# Used to scale radiation total to circle radius
sumScaledown = 2000000
padding =
    labelX: 5
    labelY: 7

# Utility function for adding commas as thousands separators
addCommas = (number) ->
    number.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")

constructHourlyObject = (hourly) ->
    dataset = []
    ix = 0
    for ghi in hourly
        dataset.push({'hour': ix, 'ghi': ghi})
        ix += 1

    return dataset

zeroes = constructHourlyObject((0 for [0..23]))

drawVisualization = (states, stations) ->
    contextInnerFrame.append("g")
        .attr("id", "states")
        .selectAll("path")
        .data(topojson.feature(states, states.objects.states).features)
        .enter()
        .append("path")
        .attr("class", "state")
        .attr("d", path)
        .on("click", clicked)

    contextInnerFrame.append("path")
        .datum(topojson.mesh(states, states.objects.states, (a, b) -> a != b))
        .attr("id", "state-borders")
        .attr("d", path)

    contextInnerFrame.selectAll("circle")
        .data(stations)
        .enter()
        .append("circle")
        .attr("class", (d) ->
            if d.sum != 0
                return "station hasData"
            else
                return "station noData"
        )
        .attr("cx", (d) -> projection([d.lon, d.lat])[0])
        .attr("cy", (d) -> projection([d.lon, d.lat])[1])
        .attr("r", (d) -> return 2 + Math.sqrt(d.sum/sumScaledown))

    d3.selectAll(".station.hasData").on("mouseover", (d) ->
        d3.select(this).style("fill", "red")

        d3.select("#tooltip")
            .style("left", "#{d3.event.pageX + offset.tooltip}px")
            .style("top", "#{d3.event.pageY + offset.tooltip}px")
        d3.select("#name").text("#{d.name}")
        d3.select("#ghi").text("#{addCommas(d.sum)}")
        d3.select("#tooltip").classed("hidden", false)
    )

    d3.selectAll(".station.hasData").on("mouseout", () ->
        d3.select(this).transition().duration(500).style("fill", "#33a02c")
        d3.select("#tooltip").classed("hidden", true)
    )

    # Instantiate focus graph with GHI data for Fallon Naas station, ID 724885
    fallonNaasHourly = [0, 0, 0, 0, 0, 0, 668600, 2479900, 5069900, 7754400, 10107600, 11763600, 12639300, 12680100, 11826500, 9879300, 7816900, 5185600, 2419600, 523300, 0, 0, 0, 0]
    focusXScale.domain([0, 23])
    focusYScale.domain([0, d3.max(fallonNaasHourly)])

    dataset = constructHourlyObject(fallonNaasHourly)
    
    focusFrame.append("g").attr("class", "x axis focus")
        .attr("transform", "translate(0, #{bbFocus.height + offset.focusGraph})")
        .call(focusXAxis)
    focusFrame.append("g").attr("class", "y axis focus")
        .call(focusYAxis)
    
    focusFrame.append("text")
        .attr("class", "title focus")
        .attr("text-anchor", "middle")
        .attr("transform", "translate(#{bbFocus.width/2}, 0)")
        .text("FALLON NAAS")
    focusFrame.append("text")
        .attr("class", "x label focus")
        .attr("text-anchor", "end")
        .attr("x", bbFocus.width - padding.labelX)
        .attr("y", bbFocus.height + offset.focusGraph - padding.labelY)
        .text("Hour")
    focusFrame.append("text")
        .attr("class", "y label focus")
        .attr("text-anchor", "end")
        .attr("y", padding.labelY)
        .attr("x", -offset.focusGraph)
        .attr("dy", ".75em")
        .attr("transform", "rotate(-90)")
        .text("GHI (lx)")

    focusFrame.append("path")
        .datum(dataset)
        .attr("class", "area focus")
        .attr("d", focusArea)

    focusFrame.append("path")
        .datum(dataset)
        .attr("class", "line focus")
        .attr("d", focusLine)

    focusFrame.selectAll(".point.focus")
        .data((dataset))
        .enter()
        .append("circle")
        .attr("class", "point focus")
        .attr("transform", (d) -> "translate(#{focusXScale(d.hour)}, #{focusYScale(d.ghi)})")
        .attr("r", 3)

    updateFocus = (d) ->
        dataset = constructHourlyObject(d.hourly)

        # Reconfigure y-scale domain
        focusYScale.domain([0, d3.max(d.hourly)])
        focusFrame.select(".y.axis.focus")
            .transition().duration(500)
            .call(focusYAxis)

        # Adjust area
        focusFrame.select(".area.focus")
            .datum(zeroes)
            .transition().duration(500)
            .attr("d", focusArea)
        focusFrame.select(".area.focus")
            .datum(dataset)
            .transition().delay(500).duration(500)
            .attr("d", focusArea)

        # Adjust line
        focusFrame.select(".line.focus")
            .datum(zeroes)
            .transition().duration(500)
            .attr("d", focusLine)
        focusFrame.select(".line.focus")
            .datum(dataset)
            .transition().delay(500).duration(500)
            .attr("d", focusLine)

        # Adjust points
        focusFrame.selectAll(".point.focus")
            .transition().duration(500)
            .attr("transform", (d) -> "translate(#{focusXScale(d.hour)}, #{bbFocus.height + offset.focusGraph})")
        focusFrame.selectAll(".point.focus")
            .data((dataset))
            .transition().delay(500).duration(500)
            .attr("transform", (d) -> "translate(#{focusXScale(d.hour)}, #{focusYScale(d.ghi)})")

        # Adjust title, sliding old one(s) off screen and sliding on new one
        focusFrame.selectAll(".title.focus")
            .transition().duration(1000)
            .attr("transform", (d) -> "translate(#{bbFocus.width + offset.focusTitle}, 0)")
            .remove()
        focusFrame.append("text")
            .attr("class", "title focus")
            .attr("text-anchor", "middle")
            .attr("transform", "translate(#{-offset.focusTitle}, 0)")
            .text(d.name)
            .transition().duration(1000)
            .attr("transform", "translate(#{bbFocus.width/2}, 0)")

    d3.selectAll(".station.hasData").on("click", (d) -> updateFocus(d))

d3.json("../data/us-named.json", (states) ->
    d3.csv("../data/NSRDB_StationsMeta.csv", (metadata) ->
        d3.json("../data/aggregated-radiation-data.json", (aggregated) ->
            stations = []
            for row in metadata
                # Ignore stations located outside clipping bounds of Albers USA projection
                if projection([row['NSRDB_LON(dd)'], row['NSRDB_LAT (dd)']]) == null
                    continue
                else
                    # Check to see if we have data 
                    if row['USAF'] of aggregated
                        stations.push(
                            'id': row['USAF']
                            'name': row['STATION']
                            'lon': row['NSRDB_LON(dd)']
                            'lat': row['NSRDB_LAT (dd)']
                            'sum': aggregated[row['USAF'].toString()]['sum']
                            'hourly': aggregated[row['USAF']]['hourly']
                        )
                    else
                        stations.push(
                            'id': row['USAF']
                            'name': row['STATION']
                            'lon': row['NSRDB_LON(dd)']
                            'lat': row['NSRDB_LAT (dd)']
                            'sum': 0
                            'hourly': []
                        )

            # Order stations with smaller sums last, so they are layered on top of 
            # larger circles when being drawn on the map
            stations.sort((a, b) ->
                if a.sum > b.sum
                    return -1
                else if a.sum < b.sum
                    return 1
                else
                    return 0
            )

            drawVisualization(states, stations)
        )
    )
)

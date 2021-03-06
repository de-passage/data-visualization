d3 = Object.assign require("d3"), require("d3-time"), require("d3-scale")
topojson = require "topojson"


$ ->

  totalWidth = window.innerWidth || document.documentElement.clientWidth || document.body.clientWidth
  totalHeight = window.innerHeight || document.documentElement.clientHeight || document.body.clientHeight

  frameHeight = Math.max totalHeight * 0.8, 650
  frameWidth = Math. max totalWidth * 0.9, 850

  chartMargin =
    left: frameWidth * 0.08
    right: frameWidth * 0.04
    top: frameHeight * 0.1
    bottom: frameHeight * 0.08

  chartHeight = frameHeight - chartMargin.top - chartMargin.bottom
  chartWidth = frameWidth - chartMargin.left - chartMargin.right
  topMargin = Math.max(0, (totalHeight - frameHeight) / 2)

  tooltip = d3.select(document.body).append("div")
    .classed("tooltip transparent", true)


  do ->
    url = "https://raw.githubusercontent.com/FreeCodeCamp/ProjectReferenceData/master/meteorite-strike-data.json"
    map_url = "https://d3js.org/world-50m.v1.json"
    frame = d3.select("body")
      .append("svg")
      .classed("chart", true)
      .attr("width", frameWidth)
      .attr("height", frameHeight)
    projection = d3.geoEquirectangular()
      .scale(130)
      .rotate([0, 0])
      .center([0, 0])
      .translate([frameWidth / 2, frameHeight / 2])
    geoPath = d3.geoPath()
      .projection(projection)

    d3.json map_url, (error, json) ->
      if error?
        console.log "Error: ", JSON.stringify error
        alert "An error has occured while loading the country data. See the logs for more details"
        return
      
      frame.append("g").selectAll("path")
        .data(topojson.feature(json, json.objects.countries).features)
        .enter()
        .append("path")
        .attr("fill", "#CCF")
        .attr("stroke", "#888")
        .attr("d", geoPath)

      d3.json url, (error, json) ->
        if error?
          console.log "Error: ", JSON.stringify error
          alert "An error has occured while loading the geo data. See the logs for more details"

        json.features.sort((a, b) -> b.properties.mass - a.properties.mass)
        massScale = d3.scalePow().exponent(0.5).domain([d3.min(json.features, (d) -> +d.properties.mass), d3.max(json.features, (d) -> +d.properties.mass)]).range([0.5, 20])
        colorScale = d3.scaleLinear().domain([d3.min(json.features, (d) -> +(d.properties.id)), d3.max(json.features, (d) -> +(d.properties.id))]).range([0, 359])

        f = (i) ->
          (d) ->
            projection([d.properties.reclong, d.properties.reclat])[i]
        
        frame.append("g").selectAll("circle")
          .data(json.features)
          .enter()
          .append("circle")
          .attr("cx",f(0))
          .attr("cy",f(1))
          .attr("r", (d) -> massScale +d.properties.mass)
          .style("fill", (d) -> "hsl(#{colorScale(+d.properties.id)}, 100%, 50%)" )
          .style("stroke", "white")
          .style("fill-opacity", (d) -> massScale.range([0.8, 0.3]) d.properties.mass)
          .on("mouseover", (d, i) ->
            coords = d3.mouse document.body
            tooltip.html "Name: #{d.properties.name}<br>
                          Year: #{(new Date d.properties.year).getFullYear()}<br>
                          Mass: #{d.properties.mass}<br>
                          Coordinates:<br>#{(+d.properties.reclat).toFixed(2)}, #{(+d.properties.reclong).toFixed(2)}<br>
                          Class: #{d.properties.recclass}"
            tooltip.classed "transparent", false
            tooltip.style("left", "#{coords[0] + 20}px").style("top", "#{coords[1] + topMargin}px")
          )
          .on("mousemove", ->
            coords = d3.mouse document.body
            tooltip.style("left", "#{coords[0] + 20}px").style("top", "#{coords[1] + topMargin}px"))
          .on("mouseout", -> tooltip.classed "transparent", true)


  do ->
    url = "https://raw.githubusercontent.com/DealPete/forceDirected/master/countries.json"

    frame = d3.select("body")
      .append("div")
      .style("height", "#{frameHeight}px")
      .style("width", "#{frameWidth}px")
      .classed("chart", true)
      .append("div")
      .classed("abspos", true)
      .style("height", "#{frameHeight}px")
      .style("width", "#{frameWidth}px")
      .style("margin-top", topMargin)
    #context = frame.node().getContext("2d")

    d3.json url, (error, json) ->
      if error?
        console.log "Error: ", JSON.stringify error
        alert "An error has occured while loading the country data. See the logs for more details"
        return
      nodes = json.nodes
      links = json.links

      gravity = 0.03

      simulation = d3.forceSimulation()
        .force("link", d3.forceLink().distance(30).strength(1))
        .force("charge", d3.forceManyBody())
        .force("x", d3.forceX(frameWidth / 2).strength(gravity))
        .force("y", d3.forceY(frameHeight / 2).strength(gravity * 1.55))
        .force("center", d3.forceCenter(frameWidth / 2, frameHeight / 2))

      drawGraph = (n, l) ->
        l
          .attr("x1", (d) -> d.source.x)
          .attr("y1", (d) -> d.source.y)
          .attr("x2", (d) -> d.target.x)
          .attr("y2", (d) -> d.target.y)
        n
          .style("left", (d) -> (d.x - 8)  + "px")
          .style("top", (d) -> (d.y - 5) + "px")

      link = frame.append("svg")
        .attr("width", frameWidth)
        .attr("height", frameHeight)
        .selectAll("line")
        .data(links)
        .enter().append("line")
        .style("stroke-width", (d) -> Math.sqrt d.value + "px")
        .style("stroke", "#CCC")

      lookupNeighbours = (idx) ->
        sourceLinks = (l.target.country for l in links when l.source.index == idx)
        targetLinks = (l.source.country for l in links when l.target.index == idx)
        sourceLinks.push target for target in targetLinks when sourceLinks.indexOf target == -1
        sourceLinks.join(", ")

      node = frame
        .selectAll("img")
        .data(nodes)
        .enter().append("img")
        .attr("class", (d) -> "flag flag-#{d.code}")
        .on("mouseover", (d, i) ->
          coords = d3.mouse document.body
          tooltip.html "Country: #{d.country}<br><br>Neighbours: #{lookupNeighbours(i)}"
          tooltip.classed "transparent", false
          tooltip.style("left", "#{coords[0] + 20}px").style("top", "#{coords[1] + topMargin}px")
        )
        .on("mousemove", ->
          coords = d3.mouse document.body
          tooltip.style("left", "#{coords[0] + 20}px").style("top", "#{coords[1] + topMargin}px"))
        .on("mouseout", -> tooltip.classed "transparent", true)

      simulation
        .nodes(nodes)
        .on("tick", -> drawGraph(node, link))

      simulation
        .force("link")
        .links(links)



  do ->
    url = "https://raw.githubusercontent.com/FreeCodeCamp/ProjectReferenceData/master/global-temperature.json"

    frame = d3.select("body")
      .append("svg")
      .classed("chart", true)
      .attr("height", "#{frameHeight}")
      .attr("width", "#{frameWidth}")
      .style("margin-top", topMargin)
    chart = frame.append("g")
      .attr("transform", "translate(#{chartMargin.left}, #{chartMargin.top})")

    d3.json url, (error, json) ->
      if error?
        console.log "Error: ", JSON.stringify error
        alert "An error has occured while loading the heat map data. See the logs for more details"
        return

      data = json.monthlyVariance

      colors = ["darkblue", "blue", "yellow", "orange", "red", "darkred"]
      months = ["Jan.", "Feb.", "Mar.", "Apr.", "May", "Jun.", "Jul.", "Aug.", "Sep.", "Oct.", "Nov.", "Dec."]

      minYear = d3.min(data, (d) -> d.year)
      maxYear = d3.max(data, (d) -> d.year)
      totalYears = maxYear - minYear
      monthsDomain = [d3.min(data, (d) -> d.month), d3.max(data, (d) -> d.month)]

      barWidth = chartWidth / totalYears
      barHeight = chartHeight / 12

      xScale = d3.scaleLinear().range([0, chartWidth - barWidth]).domain([minYear, maxYear])
      yScale = d3.scaleLinear().range([0, chartHeight - barHeight]).domain(monthsDomain)
      colorScale = d3.scaleQuantile().range(colors).domain([d3.min(data, (d) -> d.variance), d3.max(data, (d) -> d.variance)])

      chart.selectAll("g")
        .data(data)
        .enter()
        .append("g")
        .attr("transform", (d) -> "translate(#{xScale d.year},#{yScale d.month})")
        .append("rect")
        .attr("width", barWidth)
        .attr("height", barHeight)
        .style("fill", (d) -> colorScale d.variance)
        .on("mouseover", (d) ->
          coords = d3.mouse document.body
          tooltip.html "#{months[d.month - 1]} #{d.year}<br>Variance: #{d.variance}"
          tooltip.classed "transparent", false
          tooltip.style("left", "#{coords[0] + 20}px").style("top", "#{coords[1] + topMargin}px")
        )
        .on("mousemove", ->
          coords = d3.mouse document.body
          tooltip.style("left", "#{coords[0] + 20}px").style("top", "#{coords[1] + topMargin}px"))
        .on("mouseout", -> tooltip.classed "transparent", true)

      yAxis = d3.axisLeft().scale(yScale).tickFormat((d) -> months[d - 1])
      xAxis = d3.axisBottom().scale(xScale)

      chart.append("g")
        .attr("transform", "translate(0, #{chartHeight})")
        .call(xAxis)
        .append("text")
        .classed("legend", true)
        .text("Year")
        .attr("x", "#{chartWidth/2}px")
        .attr("y", "#{chartMargin.bottom * 0.8}px")
        .style("text-anchor", "middle")

      chart.append("g")
        .attr("transform","translate(0,0)")
        .call(yAxis)
        .append("text")
        .text("Month")
        .classed("legend", true)
        .attr("x", "-#{chartHeight/2}px")
        .attr("y", "-55px")
        .attr("dy", ".35em")
        .style("text-anchor", "middle")
        .attr("transform", "rotate(-90)")

      frame.append("text")
        .attr("x", "20px")
        .attr("text-anchor", "start")
        .attr("y", "#{chartMargin.top * 0.6}px")
        .classed("title", true)
        .text("Heat map")

      frame.append("text")
        .attr("x", frameWidth - 10)
        .attr("text-anchor", "end")
        .attr("y", "#{chartMargin.top * 0.3}px")
        .text("Variance from global average (#{json.baseTemperature})")

      legendSize = 25

      frame.append("g")
        .attr("transform", "translate(#{frameWidth - 100 - (colors.length*legendSize)},#{chartMargin.top * 0.5})")
        .selectAll("rect")
        .data(colors)
        .enter()
        .append("rect")
        .attr("transform", (d, i) -> "translate(#{i * legendSize}, 0)")
        .attr("width", legendSize)
        .attr("height", legendSize)
        .style("fill", (d) -> d)
        .on("mouseover", (d) ->
          coords = d3.mouse document.body
          tooltip.html "Inteval: [#{colorScale.invertExtent(d)[0].toFixed(1)}, #{colorScale.invertExtent(d)[1].toFixed(1)}]"
          tooltip.classed "transparent", false
          tooltip.style("left", "#{coords[0] + 20}px").style("top", "#{coords[1] + topMargin}px")
        )
        .on("mousemove", ->
          coords = d3.mouse document.body
          tooltip.style("left", "#{coords[0] + 20}px").style("top", "#{coords[1] + topMargin}px"))
        .on("mouseout", -> tooltip.classed "transparent", true)


  do ->

    url = "https://raw.githubusercontent.com/FreeCodeCamp/ProjectReferenceData/master/cyclist-data.json"

    frame = d3.select("body")
      .append("svg")
      .classed("chart", true)
      .attr("height", "#{frameHeight}px")
      .attr("width", "#{frameWidth}px")
      .style("margin-top", topMargin)
    chart = frame.append("g")
      .attr("transform", "translate(#{chartMargin.left},#{chartMargin.top})")

    xAxis = d3.scaleLinear().range([0, chartWidth])
    yAxis = d3.scaleTime().range([0, chartHeight])

    timeParser = d3.timeParse("%M:%S")

    $.getJSON url, (data) ->

      xAxis.domain([d3.min(data, (d) -> d.Place) - 1, d3.max(data, (d) -> d.Place)])
      shortestTime = new Date d3.min(data, (d) -> timeParser d.Time).getTime() - 15000
      longestTime = d3.max(data, (d) -> timeParser d.Time)
      yAxis.domain([longestTime, shortestTime])
      
      chart.selectAll("g")
        .data(data)
        .enter()
        .append("g")
        .attr("transform", (d, i) -> "translate(#{xAxis(d.Place)}, #{yAxis timeParser d.Time})")
        .append("circle")
        .attr("r", "5")
        .style("fill", (d) -> if d.Doping != "" then "red" else "steelblue")
        .on("mouseover", (d) ->
          coords = d3.mouse document.body
          tooltip.html "Name: #{d.Name}<br>Nationality: #{d.Nationality}<br>Year: #{d.Year}<br>Time: #{d.Time}<br>Time Ranking: #{d.Place}#{if d.Doping != "" then "<br><br>" + d.Doping else ""}"
          tooltip.classed "transparent", false
          tooltip.style("left", "#{coords[0] + 20}px").style("top", "#{coords[1] + topMargin}px")
        )
        .on("mousemove", ->
          coords = d3.mouse document.body
          tooltip.style("left", "#{coords[0] + 20}px").style("top", "#{coords[1] + topMargin}px"))
        .on("mouseout", -> tooltip.classed "transparent", true)

      xAxisRender = d3.axisBottom().scale(xAxis).tickFormat((d) -> if d then d else "")
      yAxisRender = d3.axisLeft().scale(yAxis).ticks(d3.timeSecond, 15).tickFormat(d3.timeFormat("%M:%S"))
      chart.append("g")
        .attr("transform", "translate(0, #{chartHeight})")
        .call(xAxisRender)
        .append("text")
        .classed("legend", true)
        .text("Time ranking")
        .attr("x", "#{chartWidth/2}px")
        .attr("y", "#{chartMargin.bottom * 0.8}px")
        .style("text-anchor", "middle")

      chart.append("g")
        .attr("transform","translate(0,0)")
        .call(yAxisRender)
        .append("text")
        .text("Time")
        .classed("legend", true)
        .attr("x", "-#{chartHeight/2}px")
        .attr("y", "-55px")
        .attr("dy", ".35em")
        .style("text-anchor", "middle")
        .attr("transform", "rotate(-90)")

      frame.append("text")
        .attr("x", "#{frameWidth / 2}px")
        .attr("text-anchor", "middle")
        .attr("y", "#{chartMargin.top / 2}px")
        .classed("title", true)
        .text("35 fastest times up Alpe d'Huez and doping allegations")
    
      
      
      





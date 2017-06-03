d3 = Object.assign require("d3"), require("d3-time"), require("d3-scale")

url = "https://raw.githubusercontent.com/FreeCodeCamp/ProjectReferenceData/master/cyclist-data.json"


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
    
    tooltip = d3.select(document.body).append("div")
      .classed("tooltip transparent", true)

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
  
    
    
    





d3 = require("d3")

cycling_url = "https://raw.githubusercontent.com/FreeCodeCamp/ProjectReferenceData/master/cyclist-data.json"

$ ->
  d3.select("body")
    .append("svg")
    .classed("chart", true)
  $.getJSON cycling_url, (data) ->
    document.write JSON.stringify data






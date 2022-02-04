// init type conversion
const parseDate = string => d3.utcParse('%Y')(string);
const parseNA = string => (string === 'NA' ? undefined : string);

// ------------------------------------------------------------------------------
// data return
function type(d) {
  const date = parseDate(d.Decade);

  return {
    Decade: date,
    Country: parseNA(d.Country),
    City: parseNA(d.City),
    Rank: +d.Rank,
    Name: parseNA(d.Name),
    Artist: parseNA(d.Artist),
    energy: +d.energy,
    tempo: +d.tempo,
    danceability: +d.danceability,
    liveness: +d.liveness
  };
}

// data utilities
function filterData(data) {
  return data.filter(d => {
    return (
      d.energy  &&
      d.tempo  &&
      d.danceability  &&
      d.Country &&
      d.Artist &&
      d.City &&
      d.Decade &&
      d.Rank
    );
  });
}

// drawing utilities
function formatTicks(d) {
  return d3
    .format('.5')(d);
}

// abbreviate long string names  
function cutText(string) {
  const cutt = 20; // char limit 
  return string.length < cutt ? string : string.substring(0, cutt) + '...'; // abbrev any long string names
}

// ------------------------------------------------------------------------------
// tooltip handler
function mouseover() {
  
  // pull data
  const barData = d3.select(this).data()[0];

  const bodyData = [ // info to show on mouseover 
    ['Chart rank', barData.Rank],
    ['Country', barData.Country],
    ['Energy', formatTicks(barData.energy)],
    ['Tempo', formatTicks(barData.tempo)],
    ['Danceability', barData.danceability],
    ['Liveness', barData.liveness]
  ];

  // build tooltip
  const tip = d3.select('.tooltip');

  tip
    .style('left', `${event.clientX + 15}px`)
    .style('top', `${event.clientY}px`)
    .transition()
    .style('opacity', 0.98);

  // tooltip text
  tip.select('h3').html(`${barData.Artist} - ${barData.Decade}s`) // tooltip header 
  tip.select('h4').html(`${barData.Name}`);

  // tooltip body
  d3.select('.tip-body') 
    .selectAll('p')
    .data(bodyData)
    .join('p')
    .attr('class', 'tip-info')
    .html(d => `${d[0]}: ${d[1]}`);
}

// tooltip xy position
function mousemove() { 
  d3.select('.tooltip')
    .style('left', `${event.clientX + 15}px`)
    .style('top', `${event.clientY}px`);
}

// tooltip remove event
function mouseout() {
  d3.select('.tooltip')
    .transition()
    .style('opacity', 0);
}

// ------------------------------------------------------------------------------
// main function
function ready(songs) {
  let metric = 'energy'; // default metric  

  // click handler
  function click() {
    metric = this.dataset.name;

    const updatedData = songsClean
      .sort((a, b) => b[metric] - a[metric]); 

    update(updatedData);
  }

  // general update pattern
  function update(data) {
    // Update scales.
    xScale.domain([0, d3.max(data, d => d[metric])]);
    yScale.domain(data.map(d => cutText(d.Artist)));

    // Set up transition.
    const dur = 1000;
    const t = d3.transition().duration(dur);

    // color palette
    var cScale = d3.scaleOrdinal()
    .domain(data.map(d => d.Artist))
    .range(['#5B3794','#5F3894','#623995','#653A96','#693B96','#6C3C97','#6F3D98','#723E98','#754099','#784199','#7B429A','#7D439B','#80459B','#83469C','#85489C','#88499D','#8B4A9E','#8D4C9E','#904D9F','#924F9F','#9550A0','#9752A0','#9953A1','#9C55A2','#9E57A2','#A158A3','#A35AA3','#A55BA4','#A75DA4','#AA5FA5','#AC61A5','#AE62A6','#B064A6','#B266A7','#B468A7','#B669A8','#B86BA8','#BA6DA9','#BC6FA9','#BE71AA','#C073AA','#C274AB','#C476AB','#C678AC','#C87AAD','#CA7CAD','#CC7EAE','#CD80AE','#CF82AF','#D184AF','#D386B0','#D488B0','#D68AB1','#D88CB1','#D98EB2','#DB90B2','#DD92B3','#DE94B4','#E096B4','#E199B5','#E39BB6','#E49DB6','#E69FB7','#E7A1B8','#E8A3B8','#EAA5B9','#EBA8BA','#ECAABB','#EEACBB','#EFAEBC','#F0B0BD','#F1B3BE','#F3B5BF','#F4B7C0','#F5B9C1','#F6BCC2','#F7BEC3','#F8C0C5','#F9C2C6','#F9C5C7','#FAC7C8','#FBC9CA','#FCCCCB','#FCCECD','#FDD1CF','#FDD3D0','#FDD6D2','#FCD8D5','#F8DCD9']);

    // show init data
    bars
      .selectAll('.bar')
      .data(data, d => d.Artist)
      .join(
        enter => {
          enter
            .append('rect')
            .attr('class', 'bar')
            .attr('y', d => yScale(cutText(d.Artist)))
            .attr('height', yScale.bandwidth())
            .transition(t)
            .delay((d, i) => i * 10)
            .attr('width', d => xScale(d[metric]))
            .attr("fill", function(d){ return cScale(d.Artist)});
            
        },

        // update data with button click event 
        update => {
          update
            .transition(t)
            .delay((d, i) => i * 20)
            .attr('y', d => yScale(cutText(d.Artist)))
            .attr('width', d => xScale(d[metric]))
            .attr("fill", function(d){ return cScale(d.Artist)});
        },

        // exit event 
        exit => {
          exit
            .transition()
            .duration(dur / 2)
            .style('fill-opacity', 0.9)
            .remove();
        }
      );

    // update axes
    xAxisDraw.transition(t).call(xAxis.scale(xScale));
    yAxisDraw.transition(t).call(yAxis.scale(yScale));
    yAxisDraw.selectAll('text').attr('dx', '-0.6em');

    // update header
    headline
    .text(
      `Top 20 songs and artists ranked by ${metric} (1960 - 2000)`
      );

    // tooltip interaction
    d3.selectAll('.bar')
      .on('mouseover', mouseover)
      .on('mousemove', mousemove)
      .on('mouseout', mouseout);
  }

  // data prep
  const songsClean = filterData(songs);

  // margins
  const margin = { top: 70, right: 50, bottom: 20, left: 150};
  const width = 900 - margin.right - margin.left;
  const height = 900 - margin.top - margin.bottom;

  // scales
  const xScale = d3
  .scaleLinear()
  .range([0, width]);
  
  const yScale = d3
    .scaleBand()
    .rangeRound([0, height])
    .paddingInner(0.25);

  // chart base
  const svg = d3
    .select('.bar-chart-container')
    .append('svg')
    .attr('width', width + margin.right + margin.left)
    .attr('height', height + margin.top + margin.bottom)
    .append('g')
    .attr('transform', `translate(${margin.left}, ${margin.top})`);

  // header
  const header = svg
    .append('g')
    .attr('class', 'bar-header')
    .attr('transform', `translate(0,${-margin.top * 0.6})`)
    .append('text');

  const headline = header.append('tspan');

  // header text  
  header
    .append('tspan')
    .attr('x', 0)
    .attr('dy', '1.5em')
    .style('font-size', '0.8em')
    .style('fill', '#555')
    .text('Select criteria and hover over bars for info');

  // draw bars
  const bars = svg.append('g').attr('class', 'bars');

  // draw xaxis
  const xAxis = d3
    .axisTop(xScale)
    .ticks(5)
    .tickFormat(formatTicks)
    .tickSizeInner(-height)
    .tickSizeOuter(0);

  const xAxisDraw = svg.append('g').attr('class', 'x axis');

  // draw yaxis
  const yAxis = d3
  .axisLeft(yScale)
  .tickSize(0);

  const yAxisDraw = svg.append('g').attr('class', 'y axis');

  // initial bar render
  const energyData = songsClean
    .sort((a, b) => b.energy - a.energy);

  update(energyData);

  // listen to click events
  d3.selectAll('button').on('click', click);
}

// ------------------------------------------------------------------------------
// load and pass data
d3.json('songs.json', type).then(res => {
  ready(res);
});

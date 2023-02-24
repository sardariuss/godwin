import { ActorContext } from "../../ActorContext"
import Color from 'colorjs.io';

import ReactApexChart from 'react-apexcharts';

import { ScatterChart } from "../ScatterChart";

import { Chart, registerables } from 'chart.js';

import React, { useContext, useState, useEffect } from "react";

Chart.register(...registerables);

type Props = {
  question_id: bigint;
};

// @todo: change the state of the buttons based on the opinion for the logged user for this question
const VoteOpinion = ({question_id}: Props) => {

	const {actor, isAuthenticated} = useContext(ActorContext);
  const [opinion, setOpinion] = useState<number>(0.0);
  const [leftColor, setLeftColor] = useState<string>("#DB4437");
  const [rightColor, setRightColor] = useState<string>("#0F9D58");
  const sliderWidth = 200;
  const thumbSize = 50;
  const marginWidth = thumbSize / 2;
  const marginRatio = marginWidth / sliderWidth;

  const white = new Color("white");
  const yellow = new Color("#F4B400");
  //const greenwhite = white.range("#0F9D58", { space: "lch", outputSpace: "lch" });
  const yellowwhite = white.range("#F4B400", { space: "lch", outputSpace: "lch"});
  const greenyellow = yellow.range("#0F9D58", { space: "lch", outputSpace: "lch" });
  const redyellow = yellow.range("#DB4437", { space: "lch", outputSpace: "lch"});

  const fromRange = (range: any, value: number) => {
    return new Color(range(value).toString()).to("srgb").toString({format: "hex"});
  };

  useEffect(() => {

//    if (opinion > 0) {
//      setRightColor(new Color(yellowwhite(1 - opinion).toString()).to("srgb").toString({format: "hex"}));
//      setLeftColor(new Color(greenyellow(opinion).toString()).to("srgb").toString({format: "hex"}));
//    } else {
//      setLeftColor(new Color(yellowwhite(1 + opinion).toString()).to("srgb").toString({format: "hex"}));
//      setRightColor(new Color(redyellow(-opinion).toString()).to("srgb").toString({format: "hex"}));
//    }

    const greenwhite = white.range("#0F9D58", { space: "lch", outputSpace: "lch"});
    setLeftColor(new Color(greenwhite(opinion > 0 ? opinion : 0).toString()).to("srgb").toString({format: "hex"}));
    const redwhite = white.range("#DB4437", { space: "lch", outputSpace: "lch"});
    setRightColor(new Color(redwhite(opinion < 0 ? -opinion : 0).toString()).to("srgb").toString({format: "hex"}));
  }, [opinion]);

  const updateOpinion = async () => {
    await actor.putOpinionBallot(question_id, opinion);
	};

  /*
  type Data = { x: number; y: number;}[];
  let data : Data = [];
  data.push({x: -1.0, y: 0.5});
  data.push({x: -0.5, y: 1.5});
  data.push({x: 0, y: 2.0});
  data.push({x: 0.5, y: 2.5});
  data.push({x: 1.0, y: 3.5});

  const getColor = (num: number) => {
    const white = new Color("white");
    if (num >= 0) {
      const greenwhite = white.range("#0F9D58", { space: "lch", outputSpace: "lch" });
      return new Color(greenwhite(num).toString()).to("srgb").toString({format: "rgba"});
    } else {
      const redwhite = white.range("#DB4437", { space: "lch", outputSpace: "lch"});
      return new Color(redwhite(-num).toString()).to("srgb").toString({format: "rgba"});
    }
  }

  let colors = data.map((point) => getColor(point.x));
      
  const chartData = {
    datasets: [
      {
        data: data,
        showLine: false,
        fill: false,
        backgroundColor: colors,
        options: {
          animation: false
        }
      }
    ]
  };

  let series = [
    {
      name: 'Metric1',
      data: [[6.4, 1], [8.49, 2]]
    },
    {
      name: 'Whatever',
      data: [[11.7, 4], [14.55, 13.05]]
    },
    {
      name: 'Whatever',
      data: [[15.4, 3], [14.38, 19.54]]
    },
    {
      name: 'Whatever',
      data: [[9, 2], [4.21, 7.58]]
    },
    {
      name: 'Whatever',
      data: [[10.9, 11], [3.21, 18.70]]
    }
  ];


  let options = {
    chart: {
      height: 200,
      type: "heatmap",
      sparkline: {
        enabled: true
      },
      toolbar: {
        show: false
      }
    },
    grid: {
      show: false,
      padding: {
          top: 0,
          right: 0,
          bottom: 0,
          left: 0    
      }
    },
    dataLabels: {
      enabled: false
    },
    legend: {
      show: false
    },
    colors: [fromRange(redyellow, 1.0), fromRange(redyellow, 0.5), fromRange(redyellow, 0.0), fromRange(greenyellow, 0.5), fromRange(greenyellow, 1.0)],
    title: {
      text: 'HeatMap Chart (Single color)',
      show: false
    },
    plotOptions: {
      heatmap: {
        radius: 0,
      }
    },
    yaxis: {
        show: false,        
    }, 
    xaxis: {
      show: false,
      labels: {
          show: false,
      },   
      axisBorder: {
        show: false,        
      },   
      tooltip: {
        enabled: false,
      }
    },
  };*/

  let stacked_bar_series = [
    {
      name: '👍',
      data: [43]
    },
    {
      name: '🤷',
      data: [23]
    },
    {
      name: '👎',
      data: [10]
    }
  ];

  let stacked_bar_options = {
    chart: {
      stacked: true,
      stackType: '100%',
      type: "bar",
      toolbar: {
        show: false
      },
      sparkline: {
        enabled: true
      }
    },
    grid: {
      show: false,
      padding: {
          top: 0,
          right: 0,
          bottom: 0,
          left: 0    
      }
    },
    dataLabels: {
      enabled: true
    },
    legend: {
      show: false
    },
    colors: ["#0F9D58", "white", "#DB4437"],
    plotOptions: {
      bar: {
        horizontal: true,
      },
    },
    yaxis: {
      show: false,    
    }, 
    xaxis: {
      show: false,
      labels: {
        show: false,
      },   
      axisBorder: {
        show: false,        
      },
    },
    tooltip: {
      enabled: true,
      theme: false, // for transparent background
      style: {
        fontSize: '12px',
        fontFamily: undefined
      },
      intersect: true,
      inverseOrder: true,
      onDatasetHover: {
        highlightDataSeries: true,
      },
      x: {
        show: false,
        format: '%',
        formatter: undefined,
      },
      y: {
        formatter: (y) => y.toString() + '%',
        title: {
          formatter: (seriesName) => seriesName,
        },
      },
      marker: {
        show: false,
      },
      fixed: {
        enabled: false,
        position: 'topLeft',
        offsetX: -20,
        offsetY: 0,
      },
        offsetX: 32,
        offsetY: 21,
      /*
      enabledOnSeries: undefined,
      shared: false,
      followCursor: false,
      intersect: false,
      inverseOrder: false,
      custom: undefined,
      fillSeriesColor: false,
      theme: false,
      style: {
        fontSize: '12px',
        fontFamily: undefined
      },
      onDatasetHover: {
        highlightDataSeries: true,
      },
      x: {
          show: true,
          format: 'dd MMM',
          formatter: undefined,
      },
      y: {
          formatter: undefined,
          title: {
              formatter: (seriesName) => seriesName,
          },
      },
      z: {
          formatter: undefined,
          title: 'Size: '
      },
      marker: {
          show: true,
      },
      fixed: {
          enabled: false,
          position: 'topRight',
          offsetX: 0,
          offsetY: 0,
      },
      */
    }
  };

	return (
    <div className="flex flex-col items-center space-x-1 space-y-2">
      <div className="text-xs font-extralight">
        { opinion }
      </div>
      <input id={"opinion_input_" + question_id.toString()} min="-1" max="1" step="0.02" disabled={!isAuthenticated} type="range" onChange={(e) => setOpinion(Number(e.target.value))} onMouseUp={(e) => updateOpinion()} className={"input appearance-none " + (opinion > 0.33 ? "up" : opinion < -0.33 ? "down" : "shrug") } 
      style={{
        "--progress-percent": `${ ((marginRatio + ((opinion + 1) * 0.5) * (1 - 2 * marginRatio)) * 100).toString() + "%"}`,
        "--left-color": `${leftColor}`,
        "--right-color": `${rightColor}`,
        "--margin-left": `${(marginRatio * 100).toString() + "%"}`,
        "--margin-right": `${((1 - marginRatio) * 100).toString() + "%"}`,
        "--slider-width": `${sliderWidth + "px"}`,
        "--thumb-size": `${thumbSize + "px"}`} as React.CSSProperties
      }/>
      { /*}
      <div className="w-[100px] h-[50px] bg-gray-400">
        <ScatterChart chartData={chartData}/>
      </div>
      <ReactApexChart options={options} series={series} type="heatmap" height={350} />
    */ }
      <ReactApexChart options={stacked_bar_options} series={stacked_bar_series} type="bar" height={50} />
    </div>
	);
};

export default VoteOpinion;
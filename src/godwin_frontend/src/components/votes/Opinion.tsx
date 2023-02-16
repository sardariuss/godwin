import { ActorContext } from "../../ActorContext"
import ApexChart from 'react-apexcharts';

import React, { useContext, useState, useEffect } from "react";

type Props = {
  question_id: bigint;
};

// @todo: change the state of the buttons based on the opinion for the logged user for this question
const VoteOpinion = ({question_id}: Props) => {

	const {actor, isAuthenticated} = useContext(ActorContext);
  const [opinion, setOpinion] = useState<number>(0.0);

  useEffect(() => {
    let test = (1 - opinion) * 0.5 * 100;
    //console.log("getSeries: ", test);
    ApexCharts.exec('myChart' + question_id, 'updateSeries', [test], false);
    if (test > 50) {
      console.log("DISAGREE");
      ApexCharts.exec('myChart' + question_id, 'updateOptions', {
        plotOptions: {
          radialBar: {
            dataLabels: {
              value: {
                color: "#DB4437",
                formatter: function (val) {
                  return "DISAGREE " + Math.abs(Number((2 * val - 100) / 100)).toLocaleString(undefined,{style: 'percent', minimumFractionDigits:0});
                }
              }
            }
          }
        }
      }, false);
    } else {
      console.log("AGREE");
      ApexCharts.exec('myChart' + question_id, 'updateOptions', {
        plotOptions: {
          radialBar: {
            dataLabels: {
              value: {
                color: "#0F9D58",
                formatter: function (val) {
                  return "AGREE " + Math.abs(Number((2 * val - 100) / 100)).toLocaleString(undefined,{style: 'percent', minimumFractionDigits:0});
                }
              }
            }
          }
        }
      }, false);
    }
  }, [opinion]);

  const options : ApexCharts.ApexOptions = {
    states: {
      hover: {
          filter: {
              type: 'none',
          }
      },
    },
    chart: {
      id: 'myChart' + question_id,
      type: 'radialBar',
      offsetY: -10
    },
    plotOptions: {
      radialBar: {
        startAngle: -130,
        endAngle: 130,
        dataLabels: {
          value: {
            offsetY: 20,
            fontSize: '10px',
            color: "#fff",
            formatter: function (val) {
              return Math.abs(Number((2 * val - 100) / 100)).toLocaleString(undefined,{style: 'percent', minimumFractionDigits:0});
            }
          }
        },
        hollow: {
          margin: 0,
          size: "50%",
          background: "#1F2937",
        },
        track: {
          background: '#0F9D58',
          strokeWidth: '100%',
          margin: 0, // margin is in pixels
        },
      },
    },
    fill: {
      colors: ['#DB4437'],
      type: 'solid',
    },
    labels: [''],
  };

  const updateOpinion = async () => {
    //🙆‍♂️  🤷‍♂️  🙅‍♂  👍
		console.log("updateOpinion");
    let opinionResult = await actor.putOpinionBallot(question_id, opinion);
		console.log(opinionResult);
	};

  const getTransform = () => {
    let rotation = (opinion - 1) * 90;
    return [{rotate: rotation.toString() + 'deg'}];
  };

	return (
    <div className="flex flex-col items-center space-x-1">
      {/*
      <Text style={{transform: getTransform(), fontSize: '2rem'}}>👍</Text>
      <div className="pie-wrapper min-w-10 min-h-10 progress-45 style-2">
        <span className="label">45<span className="smaller">%</span></span>
        <div className="pie">
          <div className="left-side half-circle"></div>
          <div className="right-side half-circle"></div>
        </div>
        <div className="shadow"></div>
      </div>
      */}
    <ApexChart options={options} series={[50]} type="radialBar" height={150} />
      <input id="small-range" min="-1" max="1" step="0.02" disabled={!isAuthenticated} type="range" onChange={(e) => setOpinion(Number(e.target.value))} onMouseUp={(e) => updateOpinion()} className="w-24 h-1 mb-6 bg-gray-200 rounded-lg appearance-none cursor-pointer range-sm dark:bg-gray-700"></input>
    </div>
	);
};

export default VoteOpinion;

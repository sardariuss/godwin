import { CategorySide, Polarization, Ballot } from "./../../../declarations/godwin_backend/godwin_backend.did";
import { ScatterChart } from "../ScatterChart";

import { ChartTypeEnum, PolarizationInfo, cursorToColor, getNormalizedPolarization } from "../../utils";

import { Bar }          from 'react-chartjs-2'

import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend,
} from 'chart.js';

ChartJS.register(
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend
);

const options = {
  indexAxis: 'y' as const,
  responsive: true,
  plugins: {
    tooltip: {
      enabled: true,
      callbacks: {
        label: function(ctx) {
          return ctx.dataset.labels[ctx.dataIndex] + (ctx.parsed.x * 100).toFixed(2) + " %";
        },
        title: function(ctx) {
          return "";
        }
      }
    },
    legend: {
      display: false
    }
  },
  animation:{
    duration: 0
  },
  maintainAspectRatio: false,
  scales: {
    x: {
      stacked: true,
      display: false,
    },
    y: {
      stacked: true,
      display: false,
    }
  },
};

const getDataSets = (input_ballots: [string, Ballot, number][], polarizationInfo: PolarizationInfo) => {
  let labels : string[] = [];
  let points : { x : number, y: number }[]= [];
  let colors : string[] = [];
  for (let i = 0; i < input_ballots.length; i++){
    let coef = input_ballots[i][2];
    let cursor = input_ballots[i][1].answer * coef;
    let date = input_ballots[i][1].date;
    points.push({ x: cursor, y: Number(date) });
    colors.push(cursorToColor(cursor, polarizationInfo, Math.abs(coef)));
    labels.push("Vote Id: " + input_ballots[i][0] + "\nCursor: " + input_ballots[i][1].answer.toPrecision(2) + "\nCoef:" + input_ballots[i][2].toPrecision(2) );
  }
  return {
    datasets: [{
      labels,
      data: points,
      backgroundColor: colors,
      pointRadius: 4,
      pointHoverRadius: 3,
    }]
  }
}

type Props = {
  name: string;
  showName: boolean;
  polarizationInfo: {
    left: CategorySide;
    center: CategorySide;
    right: CategorySide;
  };
  polarizationValue: Polarization;
  ballots: [string, Ballot, number][];
  chartType: ChartTypeEnum;
};

const PolarizationBar = ({name, showName, polarizationInfo, polarizationValue, ballots, chartType}: Props) => {

  const labels = [name];
  const normedPolarization = getNormalizedPolarization(polarizationValue);

  const getBorderColor = () : string => {
    if (document.documentElement.classList.contains('dark')){
      return '#333333';
    } else {
      return '#bbbbbb';
    }
  };

  //document.documentElement.classList.contains('dark')

  const data = {
    labels,
    datasets: [
      {
        borderColor: getBorderColor(),
        borderWidth: 1.2,
        borderSkipped: false,
        labels: [polarizationInfo.left.symbol],
        data: labels.map(() => normedPolarization.left),
        backgroundColor: polarizationInfo.left.color,
      },
      {
        borderColor: getBorderColor(),
        borderWidth: 1.2,
        borderSkipped: false,
        labels: [polarizationInfo.center.symbol],
        data: labels.map(() => normedPolarization.center),
        backgroundColor: polarizationInfo.center.color,
      },
      {
        borderColor: getBorderColor(),
        borderWidth: 1.2,
        borderSkipped: false,
        labels: [polarizationInfo.right.symbol],
        data: labels.map(() => normedPolarization.right),
        backgroundColor: polarizationInfo.right.color,
      },
    ],
  };
   
	return (
      <div className="grid grid-cols-5 w-full">
        <div className="flex flex-col items-center z-10 grow place-self-center">
          <div className="text-3xl">{ polarizationInfo.left.symbol }</div>
          <div className="text-xs font-extralight">{ polarizationInfo.left.name }</div>
        </div>
        <div className="col-span-3 z-0 grow">
          <div className={"max-h-16 w-full"}>
          {
            chartType === ChartTypeEnum.Scatter ? 
              <div className="max-h-16">
                <ScatterChart chartData={getDataSets(ballots, polarizationInfo)}></ScatterChart>
              </div> :
            chartType === ChartTypeEnum.Bar ?
              <Bar data={data} options={options}/> :
              <></>
          }
          </div>
        </div>
        <div className="flex flex-col items-center z-10 grow place-self-center">
          <div className="text-3xl">{ polarizationInfo.right.symbol }</div>
          <div className="text-xs font-extralight">{ polarizationInfo.right.name }</div>
        </div>
        {
          showName ? 
          <div className="col-start-1 col-end-6 text-center text-xs align-top font-light">
              {name /*+ ": " + polarizationValue.left.toPrecision(2) + " / " + polarizationValue.center.toPrecision(2) + " / " + polarizationValue.right.toPrecision(2)*/}
          </div> :
          <> </>
        }
    </div>
	);
};

export default PolarizationBar;

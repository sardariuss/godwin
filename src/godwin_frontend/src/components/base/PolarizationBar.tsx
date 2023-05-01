import { CategorySide, Polarization, Ballot } from "./../../../declarations/godwin_backend/godwin_backend.did";
import { ScatterChart } from "../ScatterChart";

import { PolarizationInfo, cursorToColor, getNormalizedPolarization } from "../../utils";

import { Bar }          from 'react-chartjs-2'

import { ChartTypeEnum } from "../../utils";


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
    labels.push("Vote Id: " + input_ballots[i][0] + "\nCursor: " + input_ballots[i][1].answer.toPrecision(2) + "\nCoef:" + input_ballots[i][2].toPrecision(2));
    let coef = input_ballots[i][2];
    let cursor = input_ballots[i][1].answer * coef;
    let date = input_ballots[i][1].date;
    points.push({ x: cursor, y: Number(date) });
    var alpha = Math.trunc(Math.abs(coef) * 255).toString(16);
    alpha = alpha.length == 1 ? "0" + alpha : alpha;
    colors.push(cursorToColor(cursor, polarizationInfo) + Math.trunc(Math.abs(coef) * 255).toString(16));
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

  const data = {
    labels,
    datasets: [
      {
        borderColor: '#000000',
        borderWidth: 0.8,
        borderSkipped: false,
        labels: [polarizationInfo.left.symbol],
        data: labels.map(() => normedPolarization.left),
        backgroundColor: polarizationInfo.left.color,
      },
      {
        borderColor: '#000000',
        borderWidth: 0.8,
        borderSkipped: false,
        labels: [polarizationInfo.center.symbol],
        data: labels.map(() => normedPolarization.center),
        backgroundColor: polarizationInfo.center.color,
      },
      {
        borderColor: '#000000',
        borderWidth: 0.8,
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
        </div>
        <div className="col-span-3 z-0 grow">
          <div className={"max-h-16 w-full"}>
          {
            chartType === ChartTypeEnum.Scatter ? 
              <ScatterChart chartData={getDataSets(ballots, polarizationInfo)}></ScatterChart> :
            chartType === ChartTypeEnum.Bar ?
              <Bar data={data} options={options}/> :
              <></>
          }
          </div>
        </div>
        <div className="flex flex-col items-center z-10 grow place-self-center">
          <div className="text-3xl">{ polarizationInfo.right.symbol }</div>
        </div>
        {
          showName ? 
          <div className="col-start-1 col-end-6 text-center text-xs align-top font-light">
              {name}
          </div> :
          <> </>
        }
    </div>
	);
};

export default PolarizationBar;

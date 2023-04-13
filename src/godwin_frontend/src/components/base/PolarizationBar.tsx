import { Principal } from "@dfinity/principal";
import { CategorySide, Polarization, Ballot } from "./../../../declarations/godwin_backend/godwin_backend.did";
import { ScatterChart } from "../ScatterChart";

import { PolarizationInfo, cursorToColor } from "../../utils";

import { Bar }            from 'react-chartjs-2'

const options = {
  indexAxis: 'y' as const,
  responsive: true,
  plugins: {
    tooltip: {
      enabled: false
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

type Props = {
  name: string;
  showName: boolean;
  polarizationInfo: {
    left: CategorySide;
    center: CategorySide;
    right: CategorySide;
  };
  polarizationValue: Polarization;
  ballots: [Principal, Ballot][];
};

const getDataSets = (input_ballots: [Principal, Ballot][], polarizationInfo: PolarizationInfo) => {
  let points : { x : number, y: number }[]= [];
  let colors : string[] = [];
  for (let i = 0; i < input_ballots.length; i++){
    
    let cursor = input_ballots[i][1].answer;
    let date = input_ballots[i][1].date;
    points.push({ x: cursor, y: Number(date) });
    colors.push(cursorToColor(cursor, polarizationInfo));
  }
  return {
    datasets: [{
      label: 'Scatter Dataset',
      data: points,
      backgroundColor: colors,
      pointRadius: 4,
      pointHoverRadius: 3,
    }]
  }
}

const PolarizationBar = ({name, showName, polarizationInfo, polarizationValue, ballots}: Props) => {

  const labels = [name];

  const data = {
    labels,
    datasets: [
      {
        label: polarizationInfo.left.symbol,
        data: labels.map(() => polarizationValue.left),
        backgroundColor: polarizationInfo.left.color,
      },
      {
        label: polarizationInfo.center.symbol,
        data: labels.map(() => polarizationValue.center),
        backgroundColor: polarizationInfo.center.color,
      },
      {
        label: polarizationInfo.right.symbol,
        data: labels.map(() => polarizationValue.right),
        backgroundColor: polarizationInfo.right.color,
      },
    ],
  };
   
	return (
      <div className="grid grid-cols-5">
        <div className="flex flex-col items-center z-10 grow">
          <div className="text-3xl">{ polarizationInfo.left.symbol }</div>
          <div className="text-xs">{ polarizationInfo.left.name }</div>
        </div>
        <div className="col-span-3 z-0 grow">
          { 
          /* 
            @todo: Somehow the scatter chart is not aligned with the bar chart.
            Here fix is to put the height of bar at 50px, but the height of scatter at 38px and a margin of 1.5 (=6px).
          */
          }
          <div className="absolute mt-1.5">
            <ScatterChart chartData={getDataSets(ballots, polarizationInfo)}></ScatterChart>
          </div>
          <div className="absolute transition ease-out hover:opacity-10">
            <Bar data={data} options={options} height="50px"/>
          </div>
        </div>
        <div className="flex flex-col items-center z-10 grow">
          <div className="text-3xl">{ polarizationInfo.right.symbol }</div>
          <div className="text-xs">{ polarizationInfo.right.name }</div>
        </div>
        {
          showName ? 
          <div className="col-start-1 col-end-6 text-center">
            <div>
              {name}
            </div>
          </div> :
          <> </>
        }
    </div>
	);
};

export default PolarizationBar;

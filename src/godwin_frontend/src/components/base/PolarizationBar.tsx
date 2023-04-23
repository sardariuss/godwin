import { Principal } from "@dfinity/principal";
import { CategorySide, Polarization, Ballot } from "./../../../declarations/godwin_backend/godwin_backend.did";
import { ScatterChart } from "../ScatterChart";

import { PolarizationInfo, cursorToColor } from "../../utils";

import { Bar }            from 'react-chartjs-2'

import { useEffect, useState } from "react";

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
  polarizationWeight: number;
  ballots: [string, Ballot, number][];
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

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

const PolarizationBar = ({name, showName, polarizationInfo, polarizationValue, polarizationWeight, ballots}: Props) => {

  const labels = [name];

  // Required to avoid the flickering effect that happen if the tailwind hover: attribute is used directly
  const [hoverScatter, setHoverScatter] = useState<boolean>(false);
  const [hoverBar, setHoverBar] = useState<boolean>(false);

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

  const refreshHoverScatter = (hovered: boolean) => {
    if (hovered == hoverScatter) return;
    if (hovered) {
      setHoverScatter(true);
    } else {
      sleep(1).then(() => { setHoverScatter(false); });
    }
  };

  const refreshHoverBar = (hovered: boolean) => {
    if (hovered == hoverBar) return;
    if (hovered) {
      setHoverBar(true);
    } else {
      sleep(1).then(() => { setHoverBar(false); });
    }
  };

  const getBarOpacity = () => {
    if (hoverScatter || hoverBar) {  
      return 0;
    } else {
      return Math.trunc(polarizationWeight * 10) * 10;
    }
  }

  const getScatterOpacity = () => {
    if (hoverScatter || hoverBar) {  
      return 100;
    } else {
      return 0;
    }
  }

  const getBarZIndex = () => {
    if (hoverScatter || hoverBar) {
      return 0;
    } else {
      return 20;
    }
  }
   
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
            w-full does not work because of the absolute positioning of the scatter chart.
            Update: I gave up on trying to fix the layout for now...
          */
          }
          <div className={"absolute mt-3 max-h-12 w-3/12 z-10 opacity-" + getScatterOpacity()} onMouseEnter={(e) => refreshHoverScatter(true) } onMouseLeave={(e) => { refreshHoverScatter(false) }}>
            <ScatterChart chartData={getDataSets(ballots, polarizationInfo)}></ScatterChart>
          </div>
          <div className={"relative transition ease-out transition ease-out max-h-16 opacity-" + getBarOpacity() + " z-" + getBarZIndex()}  onMouseEnter={(e) => refreshHoverBar(true)} onMouseLeave={(e) => refreshHoverBar(false)}>
            <Bar data={data} options={options}/>
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

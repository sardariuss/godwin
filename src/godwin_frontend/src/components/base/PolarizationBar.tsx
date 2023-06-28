import { ScatterChart }                                                              from "../charts/ScatterChart";
import { BarChart }                                                                  from "../charts/BarChart";
import CONSTANTS                                                                     from "../../Constants";
import { ChartTypeEnum, PolarizationInfo, cursorToColor, getNormalizedPolarization } from "../../utils";
import { toPercentage }                                                              from "../charts/ChartUtils";

import { Polarization }                                                              from "./../../../declarations/godwin_sub/godwin_sub.did";

import { useState, useEffect }                                                       from "react";

export type BallotPoint = {
  label: string;
  cursor: number;
  coef: number;
  date: bigint;
};

const getBorderColor = () : string => {
  return document.documentElement.classList.contains('dark') ? CONSTANTS.CHART.BORDER_COLOR_DARK : CONSTANTS.CHART.BORDER_COLOR_LIGHT;
}

const getScatterChartData = (input_ballots: BallotPoint[], polarizationInfo: PolarizationInfo) => {
  let labels : string[] = [];
  let points : { x : number, y: number }[]= [];
  let colors : string[] = [];

  for (let i = 0; i < input_ballots.length; i++){
    let final_cursor = input_ballots[i].cursor * input_ballots[i].coef;
    points.push({ x: final_cursor, y: Number(input_ballots[i].date) });
    colors.push(cursorToColor(final_cursor, polarizationInfo, Math.abs(input_ballots[i].coef)));
    labels.push(input_ballots[i].label);
  }
  return {
    datasets: [{
      borderColor: getBorderColor(),
      labels,
      data: points,
      backgroundColor: colors,
      pointRadius: 4,
      pointHoverRadius: 3,
    }]
  }
}

const getBarChartData = (name: string, polarizationValue: Polarization, polarizationInfo: PolarizationInfo) => {
  const labels = [name];
  const borderColor = getBorderColor();
  const normedPolarization = getNormalizedPolarization(polarizationValue);

  return {
    labels,
    datasets: [
      {
        borderColor,
        borderWidth: 1.2,
        borderSkipped: false,
        labels: [polarizationInfo.left.symbol],
        data: labels.map(() => normedPolarization.left),
        backgroundColor: polarizationInfo.left.color,
      },
      {
        borderColor,
        borderWidth: 1.2,
        borderSkipped: false,
        labels: [polarizationInfo.center.symbol],
        data: labels.map(() => normedPolarization.center),
        backgroundColor: polarizationInfo.center.color,
      },
      {
        borderColor,
        borderWidth: 1.2,
        borderSkipped: false,
        labels: [polarizationInfo.right.symbol],
        data: labels.map(() => normedPolarization.right),
        backgroundColor: polarizationInfo.right.color,
      },
    ],
  };
}

type Props = {
  name: string;
  showName: boolean;
  polarizationInfo: PolarizationInfo;
  polarizationValue: Polarization;
  ballots: BallotPoint[];
  chartType: ChartTypeEnum;
};

// @todo: bug: when switching principal, the charts are not updated
const PolarizationBar = ({name, showName, polarizationInfo, polarizationValue, ballots, chartType}: Props) => {

  const [scatterData, setScatterData] = useState<any>(getScatterChartData(ballots, polarizationInfo));
  const [barData    , setBarData    ] = useState<any>(getBarChartData(name, polarizationValue, polarizationInfo));

  const refreshData = () => {
    setScatterData(getScatterChartData(ballots, polarizationInfo));
    setBarData(getBarChartData(name, polarizationValue, polarizationInfo));
  }

  useEffect(() => {
    refreshData();
  }, [ballots, polarizationInfo, polarizationValue]);

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
              <ScatterChart chart_data={scatterData}/>
            </div> :
          chartType === ChartTypeEnum.Bar ?
            <BarChart chart_data={barData} generate_label={toPercentage} bar_size={1}/> :
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

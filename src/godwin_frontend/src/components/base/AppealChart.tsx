import { Appeal } from "./../../../declarations/godwin_backend/godwin_backend.did";
import CONSTANTS from "../../Constants";

import React from 'react';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend,
} from 'chart.js';
import { Bar } from 'react-chartjs-2';

import ChartDataLabels from "chartjs-plugin-datalabels";

ChartJS.register(
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend
);

const options = {
  responsive: true,
  barPercentage: 0.7,
  layout: {
    padding: {
      top: 50, // Otherwise the top label is not visible
      bottom: 10,
      left: 100,
      right: 100
    }
  },
  animation:{
    duration: 0
  },
  plugins: {
    legend: {
      display: false
    },
    datalabels: {
      anchor: 'end',
      align: 'end',
      formatter: (value: number, context) => {
        const prefix = context.datasetIndex === 0 ? 
          (CONSTANTS.INTEREST_INFO.up.symbol + "\n" + CONSTANTS.INTEREST_INFO.up.name) : context.datasetIndex === 1 ? 
          (CONSTANTS.INTEREST_INFO.down.symbol + "\n" + CONSTANTS.INTEREST_INFO.down.name) : 
          (CONSTANTS.INTEREST_INFO.duplicate.symbol + "\n" + CONSTANTS.INTEREST_INFO.duplicate.name);
        return `${prefix}`;
      },
      font:{
        size: 16,
        
      },
      color: ['#ffffff'],
      textAlign: 'center'
    }
  },
  maintainAspectRatio: false,
  scales: {
    x: {
      display: false,
    },
    y: {
      display: false,
    }
  },
};

type Props = {
  appeal: Appeal;
};

const AppealChart = ({appeal}: Props) => {

  const labels = ['APPEAL'];

  const data = {
    labels,
    datasets: [
      {
        label: CONSTANTS.INTEREST_INFO.up.symbol,
        data: labels.map(() => Number(appeal.ups)),
        backgroundColor: CONSTANTS.INTEREST_INFO.up.color,
      },
      {
        label: CONSTANTS.INTEREST_INFO.down.symbol,
        data: labels.map(() => Number(appeal.downs)),
        backgroundColor: CONSTANTS.INTEREST_INFO.down.color,
      },
      {
        label: CONSTANTS.INTEREST_INFO.duplicate.symbol,
        data: labels.map(() => 0),
        backgroundColor: CONSTANTS.INTEREST_INFO.duplicate.color,
      },
    ],
  };

  return (
    <Bar options={options} data={data} plugins={[ChartDataLabels]} height="200px"/>
  );
}

export default AppealChart;

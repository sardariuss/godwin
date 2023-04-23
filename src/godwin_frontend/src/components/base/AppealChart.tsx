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
          (CONSTANTS.INTEREST_INFO.right.symbol + "\n" + CONSTANTS.INTEREST_INFO.right.name) : context.datasetIndex === 1 ? 
          (CONSTANTS.INTEREST_INFO.left.symbol + "\n" + CONSTANTS.INTEREST_INFO.left.name) : 
          (CONSTANTS.DUPLICATE.symbol + "\n" + CONSTANTS.DUPLICATE.name);
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
        label: CONSTANTS.INTEREST_INFO.right.symbol,
        data: labels.map(() => Number(appeal.ups)),
        backgroundColor: CONSTANTS.INTEREST_INFO.right.color,
      },
      {
        label: CONSTANTS.INTEREST_INFO.left.symbol,
        data: labels.map(() => Number(appeal.downs)),
        backgroundColor: CONSTANTS.INTEREST_INFO.left.color,
      },
      {
        label: CONSTANTS.DUPLICATE.symbol,
        data: labels.map(() => 0),
        backgroundColor: CONSTANTS.DUPLICATE.color,
      },
    ],
  };

  return (
    <Bar options={options} data={data} plugins={[ChartDataLabels]} height="200px"/>
  );
}

export default AppealChart;

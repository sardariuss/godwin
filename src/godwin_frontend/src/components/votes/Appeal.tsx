import { Appeal } from "./../../../declarations/godwin_backend/godwin_backend.did";

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
        const prefix = context.datasetIndex === 0 ? "🤓\nUP" : context.datasetIndex === 1 ? "🤡\nDOWN" : "👀\nDUPLICATE";
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

const AppealComponent = ({appeal}: Props) => {

  const labels = ['APPEAL'];

  const data = {
    labels,
    datasets: [
      {
        label: '🤓',
        data: labels.map(() => Number(appeal.ups)),
        backgroundColor: "#0F9D58",
      },
      {
        label: '🤡',
        data: labels.map(() => Number(appeal.downs)),
        backgroundColor: "#DB4437",
      },
      {
        label: '👀',
        data: labels.map(() => 0),
        backgroundColor: "#4285F4",
      },
    ],
  };

  return (
    <Bar options={options} data={data} plugins={[ChartDataLabels]} height="200px"/>
  );
}

export default AppealComponent;

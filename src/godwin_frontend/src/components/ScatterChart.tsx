import React from 'react';
import {
  Chart as ChartJS,
  LinearScale,
  PointElement,
  LineElement,
  Tooltip,
  Legend,
} from 'chart.js';
import { Scatter } from 'react-chartjs-2';

ChartJS.register(LinearScale, PointElement, LineElement, Tooltip, Legend);

const options = {
  maintainAspectRatio: false,
  animation: {
    duration: 0,
  },
  scales: {
    x: {
      display: false
    },
    y: {
      display: false
    }
  },
  plugins: {
    legend: {
        display: false
    },
    tooltip:{
      enabled: false
    }
  },
  responsive: true
};

export const ScatterChart = ({ chartData }: any) => {
  return (
      <Scatter
        data={chartData}
        options={options}
      />
  );
};

export type ScatterData = {
  x: number,
  y: number
}
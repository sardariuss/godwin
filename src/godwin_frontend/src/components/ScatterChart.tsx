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
      enabled: true
    }
  },
  responsive: false
};

export const ScatterChart = ({ chartData }: any) => {
  return (
    <div>
      <Scatter
        data={chartData}
        options={options}
        height="38px"
      />
    </div>
  );
};

export type ScatterData = {
  x: number,
  y: number
}
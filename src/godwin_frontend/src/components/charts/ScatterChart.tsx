import {
  Chart as ChartJS,
  LinearScale,
  PointElement,
  LineElement,
  Tooltip,
  Legend,
}                  from 'chart.js';
import { Scatter } from 'react-chartjs-2';
import React       from 'react';

ChartJS.register(LinearScale, PointElement, LineElement, Tooltip, Legend);

const options = {
  maintainAspectRatio: false,
  animation: {
    duration: 0,
  },
  scales: {
    x: {
      display: false,
      suggestedMin: -1,
      suggestedMax: 1,
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
      enabled: true,
      callbacks: {
        label: function(ctx) { return ctx.dataset.labels[ctx.dataIndex]; }
      }
    }
  },
  responsive: true
};

export const ScatterChart = ({ chart_data }: any) => {
  return ( <Scatter data={chart_data} options={options} /> );
};
